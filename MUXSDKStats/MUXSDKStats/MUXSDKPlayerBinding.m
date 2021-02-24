#import "MUXSDKPlayerBinding.h"
#import "MUXSDKConnection.h"
#import "MUXSDKPlayerBindingConstants.h"

#if __has_feature(modules)
@import Foundation;
@import CoreMedia;
#else
#import <Foundation/Foundation.h>
#import <CoreMedia/CoreMedia.h>
#endif

// SDK constants.
NSString *const MUXSDKPluginName = @"apple-mux";
NSString *const MUXSDKPluginVersion = @"2.0.2";

// Min number of seconds between timeupdate events. (100ms)
double MUXSDKMaxSecsBetweenTimeUpdate = 0.1;
// Number of seconds of difference between wall/play time signaling the beginning of a seek. (200ms)
float MUXSDKMaxSecsSeekClockDrift = 0.2f;
// Number of seconds the playhead has to move from the last known playhead position when
// restarting play to consider the transition to play a seek. (500ms)
float MUXSDKMaxSecsSeekPlayheadShift = 0.5f;

// AVPlayer observation contexts.
static void *MUXSDKAVPlayerRateObservationContext = &MUXSDKAVPlayerRateObservationContext;
static void *MUXSDKAVPlayerStatusObservationContext = &MUXSDKAVPlayerStatusObservationContext;
static void *MUXSDKAVPlayerCurrentItemObservationContext = &MUXSDKAVPlayerCurrentItemObservationContext;

// AVPlayerItem observation contexts.
static void *MUXSDKAVPlayerItemStatusObservationContext = &MUXSDKAVPlayerStatusObservationContext;

// This is the name of the exception that gets thrown when we remove an observer that
// is not registered. In theory, this should not really happen, but there is one async condition
// that makes it possible. Specifically when handling the _playerItem observers. The
// _playerItem observer is attached asynchonously, a developer could call destroyPlayer before
// we have attached the _playerItem observer
NSString * RemoveObserverExceptionName = @"NSRangeException";

@implementation MUXSDKPlayerBinding

- (id)initWithName:(NSString *)name andSoftware:(NSString *)software {
    self = [super init];
    if (self) {
        _name = name;
        _software = software;
        _automaticErrorTracking = true;
    }
    return(self);
}

- (BOOL)setAutomaticErrorTracking:(BOOL)automaticErrorTracking {
    _automaticErrorTracking = automaticErrorTracking;
    return _automaticErrorTracking;
}

- (void)attachAVPlayer:(AVPlayer *)player {
    if (_player) {
        [self detachAVPlayer];
    }
    if (!player) {
        NSLog(@"MUXSDK-ERROR - Cannot attach to NULL AVPlayer for player name: %@", _name);
        return;
    }
    _player = player;
    __weak MUXSDKPlayerBinding *weakSelf = self;
    _lastTimeUpdate = CFAbsoluteTimeGetCurrent() - MUXSDKMaxSecsBetweenTimeUpdate;
    _timeObserver = [_player addPeriodicTimeObserverForInterval:[self getTimeObserverInternal]
                                                          queue:NULL
                                                     usingBlock:^(CMTime time) {
                                                         if ([weakSelf isTryingToPlay]) {
                                                             [weakSelf startBuffering];
                                                         } else if ([weakSelf isBuffering]) {
                                                             [weakSelf dispatchPlaying];
                                                         } else {
                                                             [weakSelf dispatchTimeUpdateEvent:time];
                                                         }
                                                         [weakSelf computeDrift];
                                                         [weakSelf updateLastPlayheadTime];
                                                     }];
    _timeUpdateTimer = [NSTimer scheduledTimerWithTimeInterval:0.05
                                                        target:self
                                                      selector:@selector(timeUpdateTimer:)
                                                      userInfo:nil
                                                       repeats:YES];
    [_player addObserver:self
              forKeyPath:@"rate"
                 options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                 context:MUXSDKAVPlayerRateObservationContext];
    [_player addObserver:self
              forKeyPath:@"status"
                 options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                 context:MUXSDKAVPlayerStatusObservationContext];
    [_player addObserver:self
              forKeyPath:@"currentItem"
                 options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                 context:MUXSDKAVPlayerCurrentItemObservationContext];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleAVPlayerAccess:) name:AVPlayerItemNewAccessLogEntryNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleRenditionChange:) name:RenditionChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleAVPlayerError:) name:AVPlayerItemNewErrorLogEntryNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleConnectionTypeDetected:) name:@"com.mux.connection-type-detected" object:nil];
    
    _lastTransferEventCount = 0;
    _lastTransferDuration= 0;
    _lastTransferredBytes = 0;
    _lastAdvertisedBitrate = 0.0;
    _lastDispatchedAdvertisedBitrate = 0.0;
}

-(NSString *)getHostName:(NSString *)urlString {
    NSURL* url = [NSURL URLWithString:urlString];
    NSString *domain = [url host];
    return (domain == nil) ? urlString : domain;
}

//
// Check that the item in the notification matches the item that we are monitoring
// This matters when there are multiple AVPlayer instances running simultaneously
//
- (BOOL) checkIfNotificationIsRelevant:(NSNotification *)notif {
    AVPlayerItem *notificationItem = (AVPlayerItem *)notif.object;
    return notificationItem == _playerItem;
}

- (void)handleConnectionTypeDetected:(NSNotification *)notif {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *type = [notif.userInfo valueForKey:@"type"];
        if (type != nil) {
            MUXSDKDataEvent *dataEvent = [[MUXSDKDataEvent alloc] init];
            MUXSDKViewerData *viewerData = [[MUXSDKViewerData alloc] init];
            [viewerData setViewerConnectionType:type];
            [dataEvent setViewerData:viewerData];
            [MUXSDKCore dispatchGlobalDataEvent:dataEvent];
        }
    });
}

# pragma mark AVPlayerItemAccessLog

- (void)handleAVPlayerAccess:(NSNotification *)notif {
    dispatch_async(dispatch_get_main_queue(), ^{
        BOOL isNotificationRelevant = [self checkIfNotificationIsRelevant:notif];
        if (isNotificationRelevant) {
            AVPlayerItemAccessLog *accessLog = [((AVPlayerItem *)notif.object) accessLog];
            [self handleRenditionChangeInAccessLog:accessLog];
            [self calculateBandwidthMetricFromAccessLog:accessLog];
        }
    });
}

- (void) handleRenditionChange:(NSNotification *) notif {
    NSDictionary *renditionChangeInfo = (NSDictionary *) notif.object;
    NSNumber *advertisedBitrate = renditionChangeInfo[RenditionChangeNotificationInfoAdvertisedBitrate];
    if (advertisedBitrate) {
        _lastAdvertisedBitrate = [advertisedBitrate doubleValue];
        if(![self doubleValueIsEqual:@(_lastDispatchedAdvertisedBitrate)  toOther:@(_lastAdvertisedBitrate)]) {
            [self dispatchRenditionChange];
        }
    }
}

- (void) handleRenditionChangeInAccessLog:(AVPlayerItemAccessLog *) log {
    AVPlayerItemAccessLogEvent *lastEvent = log.events.lastObject;
    float advertisedBitrate = lastEvent.indicatedBitrate;
    BOOL bitrateHasChanged = ![self doubleValueIsEqual:@(_lastAdvertisedBitrate) toOther:@(advertisedBitrate)];
    BOOL isStartingPlayback = [self doubleValueIsEqual:@(_lastAdvertisedBitrate) toOther:@(0)];

    if (bitrateHasChanged) {
        if(isStartingPlayback) {
            // This is not a renditionchange but the player playing the first rendition.
            _lastAdvertisedBitrate = advertisedBitrate;
            return;
        }
        NSLog(@"MUXSDK-INFO - Switch advertised bitrate from: %f to: %f", _lastAdvertisedBitrate, advertisedBitrate);
        [[NSNotificationCenter defaultCenter] postNotificationName:RenditionChangeNotification object: @{
            RenditionChangeNotificationInfoAdvertisedBitrate: @(advertisedBitrate)
        }];
    }
}

- (void) calculateBandwidthMetricFromAccessLog:(AVPlayerItemAccessLog *) log {
    if (log != nil && log.events.count > 0) {
        // https://developer.apple.com/documentation/avfoundation/avplayeritemaccesslogevent?language=objc
        AVPlayerItemAccessLogEvent *event = log.events[log.events.count - 1];
        
       if (_lastTransferEventCount != log.events.count) {
           _lastTransferDuration= 0;
           _lastTransferredBytes = 0;
           _lastTransferEventCount = log.events.count;
       }
       
       double requestCompletedTime = [[NSDate date] timeIntervalSince1970];
       // !!! event.observedMinBitrate, event.observedMaxBitrate, event.observedBitrate don't seem to be accurate
       // we did a charles proxy dump try to calculate the bitrate, and compared with above values. It doesn't match
       // but if use data stored in requestResponseStart/requestResponseEnd/requestBytesLoaded to compute, the value are very close.
       MUXSDKBandwidthMetricData *loadData = [[MUXSDKBandwidthMetricData alloc] init];
       loadData.requestType = @"media";
       double requestStartSecs = requestCompletedTime - (event.transferDuration - _lastTransferDuration);
       loadData.requestStart = [NSNumber numberWithLong: (long)(requestStartSecs * 1000)];
       loadData.requestResponseStart = nil;
       loadData.requestResponseEnd = [NSNumber numberWithLong: (long)(requestCompletedTime * 1000)];
       loadData.requestBytesLoaded = [NSNumber numberWithLong: event.numberOfBytesTransferred - _lastTransferredBytes];
       loadData.requestResponseHeaders = nil;
       loadData.requestHostName = [self getHostName:event.URI];
       loadData.requestCurrentLevel = nil;
       loadData.requestMediaStartTime = nil;
       loadData.requestMediaDuration = nil;
       loadData.requestVideoWidth = nil;
       loadData.requestVideoHeight = nil;
       loadData.requestRenditionLists = nil;
       [self dispatchBandwidthMetric:loadData withType:MUXSDKPlaybackEventRequestBandwidthEventCompleteType];
       _lastTransferredBytes = event.numberOfBytesTransferred;
       _lastTransferDuration = event.transferDuration;
    }
}

# pragma mark AVPlayerItemErrorLog

- (void)handleAVPlayerError:(NSNotification *)notif {
    BOOL isNotificationRelevant = [self checkIfNotificationIsRelevant:notif];
    if (isNotificationRelevant) {
        AVPlayerItemErrorLog *log = [((AVPlayerItem *)notif.object) errorLog];
        if (log != nil && log.events.count > 0) {
            // https://developer.apple.com/documentation/avfoundation/avplayeritemerrorlogevent?language=objc
            AVPlayerItemErrorLogEvent *errorEvent = log.events[log.events.count - 1];
            MUXSDKBandwidthMetricData *loadData = [[MUXSDKBandwidthMetricData alloc] init];
            loadData.requestError = errorEvent.errorDomain;
            loadData.requestType = @"media";
            loadData.requestUrl = errorEvent.URI;
            loadData.requestHostName = [self getHostName:errorEvent.URI];
            loadData.requestErrorCode = [NSNumber numberWithLong: errorEvent.errorStatusCode];
            loadData.requestErrorText = errorEvent.errorComment;
            [self dispatchBandwidthMetric:loadData withType:MUXSDKPlaybackEventRequestBandwidthEventErrorType];
        }
    }
}

- (void)timeUpdateTimer:(NSTimer *)timer {
    if (![self isTryingToPlay] && ![self isBuffering]) {
        [self dispatchTimeUpdateFromTimer];
    }
}

- (void)dealloc {
    [self detachAVPlayer];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemNewAccessLogEntryNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:RenditionChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemNewErrorLogEntryNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"com.mux.connection-type-detected" object:nil];
}

- (void) safelyRemoveTimeObserverForPlayer {
    if (_player) {
        @try {
            [_player removeTimeObserver:_timeObserver];
        } @catch (NSException * e) {
            if ([[e name] isEqualToString:RemoveObserverExceptionName]) {
                NSLog(@"MUXSDK-ERROR removing timeObserver (no observer registered, this can be ignored): %@ %@", e.name, e.reason);
            } else {
                @throw;
            }
        }
        @finally { }
    }
}

- (void) safelyRemovePlayerObserverForKeyPath:(NSString *)keyPath {
    if (_player) {
        @try {
            [_player removeObserver:self forKeyPath:keyPath];
        } @catch (NSException * e) {
            if ([[e name] isEqualToString:RemoveObserverExceptionName]) {
                NSLog(@"MUXSDK-ERROR removing player observer for keyPath (no observer registered, this can be ignored): %@. %@: %@", keyPath, e.name, e.reason);
            } else {
                @throw;
            }
        }
        @finally { }
    }
}

- (void) safelyRemovePlayerItemObserverForKeyPath:(NSString *)keyPath {
    if (_playerItem) {
        @try {
            [_playerItem removeObserver:self forKeyPath:keyPath];
        } @catch (NSException * e) {
            if ([[e name] isEqualToString:RemoveObserverExceptionName]) {
                NSLog(@"MUXSDK-ERROR removing player item observer for keyPath (no observer registered, this can be ignored): %@. %@: %@", keyPath, e.name, e.reason);
            } else {
                @throw;
            }
        }
        @finally { }
    }
}

- (void)detachAVPlayer {
    [self safelyRemoveTimeObserverForPlayer];
    [self safelyRemovePlayerObserverForKeyPath:@"rate"];
    [self safelyRemovePlayerObserverForKeyPath:@"status"];
    [self safelyRemovePlayerObserverForKeyPath:@"currentItem"];
    _player = nil;
    if (_playerItem) {
        [self stopMonitoringAVPlayerItem];
    }
    if (_timeUpdateTimer) {
        [_timeUpdateTimer invalidate];
        _timeUpdateTimer = nil;
    }
}

- (void)monitorAVPlayerItem {
    if (_playerItem) {
        [self stopMonitoringAVPlayerItem];
        [self.playDispatchDelegate videoChangedForPlayer:_name];
        //
        // Special case for AVQueuePlayer
        // In a normal videoChange: world - the KVO for "rate" will fire - and
        // subsequently after that this binding will dispatchPlay. In fact, any time
        // an AVPlayer gets an item loaded into it the KVO for "rate" changes.
        //
        // However, in AVQueuePlayer world - the "rate" doesn't fire when the video is
        // changed. I don't know why, but I guess that is the intended behavior. For that
        // reason, if we're handling a videoChange event and we're dealing with AVQueuePlayer
        // then we have to fire the play event here.
        //
        if (_shouldHandleAVQueuePlayerItem) {
            _shouldHandleAVQueuePlayerItem = false;
            [self dispatchPlay];
        }
    }
    if (_player && _player.currentItem) {
        _playerItem = _player.currentItem;
        [_playerItem addObserver:self
                      forKeyPath:@"status"
                         options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                         context:MUXSDKAVPlayerItemStatusObservationContext];
    }
}

- (void)stopMonitoringAVPlayerItem {
    [MUXSDKCore destroyPlayer: _name];
    [self safelyRemovePlayerItemObserverForKeyPath:@"status"];
    _playerItem = nil;
}

- (void) programChangedForPlayer {
    [self monitorAVPlayerItem];
    [self dispatchPlay];
    [self dispatchPlaying];
}

- (void) prepareForAvQueuePlayerNextItem {
    BOOL isAVQueuePlayer = [_player isKindOfClass:[AVQueuePlayer class]];
    if (isAVQueuePlayer) {
        _shouldHandleAVQueuePlayerItem = true;
    }
}

- (CMTime)getTimeObserverInternal {
    return CMTimeMakeWithSeconds(0.1, NSEC_PER_SEC);
}

- (float)getCurrentPlayheadTimeMs {
    return CMTimeGetSeconds([_player currentTime]) * 1000;
}

- (CGRect)getVideoBounds {
    return CGRectMake(0, 0, 0, 0);
}

- (CGRect)getViewBounds {
    return CGRectMake(0, 0, 0, 0);
}

- (CGSize)getSourceDimensions {
    @try {
        NSArray *formatDescriptions;
        for (int t = 0; t < _player.currentItem.tracks.count; t++) {
            AVPlayerItemTrack *track = [[[_player currentItem] tracks] objectAtIndex:t];
            if (track) {
                formatDescriptions = track.assetTrack.formatDescriptions;
                for (int i = 0; i < formatDescriptions.count; i++) {
                    CMFormatDescriptionRef desc = (__bridge CMFormatDescriptionRef)formatDescriptions[i];
                    if (CMFormatDescriptionGetMediaType(desc) == kCMMediaType_Video) {
                        CMVideoDimensions dimensions = CMVideoFormatDescriptionGetDimensions(desc);
                        return CGSizeMake([[NSNumber numberWithInteger:dimensions.width] floatValue], [[NSNumber numberWithInteger:dimensions.height] floatValue]);
                    }
                }
            }
        }
    } @catch (NSException *exception) {
        NSLog(@"%@", exception.reason);
    }
    return CGSizeMake(0, 0);
}

- (void)resetVideoData {
    _videoSize = CGSizeMake(0, 0);
    _videoDuration = CMTimeMake(0, 0);
    _videoIsLive = NO;
    _videoURL = NULL;
    _seeking = NO;
    _started = NO;
    _lastAdvertisedBitrate = 0.0;
    _lastDispatchedAdvertisedBitrate = 0.0;
    _sourceDimensionsHaveChanged = NO;
    _lastDispatchedVideoSize = CGSizeMake(0, 0);
}

- (void)checkVideoData {
    BOOL videoDataUpdated = NO;
    NSError *error = nil;
    AVKeyValueStatus status = [_player.currentItem.asset statusOfValueForKey:@"duration" error: &error];
    if (status == AVKeyValueStatusLoaded) {
        CMTime duration = [_player.currentItem.asset duration];
        if (CMTimeCompare(_videoDuration, duration) != 0) {
            _videoDuration = duration;
            _videoIsLive = CMTimeCompare(duration, kCMTimeIndefinite) == 0;
            if (_videoIsLive || CMTimeGetSeconds(duration) > 0) {
                videoDataUpdated = YES;
            }
        }
    }
    AVAsset *currentPlayerAsset = _player.currentItem.asset;
    if ([currentPlayerAsset isKindOfClass:AVURLAsset.class]) {
        AVURLAsset *urlAsset = (AVURLAsset *)currentPlayerAsset;
        NSString * urlString = [[urlAsset URL] absoluteString];
        if (!_videoURL || ![_videoURL isEqualToString:urlString]) {
            _videoURL = urlString;
            videoDataUpdated = YES;
        }
    }
    if (![self doubleValueIsEqual:@(_lastDispatchedAdvertisedBitrate)  toOther:@(_lastAdvertisedBitrate)]) {
        videoDataUpdated = YES;
        _lastDispatchedAdvertisedBitrate = _lastAdvertisedBitrate;
        _sourceDimensionsHaveChanged = YES;
    }
    if (_sourceDimensionsHaveChanged && CGSizeEqualToSize(_videoSize, _lastDispatchedVideoSize)) {
        CGSize sourceDimensions = [self getSourceDimensions];
        if (!CGSizeEqualToSize(_videoSize, sourceDimensions)) {
            _videoSize = sourceDimensions;
            if (sourceDimensions.width > 0 && sourceDimensions.height > 0) {
                _lastDispatchedVideoSize = _videoSize;
                _sourceDimensionsHaveChanged = NO;
                videoDataUpdated = YES;
            }
        }
    }
    if (videoDataUpdated) {
        MUXSDKVideoData *videoData = [[MUXSDKVideoData alloc] init];
        if (_videoSize.width > 0 && _videoSize.height > 0) {
            [videoData setVideoSourceWidth:[NSNumber numberWithInt:_videoSize.width]];
            [videoData setVideoSourceHeight:[NSNumber numberWithInt:_videoSize.height]];
        }
        if (_videoIsLive) {
            [videoData setVideoSourceIsLive:@"true"];
        } else {
            [videoData setVideoSourceIsLive:@"false"];
            float sec = CMTimeGetSeconds(_videoDuration);
            if (sec && sec > 0) {
                float ms = sec * 1000;
                NSNumber *timeMs = [NSNumber numberWithFloat:ms];
                [videoData setVideoSourceDuration:[NSNumber numberWithLongLong:[timeMs longLongValue]]];
            }
        }
        if (_videoURL) {
            [videoData setVideoSourceUrl:_videoURL];
        }
        if (_lastAdvertisedBitrate > 0) {
            [videoData setVideoSourceAdvertisedBitrate:@(_lastAdvertisedBitrate)];
        }
        MUXSDKDataEvent *dataEvent = [[MUXSDKDataEvent alloc] init];
        [dataEvent setVideoData:videoData];
        [MUXSDKCore dispatchEvent:dataEvent forPlayer:_name];
    }
}

- (MUXSDKPlayerData *)getPlayerData {
    MUXSDKPlayerData *playerData = [[MUXSDKPlayerData alloc] init];

    // Mostly static values.
    [playerData setPlayerMuxPluginName:MUXSDKPluginName];
    [playerData setPlayerMuxPluginVersion:MUXSDKPluginVersion];
    [playerData setPlayerSoftwareName:_software];

    NSString *language = [[NSLocale preferredLanguages] firstObject];
    if (language) {
        [playerData setPlayerLanguageCode:language];
    }

    CGRect bounds = [self getVideoBounds];
    [playerData setPlayerWidth:[NSNumber numberWithInt:bounds.size.width]];
    [playerData setPlayerHeight:[NSNumber numberWithInt:bounds.size.height]];

    CGRect viewBounds = [self getViewBounds];
    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    // TODO: setPlayerIsFullscreen - should be a boolean.
    if ((viewBounds.size.width == screenBounds.size.width && viewBounds.size.height == screenBounds.size.height) ||
        (viewBounds.size.width == screenBounds.size.height && viewBounds.size.height == screenBounds.size.width)) {
        [playerData setPlayerIsFullscreen:@"true"];
    } else {
        [playerData setPlayerIsFullscreen:@"false"];
    }

    // Derived from the player.
    NSMutableArray *errors = [NSMutableArray new];
    NSString *defaultMsg = nil;
    NSInteger errorCode = 0;
    if (_player.error) {
        [errors addObject:[self buildError:@"p"
                                    domain:_player.error.domain
                                      code:_player.error.code
                                   message:_player.error.localizedDescription]];
        defaultMsg = _player.error.localizedDescription;
        errorCode = _player.error.code;
    } else if (_playerItem && _playerItem.error) {
        [errors addObject:[self buildError:@"i"
                                    domain:_playerItem.error.domain
                                      code:_playerItem.error.code
                                   message:_playerItem.error.localizedDescription]];
        defaultMsg = _playerItem.error.localizedDescription;
        errorCode = _playerItem.error.code;
        // Append the full error log.
        for (AVPlayerItemErrorLogEvent *event in _playerItem.errorLog.events) {
            [errors addObject:[self buildError:@"l"
                                        domain:event.errorDomain
                                          code:event.errorStatusCode
                                       message:(event.errorComment ? event.errorComment : @"")]];

        }
    } else {
        // Not sure if both checks are necessary here as when rate is 0 we expect to be paused and vice versa.
        if (_player.rate == 0.0) { // || _player.timeControlStatus == AVPlayerTimeControlStatusPaused) {
            [playerData setPlayerIsPaused:[NSNumber numberWithBool:YES]];
        } else {
            [playerData setPlayerIsPaused:[NSNumber numberWithBool:NO]];
        }
        float ms = CMTimeGetSeconds(_player.currentTime) * 1000;
        NSNumber *timeMs = [NSNumber numberWithFloat:ms];
        [playerData setPlayerPlayheadTime:[NSNumber numberWithLongLong:[timeMs longLongValue]]];
    }
    if ([errors count] > 0 && defaultMsg) {
        // Hard coded default value for now. Error codes on iOS have no meaning for now.
        // We'll reclassify/recode errors on the backend as we learn more.
        [playerData setPlayerErrorCode:[NSString stringWithFormat:@"%ld", (long)errorCode]];
        [playerData setPlayerErrorMessage:defaultMsg];
        NSError *error = nil;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:errors
                                                           options:0
                                                             error:&error];
        if (!error) {
            [playerData setPlayeriOSErrorData:[[NSString alloc] initWithData:jsonData
                                                                    encoding:NSUTF8StringEncoding]];
        }
    }
    // TODO: Airplay - don't set the view if we don't actually know what is going on.
    if (_player.externalPlaybackActive) {
        [playerData setPlayerRemotePlayed:[NSNumber numberWithBool:YES]];
    }
    return playerData;
}

- (NSDictionary *)buildError:(NSString *)level domain:(NSString *)domain code:(NSInteger)code message:(NSString *)message {
    return @{
             @"l": level,
             @"d": domain,
             @"c": [NSString stringWithFormat:@"%ld", (long)code],
             @"m": (message == nil ? @"n/a" : message),
             };
}

- (BOOL)isPlayerOK {
    if (!_player) {
        NSLog(@"MUXSDK-ERROR - Mux failed to find the AVPlayer for player name: %@", _name);
        return NO;
    }
    return YES;
}

- (BOOL)isPlaying {
    return _state == MUXSDKPlayerStatePlaying;
}

- (BOOL)isBuffering {
    return _state == MUXSDKPlayerStateBuffering;
}

- (BOOL)isTryingToPlay {
    return _state == MUXSDKPlayerStatePlay;
}

- (BOOL)isPlayingOrTryingToPlay {
    return [self isPlaying] || [self isTryingToPlay];
}

- (void)startBuffering {
    _state = MUXSDKPlayerStateBuffering;
}

- (void)dispatchViewInit {
    if (![self isPlayerOK]) {
        return;
    }
    [self resetVideoData];
    MUXSDKPlayerData *playerData = [self getPlayerData];
    MUXSDKViewInitEvent *event = [[MUXSDKViewInitEvent alloc] init];
    [event setPlayerData:playerData];
    [MUXSDKCore dispatchEvent:event forPlayer:_name];
    _state = MUXSDKPlayerStateViewInit;
}

- (void)dispatchPlayerReady {
    if (![self isPlayerOK]) {
        return;
    }
    MUXSDKPlayerData *playerData = [self getPlayerData];
    MUXSDKPlayerReadyEvent *event = [[MUXSDKPlayerReadyEvent alloc] init];
    [event setPlayerData:playerData];
    [MUXSDKCore dispatchEvent:event forPlayer:_name];
    _state = MUXSDKPlayerStateReady;
}

- (void)dispatchPlay {
    if (![self isPlayerOK]) {
        return;
    }
    [self.playDispatchDelegate playbackStartedForPlayer:_name];
    if (!_started) {
        _started = YES;
        [self updateLastPlayheadTime];
    }
    [self checkVideoData];
    MUXSDKPlayerData *playerData = [self getPlayerData];
    MUXSDKPlayEvent *event = [[MUXSDKPlayEvent alloc] init];
    [event setPlayerData:playerData];
    [MUXSDKCore dispatchEvent:event forPlayer:_name];
    _state = MUXSDKPlayerStatePlay;
    // Note that this computation is done in response to an observed rate change and not a time update
    // so we have to both compute our drift and update the playhead time as we do in the time update handler.
    [self computeDrift];
    [self updateLastPlayheadTime];
}

- (void)dispatchPlaying {
    if (![self isPlayerOK]) {
        return;
    }
    [self checkVideoData];
    MUXSDKPlayerData *playerData = [self getPlayerData];
    if (_seeking) {
        _seeking = NO;
        MUXSDKSeekedEvent *seekedEvent = [[MUXSDKSeekedEvent alloc] init];
        [seekedEvent setPlayerData:playerData];
        [MUXSDKCore dispatchEvent:seekedEvent forPlayer:_name];
    }
    MUXSDKPlayingEvent *event = [[MUXSDKPlayingEvent alloc] init];
    [event setPlayerData:playerData];
    [MUXSDKCore dispatchEvent:event forPlayer:_name];
    _state = MUXSDKPlayerStatePlaying;
}

- (void)dispatchPause {
    if (![self isPlayerOK]) {
        return;
    }
    [self checkVideoData];
    MUXSDKPlayerData *playerData = [self getPlayerData];
    MUXSDKPauseEvent *event = [[MUXSDKPauseEvent alloc] init];
    [event setPlayerData:playerData];
    [MUXSDKCore dispatchEvent:event forPlayer:_name];
    _state = MUXSDKPlayerStatePaused;
    [self computeDrift];
}

- (void)dispatchTimeUpdateFromTimer {
    // TODO: Consider rescheduling this timer when the app is not active.
    [self dispatchTimeUpdateEvent:[_player currentTime]];
}

- (void)dispatchTimeUpdateEvent:(CMTime)time {
    if (![self isPlayerOK] || ![self isPlaying]) {
        return;
    }
    // Check to make sure we don't over work.
    CFAbsoluteTime currentTime = CFAbsoluteTimeGetCurrent();
    if (currentTime - _lastTimeUpdate < MUXSDKMaxSecsBetweenTimeUpdate) {
        return;
    }
    _lastTimeUpdate = currentTime;
    [self checkVideoData];
    MUXSDKPlayerData *playerData = [self getPlayerData];
    MUXSDKTimeUpdateEvent *event = [[MUXSDKTimeUpdateEvent alloc] init];
    [event setPlayerData:playerData];
    [MUXSDKCore dispatchEvent:event forPlayer:_name];
}

- (void)dispatchError {
    if (!_automaticErrorTracking) {
        return;
    }
    if (![self isPlayerOK]) {
        return;
    }
    [self checkVideoData];
    MUXSDKPlayerData *playerData = [self getPlayerData];
    MUXSDKErrorEvent *event = [[MUXSDKErrorEvent alloc] init];
    [event setPlayerData:playerData];
    [MUXSDKCore dispatchEvent:event forPlayer:_name];
    _state = MUXSDKPlayerStateError;
}

- (void) dispatchError:(nonnull NSString *)code withMessage:(nonnull NSString *)message {
    if (![self isPlayerOK]) {
        return;
    }
    [self checkVideoData];
    MUXSDKPlayerData *playerData = [self getPlayerData];
    [playerData setPlayerErrorCode:code];
    [playerData setPlayerErrorMessage:message];
    MUXSDKErrorEvent *event = [[MUXSDKErrorEvent alloc] init];
    [event setPlayerData:playerData];
    [MUXSDKCore dispatchEvent:event forPlayer:_name];
    _state = MUXSDKPlayerStateError;
}

- (void)dispatchViewEnd {
    if (![self isPlayerOK]) {
        return;
    }
    [self checkVideoData];
    MUXSDKPlayerData *playerData = [self getPlayerData];
    MUXSDKViewEndEvent *event = [[MUXSDKViewEndEvent alloc] init];
    [event setPlayerData:playerData];
    [MUXSDKCore dispatchEvent:event forPlayer:_name];
    _state = MUXSDKPlayerStateViewEnd;
}

- (void)dispatchBandwidthMetric: (MUXSDKBandwidthMetricData *)loadData withType:(NSString *)type {
    if (![self isPlayerOK]) {
        return;
    }
    [self checkVideoData];
    MUXSDKPlayerData *playerData = [self getPlayerData];
    MUXSDKRequestBandwidthEvent *event = [[MUXSDKRequestBandwidthEvent alloc] init];
    event.type = type;
    [event setPlayerData:playerData];
    [event setBandwidthMetricData: loadData];
    [MUXSDKCore dispatchEvent:event forPlayer:_name];
}

- (void) dispatchOrientationChange:(MUXSDKViewOrientation) orientation {
    if (![self isPlayerOK]) {
        return;
    }
    [self checkVideoData];
    _orientation = orientation;
    MUXSDKPlayerData *playerData = [self getPlayerData];
    MUXSDKViewDeviceOrientationData *orientationData;
    switch (orientation) {
        case MUXSDKViewOrientationPortrait:
            orientationData = [[MUXSDKViewDeviceOrientationData alloc] initWithZ:@(90.0)];
            break;
        case MUXSDKViewOrientationLandscape:
            orientationData = [[MUXSDKViewDeviceOrientationData alloc] initWithZ:@(0.0)];
            break;
        default:
            return;
    }
    MUXSDKViewData *viewData = [[MUXSDKViewData alloc] init];
    viewData.viewDeviceOrientationData = orientationData;
    
    MUXSDKOrientationChangeEvent *event = [[MUXSDKOrientationChangeEvent alloc] init];
    [event setPlayerData:playerData];
    [event setViewData: viewData];
    [MUXSDKCore dispatchEvent:event forPlayer:_name];
}

- (void) dispatchRenditionChange {
    if (![self isPlayerOK]) {
        return;
    }
    [self checkVideoData];
    MUXSDKPlayerData *playerData = [self getPlayerData];
    MUXSDKRenditionChangeEvent *event = [[MUXSDKRenditionChangeEvent alloc] init];
    [event setPlayerData:playerData];
    [MUXSDKCore dispatchEvent:event forPlayer:_name];
}

- (void)updateLastPlayheadTime {
    _lastPlayheadTimeMs = [self getCurrentPlayheadTimeMs];
    _lastPlayheadTimeUpdated = CFAbsoluteTimeGetCurrent();
}

- (void)computeDrift {
    if (!_started) {
        // Avoid computing drift until playback has started (meaning play has been called).
        return;
    }
    // Determing if we are seeking by infering that we went into the pause state and the playhead moved a lot.
    float playheadTimeElapsed = ([self getCurrentPlayheadTimeMs] - _lastPlayheadTimeMs) / 1000;
    float wallTimeElapsed = CFAbsoluteTimeGetCurrent() - _lastPlayheadTimeUpdated;
    float drift = playheadTimeElapsed - wallTimeElapsed;
    // The playhead has to have moved > 500ms and we have to have signifigantly drifted in comparision to wall time.
    // We check both positive and negative to account for seeking forward and backward respectively.
    // Unbuffered seeks seem to update the playhead time when transitioning into play where as buffered seeks update the playhead time when paused.
    if (fabsf(playheadTimeElapsed) > MUXSDKMaxSecsSeekPlayheadShift &&
        fabsf(drift) > MUXSDKMaxSecsSeekClockDrift &&
        (_state == MUXSDKPlayerStatePaused || _state == MUXSDKPlayerStatePlay)) {
        _seeking = YES;
        MUXSDKInternalSeekingEvent *event = [[MUXSDKInternalSeekingEvent alloc] init];
        [event setPlayerData:[self getPlayerData]];
        [MUXSDKCore dispatchEvent:event forPlayer:_name];
    }
}

- (NSString *)getPlayerState {
    switch (_state) {
        case MUXSDKPlayerStatePaused:
            return @"Paused";
            break;

        case MUXSDKPlayerStatePlay:
            return @"Play";
            break;

        case MUXSDKPlayerStateBuffering:
            return @"Buffering";
            break;

        case MUXSDKPlayerStateError:
            return @"Error";
            break;

        case MUXSDKPlayerStateReady:
            return @"Ready";
            break;

        case MUXSDKPlayerStatePlaying:
            return @"Playing";
            break;

        case MUXSDKPlayerStateViewInit:
            return @"Init";
            break;

        case MUXSDKPlayerStateViewEnd:
            return @"End";
            break;

        default:
            return @"Unknown";
            break;
    }
}

- (BOOL)isPlayerInErrorState {
    if (!_player || !_playerItem) {
        return NO;
    }
    return _player.status == AVPlayerStatusFailed || _playerItem.status == AVPlayerItemStatusFailed;
}

- (void)observeValueForKeyPath:(NSString*) path
                      ofObject:(id)object
                        change:(NSDictionary*)change
                       context:(void*)context
{
    // AVPlayer Observations
    if (context == MUXSDKAVPlayerRateObservationContext) {
        if (_player.rate == 0 && [self isPlayingOrTryingToPlay]) {
            [self dispatchPause];
        } else if (_player.rate != 0 && ![self isPlayingOrTryingToPlay]) {
            [self dispatchPlay];
        }
    } else if (context == MUXSDKAVPlayerStatusObservationContext) {
        if ([self isPlayerInErrorState]) {
            [self dispatchError];
        }
    } else if (context == MUXSDKAVPlayerCurrentItemObservationContext) {
        [self monitorAVPlayerItem];

        // AVPlayerItem Observations
    } else if (context == MUXSDKAVPlayerItemStatusObservationContext) {
        if ([self isPlayerInErrorState]) {
            [self dispatchError];
        }
    }
}

- (void)dispatchAdEvent:(MUXSDKPlaybackEvent *)event {
    if (![self isPlayerOK]) {
        return;
    }
    [self checkVideoData];
    MUXSDKPlayerData *playerData = [self getPlayerData];
    [event setPlayerData:playerData];
    [MUXSDKCore dispatchEvent:event forPlayer:_name];
}

- (BOOL) doubleValueIsEqual:(NSNumber *) x toOther:(NSNumber *) n {
    return fabs([x doubleValue] - [n doubleValue]) < FLT_EPSILON;
}

@end


@implementation MUXSDKAVPlayerViewControllerBinding

- (id)initWithName:(NSString *)name software:(NSString *)software andView:(AVPlayerViewController *)view {
    self = [super initWithName:name andSoftware:software];
    if (self) {
        _viewController = view;
    }
    return (self);
}

- (CGRect)getVideoBounds {
#if TVOS
    return [[_viewController view] bounds];
#else
    return [_viewController videoBounds];
#endif
}

- (CGRect)getViewBounds {
    return [[_viewController view] bounds];
}

@end


@implementation MUXSDKAVPlayerLayerBinding

- (id)initWithName:(NSString *)name software:(NSString *)software andView:(AVPlayerLayer *)view {
    self = [super initWithName:name andSoftware:software];
    if (self) {
        _view = view;
    }
    return (self);
}

- (CGRect)getVideoBounds {
    return [_view videoRect];
}

- (CGRect)getViewBounds {
    return [_view bounds];
}

@end
