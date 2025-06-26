#import <Foundation/Foundation.h>
#import <CoreMedia/CoreMedia.h>
#import <UIKit/UIKit.h>

#if MUX_COCOAPODS
#if __has_include("MUXSDKStats-Swift.h")
#import "MUXSDKStats-Swift.h"
#else
#import <MUXSDKStats/MUXSDKStats-Swift.h>
#endif
#else
@import MUXSDKStatsInternal;
#endif

#import "MUXSDKStats/MUXSDKPlayerBinding.h"

#import "MUXSDKConnection.h"
#import "MUXSDKPlayerBindingConstants.h"

// SDK constants.
NSString *const MUXSDKPluginName = @"apple-mux";
NSString *const MUXSDKPluginVersion = @"4.7.0";
NSString *const MUXSessionDataPrefix = @"io.litix.data.";

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
static void *MUXSDKAVPlayerTimeControlStatusObservationContext = &MUXSDKAVPlayerTimeControlStatusObservationContext;

// AVPlayerItem observation contexts.
static void *MUXSDKAVPlayerItemStatusObservationContext = &MUXSDKAVPlayerItemStatusObservationContext;
static void *MUXSDKAVPlayerItemPlaybackBufferEmptyObservationContext = &MUXSDKAVPlayerItemPlaybackBufferEmptyObservationContext;

// This is the name of the exception that gets thrown when we remove an observer that
// is not registered. In theory, this should not really happen, but there is one async condition
// that makes it possible. Specifically when handling the _playerItem observers. The
// _playerItem observer is attached asynchonously, a developer could call destroyPlayer before
// we have attached the _playerItem observer
NSString * RemoveObserverExceptionName = @"NSRangeException";

@interface MUXSDKPlayerBinding ()

@property (nonatomic, nullable) MUXSDKPlayerMonitor *swiftMonitor
    API_AVAILABLE(ios(15), tvos(15));

@property (nonatomic) BOOL shouldTrackRenditionChanges;

@end

@implementation MUXSDKPlayerBinding {
    NSString *_name;
    NSString *_softwareName;
    AVPlayer *_player;
    AVPlayerItem *_playerItem;
    id _timeObserver;
    volatile MUXSDKPlayerState _state;
    CGSize _videoSize;
    CMTime _videoDuration;
    BOOL _videoIsLive;
    NSString *_videoURL;
    CFAbsoluteTime _lastTimeUpdate;
    NSTimer *_timeUpdateTimer;
    CFAbsoluteTime _lastPlayheadTimeUpdated;
    float _lastPlayheadTimeMs;
    CFAbsoluteTime _lastPlayheadTimeOnPauseUpdated;
    float _lastPlayheadTimeMsOnPause;
    BOOL _seeking;
    BOOL _started;
    BOOL _shouldHandleAVQueuePlayerItem;
    NSUInteger _lastTransferEventCount;
    double _lastTransferDuration;
    long long _lastTransferredBytes;
    MUXSDKViewOrientation _orientation;
    double _lastAdvertisedBitrate;
    double _lastDispatchedAdvertisedBitrate;
    BOOL _sourceDimensionsHaveChanged;
    CGSize _lastDispatchedVideoSize;
    BOOL _automaticErrorTracking;
    BOOL _isAdPlaying;
    BOOL _automaticVideoChange;
    BOOL _didTriggerManualVideoChange;
    BOOL _playbackIsLivestream;
    NSInteger _totalFrameDrops;
    BOOL _totalFrameDropsHasChanged;
    NSString *_softwareVersion;
}

- (id)initWithName:(NSString *)name 
       andSoftware:(NSString *)software {
    return [self initWithPlayerName:name
                       softwareName:software
                    softwareVersion:nil];
}

- (id)initWithPlayerName:(NSString *)playerName
            softwareName:(NSString *)softwareName {
    return [self initWithPlayerName:playerName
                       softwareName:softwareName
                    softwareVersion:nil];
}

- (id)initWithPlayerName:(NSString *)playerName
            softwareName:(NSString *)softwareName
         softwareVersion:(NSString *)softwareVersion {
    self = [super init];
    if (self) {
        _name = playerName;
        _softwareName = softwareName;
        _softwareVersion = softwareVersion;
        _automaticErrorTracking = true;
        _automaticVideoChange = true;
        _didTriggerManualVideoChange = false;
        _playbackIsLivestream = false;
    }
    return(self);
}

- (void)setAdPlaying:(BOOL)isAdPlaying {
    _isAdPlaying = isAdPlaying;
}

- (BOOL)setAutomaticErrorTracking:(BOOL)automaticErrorTracking {
    _automaticErrorTracking = automaticErrorTracking;
    return _automaticErrorTracking;
}

- (BOOL)setAutomaticVideoChange:(BOOL)automaticVideoChange {
    _automaticVideoChange = automaticVideoChange;
    return _automaticVideoChange;
}

- (void)attachAVPlayer:(AVPlayer *)player {
    if (_player) {
        [self detachAVPlayer];
    }
    if (!player) {
        NSLog(@"MUXSDK-ERROR - Cannot attach to NULL AVPlayer for player name: %@", _name);
        return;
    }
    if (@available(iOS 15, tvOS 15, *)) {
        self.shouldTrackRenditionChanges = NO;
        __weak typeof(self) weakSelf = self;
        self.swiftMonitor = [[MUXSDKPlayerMonitor alloc] initWithPlayer:player onEvent:^(MUXSDKBaseEvent *event) {
            [weakSelf dispatchSwiftMonitorEvent:event];
        }];
    } else {
        self.shouldTrackRenditionChanges = YES;
    }
    _player = player;
    __weak MUXSDKPlayerBinding *weakSelf = self;
    _lastTimeUpdate = CFAbsoluteTimeGetCurrent() - MUXSDKMaxSecsBetweenTimeUpdate;
    _timeObserver = [_player addPeriodicTimeObserverForInterval:[self getTimeObserverInternal]
                                                          queue:NULL
                                                     usingBlock:^(CMTime time) {
            if([weakSelf isAdPlaying]) {
                return;
            } else if ([weakSelf isTryingToPlay]) {
                [weakSelf startBuffering];
            } else if ([weakSelf isBuffering]) {
                [weakSelf dispatchPlaying];
            } else {
                [weakSelf dispatchTimeUpdateEvent:time];
            }
            
            [weakSelf computeDrift];
            [weakSelf updateLastPlayheadTime];
        }
    ];
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
    
    [_player addObserver:self
              forKeyPath:@"timeControlStatus"
                 options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                 context:MUXSDKAVPlayerTimeControlStatusObservationContext];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleDidPlayToEndTimeNotification:) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleAVPlayerAccess:) name:AVPlayerItemNewAccessLogEntryNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleRenditionChange:) name:RenditionChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleAVPlayerError:) name:AVPlayerItemNewErrorLogEntryNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleConnectionTypeDetected:) name:@"com.mux.connection-type-detected" object:nil];
    
    //
    // dylanjhaveri
    // See MUXSDKConnection.m for the tvos shortcoming
    //
    if ([[UIDevice currentDevice] userInterfaceIdiom] != UIUserInterfaceIdiomTV) {
        [MUXSDKConnection detectConnectionType];
    }
    
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
- (BOOL) isNotificationAboutCurrentPlayerItem:(NSNotification *)notif {
    return notif.object == _playerItem;
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
- (void)handleApplicationWillTerminate:(NSNotification *)notification {
    [self dispatchViewEnd];
    [self stopMonitoringAVPlayerItem];
    
    [MUXSDKCore destroyPlayer:self.name];
    
}

# pragma mark AVPlayerItemDidPlayToEndTimeNotification

- (void)handleDidPlayToEndTimeNotification:(NSNotification *)notification {
    if ([self isNotificationAboutCurrentPlayerItem:notification]) {
        MUXSDKEndedEvent *endedEvent = [[MUXSDKEndedEvent alloc] init];
        MUXSDKPlayerData *playerData = [self getPlayerData];
        endedEvent.playerData = playerData;
        [MUXSDKCore dispatchEvent:endedEvent forPlayer:_name];
    }
}

# pragma mark AVPlayerItemAccessLog

- (void)handleAVPlayerAccess:(NSNotification *)notif {
    dispatch_async(dispatch_get_main_queue(), ^{
        BOOL isNotificationRelevant = [self isNotificationAboutCurrentPlayerItem:notif];
        if (isNotificationRelevant) {
            AVPlayerItemAccessLog *accessLog = [((AVPlayerItem *)notif.object) accessLog];
            if (self.shouldTrackRenditionChanges) {
                [self handleRenditionChangeInAccessLog:accessLog];
            }
            [self calculateBandwidthMetricFromAccessLog:accessLog];
            [self updateViewingLivestream:accessLog];
            [self updateFrameDropsFromAccessLog:accessLog];
        }
    });
}

- (void)updateFrameDropsFromAccessLog:(AVPlayerItemAccessLog *)accessLog {
    AVPlayerItemAccessLogEvent *event = accessLog.events.lastObject;
    NSInteger loggedFrameDrops = event.numberOfDroppedVideoFrames;
    if(loggedFrameDrops != _totalFrameDrops) {
        _totalFrameDrops = loggedFrameDrops;
        _totalFrameDropsHasChanged = YES;
    }
}

- (void) handleRenditionChange:(NSNotification *) notif {
    NSDictionary *renditionChangeInfo = (NSDictionary *) notif.object;
    NSNumber *advertisedBitrate = renditionChangeInfo[RenditionChangeNotificationInfoAdvertisedBitrate];
    if (advertisedBitrate) {
        _lastAdvertisedBitrate = [advertisedBitrate doubleValue];
        if(![self doubleValueIsEqual:@(_lastDispatchedAdvertisedBitrate) toOther:@(_lastAdvertisedBitrate)]) {
            [self dispatchRenditionChange];
        }
    }
}

- (void) handleRenditionChangeInAccessLog:(AVPlayerItemAccessLog *) log {
    AVPlayerItemAccessLogEvent *lastEvent = log.events.lastObject;
    float advertisedBitrate = lastEvent.indicatedBitrate;
    BOOL bitrateHasChanged = ![self doubleValueIsEqual:@(_lastAdvertisedBitrate) toOther:@(advertisedBitrate)];
    if (!bitrateHasChanged) {
        return;
    }
    if (_lastAdvertisedBitrate == 0 || !_started) {
        _lastAdvertisedBitrate = advertisedBitrate;
        return;
    }
    //Dispatch rendition change event only when playback began
    if (lastEvent.playbackStartDate == nil) {
        return;
    }
    NSLog(@"MUXSDK-INFO - Switch advertised bitrate from: %f to: %f", _lastAdvertisedBitrate, advertisedBitrate);
    [[NSNotificationCenter defaultCenter] postNotificationName:RenditionChangeNotification object: @{
        RenditionChangeNotificationInfoAdvertisedBitrate: @(advertisedBitrate)
    }];
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
       loadData.requestUrl = event.URI;
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

- (void) updateViewingLivestream:(AVPlayerItemAccessLog *) log {
    AVPlayerItemAccessLogEvent *lastEvent = log.events.lastObject;
    NSString *playbackType = lastEvent.playbackType;
    _playbackIsLivestream = [playbackType isEqualToString:@"LIVE"];
}

# pragma mark AVPlayerItemErrorLog

- (void)handleAVPlayerError:(NSNotification *)notif {
    BOOL isNotificationRelevant = [self isNotificationAboutCurrentPlayerItem:notif];
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
    if (![self isTryingToPlay] && ![self isBuffering] && !_isAdPlaying) {
        [self dispatchTimeUpdateFromTimer];
    }
}

- (void)dealloc {
    [self detachAVPlayer];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemNewAccessLogEntryNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:RenditionChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemNewErrorLogEntryNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"com.mux.connection-type-detected" object:nil];
}

- (void) safelyRemoveTimeObserverForPlayer {
    if (_player != nil && _timeObserver != nil) {
        @try {
            [_player removeTimeObserver:_timeObserver];
            _timeObserver = nil;
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
    if (@available(iOS 15, tvOS 15, *)) {
        [self.swiftMonitor cancel];
        self.swiftMonitor = nil;
    }
    if (_playerItem) {
        [self stopMonitoringAVPlayerItem];
    }
    [self safelyRemoveTimeObserverForPlayer];
    [self safelyRemovePlayerObserverForKeyPath:@"rate"];
    [self safelyRemovePlayerObserverForKeyPath:@"status"];
    [self safelyRemovePlayerObserverForKeyPath:@"currentItem"];
    [self safelyRemovePlayerObserverForKeyPath:@"timeControlStatus"];
    _player = nil;
    if (_timeUpdateTimer) {
        [_timeUpdateTimer invalidate];
        _timeUpdateTimer = nil;
    }
}

- (void)monitorAVPlayerItem {
    if ((!_automaticVideoChange && !_didTriggerManualVideoChange) || _isAdPlaying) {
        return;
    }
    AVPlayerItem *currentItem = _player.currentItem;
    if (_playerItem) {
        if (_didTriggerManualVideoChange) {
            _didTriggerManualVideoChange = false;
        }
        [self dispatchViewEnd];
        [self stopMonitoringAVPlayerItem];
        
        if (currentItem) {
            [self.playDispatchDelegate videoChangedForPlayer:_name];
        }
        
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
    _playerItem = currentItem;
    if (currentItem) {
        [currentItem addObserver:self
                      forKeyPath:@"status"
                         options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                         context:MUXSDKAVPlayerItemStatusObservationContext];
        [currentItem addObserver:self
                      forKeyPath:@"playbackBufferEmpty"
                         options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                         context:MUXSDKAVPlayerItemPlaybackBufferEmptyObservationContext];
        
        [self dispatchSessionData];
    }
}

- (void)dispatchSessionData {
    AVAsset *asset = _player.currentItem.asset;
    // Load Session Data from HLS manifest
    __weak MUXSDKPlayerBinding *weakSelf = self;
    
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        [asset loadValuesAsynchronouslyForKeys:@[ @"metadata" ]
                             completionHandler:^{
            __strong __typeof(weakSelf) strongSelf = weakSelf;
            if (strongSelf == nil) {
                return;
            }

            NSError *error = nil;
            AVKeyValueStatus status = [asset statusOfValueForKey:@"metadata"
                                                           error:&error];
            if (status != AVKeyValueStatusLoaded || error != nil) {
                NSLog(@"MUXSDK-ERROR - Mux failed to load asset metadata for player name: %@",
                      [strongSelf name]);
                return;
            }
            
            NSMutableDictionary *sessionData = [[NSMutableDictionary alloc] init];
            for (AVMetadataItem *item in asset.metadata) {
                id<NSObject, NSCopying> key = [item key];
                if ([key isKindOfClass:[NSString class]]) {
                    NSString *keyString = (NSString *)key;
                    if ([keyString hasPrefix:MUXSessionDataPrefix]) {
                        NSString *itemKey = [keyString
                                             substringFromIndex: [MUXSessionDataPrefix length]];
                        [sessionData setObject:[item value]
                                        forKey:itemKey];
                    }
                }
            }
            
            if ([sessionData count] > 0) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    __strong __typeof(weakSelf) strongSelf = weakSelf;
                    if (strongSelf == nil) {
                        return;
                    }
                    
                    MUXSDKSessionDataEvent *dataEvent = [MUXSDKSessionDataEvent new];
                    [dataEvent setSessionData:sessionData];
                    [MUXSDKCore dispatchEvent:dataEvent
                                    forPlayer:[strongSelf name]];
                });
            }
        }];
    });
}

- (void)stopMonitoringAVPlayerItem {
    [self safelyRemovePlayerItemObserverForKeyPath:@"status"];
    [self safelyRemovePlayerItemObserverForKeyPath:@"playbackBufferEmpty"];
    _playerItem = nil;
    if (!_isAdPlaying) {
        [MUXSDKCore destroyPlayer: _name];
    }
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
    return [self getViewBoundsValue].CGRectValue;
}

- (nullable NSValue *)getViewBoundsValue {
    return [NSValue valueWithCGRect: CGRectMake(0, 0, 0, 0)];
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

    if (self.shouldTrackRenditionChanges) {
        if (![self doubleValueIsEqual:@(_lastDispatchedAdvertisedBitrate) toOther:@(_lastAdvertisedBitrate)]) {
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
    }

    NSNumber *checkedFrameDrops = nil;
    if(_totalFrameDropsHasChanged && _totalFrameDrops > 0) {
        _totalFrameDropsHasChanged = NO;
        videoDataUpdated = YES;
        checkedFrameDrops = [NSNumber numberWithLong:_totalFrameDrops];
    }
    
    if (videoDataUpdated) {
        MUXSDKVideoData *videoData = [[MUXSDKVideoData alloc] init];
        if (self.shouldTrackRenditionChanges) {
            if (_videoSize.width > 0 && _videoSize.height > 0) {
                [videoData setVideoSourceWidth:[NSNumber numberWithInt:_videoSize.width]];
                [videoData setVideoSourceHeight:[NSNumber numberWithInt:_videoSize.height]];
            }
            if (_lastAdvertisedBitrate > 0 && _started) {
                [videoData setVideoSourceAdvertisedBitrate:@(_lastAdvertisedBitrate)];
            }
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
        if(checkedFrameDrops) {
            [videoData setVideoSourceFrameDrops:checkedFrameDrops];
        }
        
        MUXSDKDataEvent *dataEvent = [[MUXSDKDataEvent alloc] init];
        [dataEvent setVideoData:videoData];
        [MUXSDKCore dispatchEvent:dataEvent forPlayer:_name];
    }
}

- (void)updatePlayerMetadata:(MUXSDKPlayerData *)playerData {
    // Mostly static values.
    [playerData setPlayerMuxPluginName:MUXSDKPluginName];
    [playerData setPlayerMuxPluginVersion:MUXSDKPluginVersion];
    [playerData setPlayerSoftwareName:_softwareName];
    [playerData setPlayerSoftwareVersion:_softwareVersion];

    NSString *language = [[NSLocale preferredLanguages] firstObject];
    if (language) {
        [playerData setPlayerLanguageCode:language];
    }
}

- (void)updatePlayerDimensions:(MUXSDKPlayerData *)playerData {
    NSValue *viewBoundsValue = [self getViewBoundsValue];
    if(viewBoundsValue == nil){
        return;
    }
    
    CGRect viewBounds = [viewBoundsValue CGRectValue];
    [playerData setPlayerWidth:[NSNumber numberWithInt:viewBounds.size.width]];
    [playerData setPlayerHeight:[NSNumber numberWithInt:viewBounds.size.height]];


    #if TARGET_OS_VISION
    // TODO: Call analogous vision OS API for the area containing
    // the player window, which seems like the rough equivalent
    // of UIScreen
    [playerData setPlayerIsFullscreen:@"false"];
    #else
    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    // TODO: setPlayerIsFullscreen - should be a boolean.
    if ((viewBounds.size.width == screenBounds.size.width && viewBounds.size.height == screenBounds.size.height) ||
        (viewBounds.size.width == screenBounds.size.height && viewBounds.size.height == screenBounds.size.width)) {
        [playerData setPlayerIsFullscreen:@"true"];
    } else {
        [playerData setPlayerIsFullscreen:@"false"];
    }
    #endif
}

- (MUXSDKPlayerData *)getPlayerData {
    MUXSDKPlayerData *playerData = [MUXSDKPlayerData new];
    [self updatePlayerMetadata:playerData];
    [self updatePlayerDimensions:playerData];

    // Not sure if both checks are necessary here as when rate is 0 we expect to be paused and vice versa.
    if (_player.rate == 0.0) { // || _player.timeControlStatus == AVPlayerTimeControlStatusPaused) {
        [playerData setPlayerIsPaused:[NSNumber numberWithBool:YES]];
    } else {
        [playerData setPlayerIsPaused:[NSNumber numberWithBool:NO]];
    }
    if (!_isAdPlaying) {
        float ms = CMTimeGetSeconds(_player.currentTime) * 1000;
        [self setPlayerPlayheadTime:ms onPlayerData:playerData];
    }

    // Only report program time metrics if this is a live stream
    if (_playbackIsLivestream) {
        // Sampling Data
        NSTimeInterval currentTimestamp = [_player.currentItem.currentDate timeIntervalSince1970];
        playerData.playerProgramTime = [NSNumber numberWithLongLong: (long long)(currentTimestamp * 1000)];


        if ([_player.currentItem.seekableTimeRanges count] > 0) {
            // seekableTimeRanges is ordered, so we only need to look at the last one
            // Note about seekableTimeRanges: the meaning of the values in seekableTimeRanges appears to change
            // across OS versions and device types. Sometimes the duration appears to take holdbacks from the HLS
            // manifest into consideration, and other times not. Use this value with caution.
            CMTimeRange seekableRange = [_player.currentItem.seekableTimeRanges.lastObject CMTimeRangeValue];
            CGFloat start = CMTimeGetSeconds(seekableRange.start);
            CGFloat duration = CMTimeGetSeconds(seekableRange.duration);
            CGFloat currentTimeOfVideo = CMTimeGetSeconds([[_player currentItem] currentTime]);
            CGFloat livePosition = start + duration;
            NSTimeInterval viewStartTimestamp = currentTimestamp - currentTimeOfVideo;
            NSTimeInterval liveEdgeProgramTimestamp = viewStartTimestamp + livePosition;

            playerData.playerLiveEdgeProgramTime = [NSNumber numberWithLongLong:(long long)(liveEdgeProgramTimestamp * 1000)];
        }
    }

    // TODO: Airplay - don't set the view if we don't actually know what is going on.
    #if TARGET_OS_VISION

    #else
    if (_player.externalPlaybackActive) {
        [playerData setPlayerRemotePlayed:[NSNumber numberWithBool:YES]];
    }
    #endif
    return playerData;
}

- (void) setPlayerPlayheadTime:(float) playheadTimeMs onPlayerData:(MUXSDKPlayerData *) playerData {
    NSNumber *timeMs = [NSNumber numberWithFloat:playheadTimeMs];
    [playerData setPlayerPlayheadTime:[NSNumber numberWithLongLong:[timeMs longLongValue]]];
}

- (BOOL)hasPlayer {
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

- (BOOL) isPaused {
    return _state == MUXSDKPlayerStatePaused;
}

- (BOOL)isPlayingOrTryingToPlay {
    return [self isPlaying] || [self isTryingToPlay];
}

- (BOOL) isPausedWhileAirPlaying {
    #if TARGET_OS_VISION
    return NO;
    #else
    return _player.externalPlaybackActive && [self isPaused];
    #endif
}

- (BOOL) isAdPlaying {
    return _isAdPlaying;
}

- (NSString *) name {
    return _name;
}

- (void)startBuffering {
    _state = MUXSDKPlayerStateBuffering;
}

- (void)dispatchSwiftMonitorEvent:(MUXSDKBaseEvent *)event {
    // Shims for things not yet handled in Swift monitor:
    if ([event isKindOfClass:MUXSDKPlaybackEvent.class]) {
        MUXSDKPlaybackEvent *playbackEvent = (MUXSDKPlaybackEvent *)event;

        if (_isAdPlaying) {
            playbackEvent.playerData.playerPlayheadTime = nil;
        }

        [self updatePlayerMetadata:playbackEvent.playerData];
        [self updatePlayerDimensions:playbackEvent.playerData];
    }

    [MUXSDKCore dispatchEvent:event forPlayer:_name];
}

- (void)dispatchViewInit {
    if (![self hasPlayer]) {
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
    if (![self hasPlayer]) {
        return;
    }
    MUXSDKPlayerData *playerData = [self getPlayerData];
    MUXSDKPlayerReadyEvent *event = [[MUXSDKPlayerReadyEvent alloc] init];
    [event setPlayerData:playerData];
    [MUXSDKCore dispatchEvent:event forPlayer:_name];
    _state = MUXSDKPlayerStateReady;
}

- (void)dispatchPlay {
    if (![self hasPlayer]) {
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
    if(!_isAdPlaying) {
        [self computeDrift];
        [self updateLastPlayheadTime];
    }
}

- (void)dispatchPlaying {
    if (![self hasPlayer]) {
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
    if (![self hasPlayer]) {
        return;
    }
    [self checkVideoData];
    [self updateLastPlayheadTimeOnPause];
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
    if (![self hasPlayer] || ![self isPlaying]) {
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
    if (![self hasPlayer]) {
        return;
    }
    [self checkVideoData];
    MUXSDKPlayerData *playerData = [self getPlayerData];

    // Derived from the player.
    if (_player.error) {
        NSInteger errorCode = _player.error.code;
        if (errorCode != 0 && errorCode != NSNotFound) {
            [playerData setPlayerErrorCode:[NSString stringWithFormat:@"%ld", (long)errorCode]];
        }
        NSString *errorLocalizedDescription = _player.error.localizedDescription;
        if (errorLocalizedDescription != nil) {
            [playerData setPlayerErrorMessage:errorLocalizedDescription];
        }
    } else if (_playerItem && _playerItem.error) {
        NSInteger errorCode = _playerItem.error.code;
        if (errorCode != 0 && errorCode != NSNotFound) {
            [playerData setPlayerErrorCode:[NSString stringWithFormat:@"%ld", (long)errorCode]];
        }
        NSString *errorLocalizedDescription = _playerItem.error.localizedDescription;
        if (errorLocalizedDescription != nil) {
            [playerData setPlayerErrorMessage:errorLocalizedDescription];
        }
    }

    MUXSDKErrorEvent *event = [[MUXSDKErrorEvent alloc] init];
    [event setPlayerData:playerData];
    [MUXSDKCore dispatchEvent:event forPlayer:_name];
    _state = MUXSDKPlayerStateError;
}

- (void)dispatchError:(nonnull NSString *)code
          withMessage:(nonnull NSString *)message {
    if (![self hasPlayer]) {
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

- (void)dispatchError:(nonnull NSString *)code
          withMessage:(nonnull NSString *)message
     withErrorContext:(nonnull NSString *)errorContext {
    if (![self hasPlayer]) {
        return;
    }
    [self checkVideoData];
    MUXSDKPlayerData *playerData = [self getPlayerData];
    [playerData setPlayerErrorCode:code];
    [playerData setPlayerErrorMessage:message];
    [playerData setPlayerErrorContext:errorContext];
    MUXSDKErrorEvent *event = [[MUXSDKErrorEvent alloc] init];
    [event setPlayerData:playerData];
    [MUXSDKCore dispatchEvent:event forPlayer:_name];
    _state = MUXSDKPlayerStateError;
}

- (void)dispatchError:(nonnull NSString *)code
          withMessage:(nonnull NSString *)message
             severity:(MUXSDKErrorSeverity)severity {
    if (![self hasPlayer]) {
        return;
    }
    [self checkVideoData];
    MUXSDKPlayerData *playerData = [self getPlayerData];
    [playerData setPlayerErrorCode:code];
    [playerData setPlayerErrorMessage:message];
    MUXSDKErrorEvent *event = [[MUXSDKErrorEvent alloc] init];
    [event setPlayerData:playerData];
    [event setSeverity:severity];
    [MUXSDKCore dispatchEvent:event forPlayer:_name];
    _state = MUXSDKPlayerStateError;
}

- (void)dispatchError:(nonnull NSString *)code
          withMessage:(nonnull NSString *)message
             severity:(MUXSDKErrorSeverity)severity
         errorContext:(nonnull NSString *)errorContext {
    if (![self hasPlayer]) {
        return;
    }
    [self checkVideoData];
    MUXSDKPlayerData *playerData = [self getPlayerData];
    [playerData setPlayerErrorCode:code];
    [playerData setPlayerErrorMessage:message];
    [playerData setPlayerErrorContext:errorContext];
    MUXSDKErrorEvent *event = [[MUXSDKErrorEvent alloc] init];
    [event setPlayerData:playerData];
    [event setSeverity:severity];
    [MUXSDKCore dispatchEvent:event forPlayer:_name];
    _state = MUXSDKPlayerStateError;
}

- (void)dispatchError:(nonnull NSString *)code
          withMessage:(nonnull NSString *)message
             severity:(MUXSDKErrorSeverity)severity
  isBusinessException:(BOOL)isBusinessException {
    if (![self hasPlayer]) {
        return;
    }
    [self checkVideoData];
    MUXSDKPlayerData *playerData = [self getPlayerData];
    [playerData setPlayerErrorCode:code];
    [playerData setPlayerErrorMessage:message];
    MUXSDKErrorEvent *event = [[MUXSDKErrorEvent alloc] init];
    [event setPlayerData:playerData];
    [event setSeverity:severity];
    [event setIsBusinessException:isBusinessException];
    [MUXSDKCore dispatchEvent:event forPlayer:_name];
    _state = MUXSDKPlayerStateError;
}

- (void)dispatchError:(nonnull NSString *)code
          withMessage:(nonnull NSString *)message
             severity:(MUXSDKErrorSeverity)severity
  isBusinessException:(BOOL)isBusinessException
         errorContext:(nonnull NSString *)errorContext {
    if (![self hasPlayer]) {
        return;
    }
    [self checkVideoData];
    MUXSDKPlayerData *playerData = [self getPlayerData];
    [playerData setPlayerErrorCode:code];
    [playerData setPlayerErrorMessage:message];
    [playerData setPlayerErrorContext:errorContext];
    MUXSDKErrorEvent *event = [[MUXSDKErrorEvent alloc] init];
    [event setPlayerData:playerData];
    [event setSeverity:severity];
    [event setIsBusinessException:isBusinessException];
    [MUXSDKCore dispatchEvent:event forPlayer:_name];
    _state = MUXSDKPlayerStateError;
}

- (void)dispatchViewEnd {
    if (![self hasPlayer]) {
        return;
    }
    if (_state == MUXSDKPlayerStateViewEnd) {
        NSLog(@"MUXSDK-WARNING - Attempting to dispatch a viewend more than once before a new view is initialized");
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
    if (![self hasPlayer]) {
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
    if (![self hasPlayer]) {
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
    if (![self hasPlayer]) {
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

- (void)updateLastPlayheadTimeOnPause {
    _lastPlayheadTimeMsOnPause = [self getCurrentPlayheadTimeMs];
    _lastPlayheadTimeOnPauseUpdated = CFAbsoluteTimeGetCurrent();
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
        fabsf(drift) > MUXSDKMaxSecsSeekClockDrift) {
        if (_state == MUXSDKPlayerStatePaused || _state == MUXSDKPlayerStatePlay) {
            _seeking = YES;
            MUXSDKInternalSeekingEvent *event = [[MUXSDKInternalSeekingEvent alloc] init];
            MUXSDKPlayerData *playerData = [self getPlayerData];
            if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomTV) {
                [self setPlayerPlayheadTime:_lastPlayheadTimeMsOnPause onPlayerData:playerData];
            }
            [event setPlayerData:playerData];
            [MUXSDKCore dispatchEvent:event forPlayer:_name];
        } else if (_state == MUXSDKPlayerStatePlaying || _state == MUXSDKPlayerStateBuffering) {
            // If seek is called programmatically while the player is playing or buffering it will enter this block, otherwise it will run the upper branch logic
            _seeking = YES;
            MUXSDKInternalSeekingEvent *seekingEvent = [[MUXSDKInternalSeekingEvent alloc] init];
            MUXSDKPlayerData *playerData = [self getPlayerData];
            [self setPlayerPlayheadTime:_lastPlayheadTimeMs onPlayerData:playerData];
            [seekingEvent setPlayerData:playerData];
            [MUXSDKCore dispatchEvent:seekingEvent forPlayer:_name];
        }
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
    // check for presence of errors rather than player status
    return _player.error || _playerItem.error;
}

- (void)observeValueForKeyPath:(NSString*) path
                      ofObject:(id)object
                        change:(NSDictionary*)change
                       context:(void*)context
{
    // AVPlayer Observations
    if (context == MUXSDKAVPlayerRateObservationContext) {
        if(_isAdPlaying) {
            return;
        }
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
    } else if (context == MUXSDKAVPlayerItemPlaybackBufferEmptyObservationContext) {
        if ([_playerItem isPlaybackBufferEmpty] && _player.timeControlStatus != AVPlayerTimeControlStatusPlaying && [self isPausedWhileAirPlaying] && !_isAdPlaying) {
            // We erroneously detected a pause when in fact we are rebuffering. This *only* happens in AirPlay mode
            [self dispatchPlay];
            [self dispatchPlaying];
        }
    } else if (context == MUXSDKAVPlayerTimeControlStatusObservationContext) {
        if (_seeking && _state == MUXSDKPlayerStatePlaying) {
            // Dispatch seeked and playing events for programmatic seeks on playing status
            [self dispatchPlaying];
        }
    }
}

- (void)dispatchAdEvent:(MUXSDKPlaybackEvent *)event {
    if (![self hasPlayer]) {
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

- (void)didTriggerManualVideoChange {
    _didTriggerManualVideoChange = true;
}
@end


@interface MUXSDKAVPlayerViewControllerBinding ()

@property (nonatomic, readonly) AVPlayerViewController *viewController;

@end

@implementation MUXSDKAVPlayerViewControllerBinding

- (id)initWithName:(NSString *)name software:(NSString *)software andView:(AVPlayerViewController *)view {
    return  [self initWithPlayerName:name
                        softwareName:software
                     softwareVersion:nil
                playerViewController:view];
}

- (CGRect)getVideoBounds {
#if TARGET_OS_TV
    return [[_viewController view] bounds];
#else
    return [_viewController videoBounds];
#endif
}

- (nullable NSValue *)getViewBoundsValue {
    if (![NSThread isMainThread]) {
        return nil;
    }
    UIView *view = _viewController.viewIfLoaded;
    if (view == nil) {
        return nil;
    }

    return [NSValue valueWithCGRect:view.bounds];
}

- (nonnull id)initWithPlayerName:(nonnull NSString *)playerName
                    softwareName:(nullable NSString *)softwareName
            playerViewController:(nonnull AVPlayerViewController *)playerViewController {
    return  [self initWithPlayerName:playerName
                        softwareName:softwareName
                     softwareVersion:nil
                playerViewController:playerViewController];
}

- (nonnull id)initWithPlayerName:(nonnull NSString *)playerName
                    softwareName:(nullable NSString *)softwareName
                 softwareVersion:(nullable NSString *)softwareVersion
            playerViewController:(nonnull AVPlayerViewController *)playerViewController {
    self = [super initWithPlayerName:playerName
                        softwareName:softwareName
                     softwareVersion:softwareVersion];
    if (self) {
        _viewController = playerViewController;
    }
    return self;
}

@end


@interface MUXSDKAVPlayerLayerBinding ()

@property (nonatomic, readonly) AVPlayerLayer *view;

@end

@implementation MUXSDKAVPlayerLayerBinding

- (id)initWithName:(NSString *)name 
          software:(NSString *)software
           andView:(AVPlayerLayer *)view {
    return [self initWithPlayerName:name
                       softwareName:software
                    softwareVersion:nil
                        playerLayer:view];
}

- (nonnull id)initWithPlayerName:(nonnull NSString *)playerName
                    softwareName:(nullable NSString *)softwareName
                     playerLayer:(nonnull AVPlayerLayer *)playerLayer {
    return [self initWithPlayerName:playerName
                       softwareName:softwareName
                    softwareVersion:nil
                        playerLayer:playerLayer];
}

- (nonnull id)initWithPlayerName:(nonnull NSString *)playerName
                    softwareName:(nullable NSString *)softwareName
                 softwareVersion:(nullable NSString *)softwareVersion
                     playerLayer:(nonnull AVPlayerLayer *)playerLayer {
    self = [super initWithPlayerName:playerName
                        softwareName:softwareName
                     softwareVersion:softwareVersion];
    if (self) {
        _view = playerLayer;
    }
    return self;
}

- (CGRect)getVideoBounds {
    return [_view videoRect];
}

- (nullable NSValue *)getViewBoundsValue {
    return [NSValue valueWithCGRect:_view.bounds];
}

@end


@interface MUXSDKAVPlayerBinding ()

@property (nonatomic, readonly) CGSize fixedPlayerSize;

@end

@implementation MUXSDKAVPlayerBinding

- (nonnull id)initWithPlayerName:(nonnull NSString *)playerName
                    softwareName:(nullable NSString *)softwareName
                 fixedPlayerSize:(CGSize)fixedPlayerSize {
    return [self initWithPlayerName:playerName
                       softwareName:softwareName
                    softwareVersion:nil
                    fixedPlayerSize:fixedPlayerSize];
}

- (nonnull id)initWithPlayerName:(nonnull NSString *)playerName
                    softwareName:(nullable NSString *)softwareName
                 softwareVersion:(nullable NSString *)softwareVersion
                 fixedPlayerSize:(CGSize)fixedPlayerSize {

    self = [super initWithPlayerName:playerName
                        softwareName:softwareName
                     softwareVersion:softwareVersion];
    if (self) {
        _fixedPlayerSize = fixedPlayerSize;
    }
    return self;
}

- (CGRect)getVideoBounds {
    return CGRectMake(
                      0.0,
                      0.0,
                      0.0,
                      0.0
                      );
}

- (nullable NSValue *)getViewBoundsValue {
    return [NSValue valueWithCGRect:CGRectMake(
        0.0,
        0.0,
        _fixedPlayerSize.width,
        _fixedPlayerSize.height
    )];
}

@end
