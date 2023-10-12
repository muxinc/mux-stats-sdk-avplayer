#ifndef MUXSDKPlayerBinding_h
#define MUXSDKPlayerBinding_h

#if __has_feature(modules)
@import AVKit;
@import AVFoundation;
@import Foundation;
@import MuxCore;
#else
#import <Foundation/Foundation.h>
#import <AVKit/AVKit.h>
#import <AVFoundation/AVFoundation.h>
#if TVOS
#import <MuxCore/MuxCoreTv.h>
#else
#import <MuxCore/MuxCore.h>
#endif
#endif
#endif

typedef NS_ENUM(NSUInteger, MUXSDKPlayerState) {
    MUXSDKPlayerStateReady,
    MUXSDKPlayerStateViewInit,
    MUXSDKPlayerStatePlay,
    MUXSDKPlayerStateBuffering,
    MUXSDKPlayerStatePlaying,
    MUXSDKPlayerStatePaused,
    MUXSDKPlayerStateError,
    MUXSDKPlayerStateViewEnd,
};

typedef NS_ENUM(NSUInteger, MUXSDKViewOrientation) {
    MUXSDKViewOrientationUnknown,
    MUXSDKViewOrientationPortrait,
    MUXSDKViewOrientationLandscape
};

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnullability-completeness"

@protocol MUXSDKPlayDispatchDelegate
- (void) playbackStartedForPlayer:(NSString *) name;
- (void) videoChangedForPlayer:(NSString *) name;
@end

#pragma clang diagnostic pop

@interface MUXSDKPlayerBinding : NSObject {

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnullability-completeness"

@private
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

@property (nonatomic, weak) id<MUXSDKPlayDispatchDelegate>  playDispatchDelegate;

- (id)initWithName:(NSString *)name 
       andSoftware:(NSString *)software;

- (void)attachAVPlayer:(AVPlayer *)player;
- (void)detachAVPlayer;
- (void)programChangedForPlayer;
- (void)prepareForAvQueuePlayerNextItem;
- (CGRect)getViewBounds;
- (void)dispatchViewInit;
- (void)dispatchPlayerReady;
- (void)dispatchPlay;
- (void)dispatchPlaying;
- (void)dispatchPause;
- (void)dispatchTimeUpdateEvent:(CMTime)time;
- (void)dispatchError;
- (void)dispatchViewEnd;
- (void)dispatchOrientationChange:(MUXSDKViewOrientation) orientation;
- (void)dispatchAdEvent:(MUXSDKPlaybackEvent *)event;
- (float)getCurrentPlayheadTimeMs;
- (void)dispatchRenditionChange;
- (void)setAdPlaying:(BOOL)isAdPlaying;
- (BOOL)setAutomaticErrorTracking:(BOOL)automaticErrorTracking;
- (BOOL)setAutomaticVideoChange:(BOOL)automaticVideoChange;
- (void)dispatchError:(NSString *)code withMessage:(NSString *)message;
- (void)didTriggerManualVideoChange;

#pragma clang diagnostic pop

- (nonnull id)initWithPlayerName:(nonnull NSString *)playerName
                    softwareName:(nullable NSString *)softwareName;

- (nonnull id)initWithPlayerName:(nonnull NSString *)playerName
                    softwareName:(nullable NSString *)softwareName
                 softwareVersion:(nullable NSString *)softwareVersion;

@end

@interface MUXSDKAVPlayerViewControllerBinding : MUXSDKPlayerBinding {
@private
    AVPlayerViewController *_viewController;
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnullability-completeness"

/// Initializes a binding that listens for and dispatches player events
/// - Parameters:
///   - name: A name for this instance of the player
///   - software: The name of the underlying player software
///   - view: An AVPlayerViewController to monitor using this binding
- (id)initWithName:(NSString *)name
          software:(NSString *)software
           andView:(AVPlayerViewController *)view __attribute__((deprecated("Please migrate to initWithPlayerName:softwareName:playerViewController:")));

#pragma clang diagnostic pop


/// Initializes a binding that listens for and dispatches player events
/// - Parameters:
///   - playerName: A name for this instance of the player
///   - softwareName: The name of the underlying player software
///   - playerViewController: An AVPlayerViewController to monitor using this binding
- (nonnull id)initWithPlayerName:(nonnull NSString *)playerName
                    softwareName:(nullable NSString *)softwareName
            playerViewController:(nonnull AVPlayerViewController *)playerViewController;


/// Initializes a binding that listens for and dispatches player events
/// - Parameters:
///   - playerName: A name for this instance of the player
///   - softwareName: The name of the underlying player software
///   - softwareVersion: The version of this player software
///   - playerViewController: An AVPlayerViewController to monitor using this binding
- (nonnull id)initWithPlayerName:(nonnull NSString *)playerName
                    softwareName:(nullable NSString *)softwareName
                 softwareVersion:(nullable NSString *)softwareVersion
            playerViewController:(nonnull AVPlayerViewController *)playerViewController;

@end

@interface MUXSDKAVPlayerLayerBinding : MUXSDKPlayerBinding {
@private
    AVPlayerLayer *_view;
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnullability-completeness"


/// Initializes a binding that listens for and dispatches player events
/// - Parameters:
///   - name: A name for this instance of the player
///   - software: The name of the underlying player software
///   - view: An AVPlayerLayer to monitor
- (id)initWithName:(NSString *)name
          software:(NSString *)software
           andView:(AVPlayerLayer *)view __attribute__((deprecated("Please migrate to initWithPlayerName:softwareName:playerLayer:")));;

#pragma clang diagnostic pop


/// Initializes a binding that listens for and dispatches player events
/// - Parameters:
///   - playerName: A name for this instance of the player
///   - softwareName: The name of the underlying player software
///   - playerLayer: An AVPlayerLayer to monitor
- (nonnull id)initWithPlayerName:(nonnull NSString *)playerName
                    softwareName:(nullable NSString *)softwareName
                     playerLayer:(nonnull AVPlayerLayer *)playerLayer;


/// Initializes a binding that listens for and dispatches player events
/// - Parameters:
///   - playerName: A name for this instance of the player
///   - softwareName: The name of the underlying player software
///   - softwareVersion: The version of this player software
///   - playerLayer: An AVPlayerLayer to monitor
- (nonnull id)initWithPlayerName:(nonnull NSString *)playerName
                    softwareName:(nullable NSString *)softwareName
                 softwareVersion:(nullable NSString *)softwareVersion
                     playerLayer:(nonnull AVPlayerLayer *)playerLayer;

@end

@interface MUXSDKAVPlayerBinding : MUXSDKPlayerBinding {
@private
    CGSize _fixedPlayerSize;
}


/// Initializes a binding that listens for and dispatches player events
/// - Parameters:
///   - playerName: A name for this instance of the player
///   - softwareName: The name of the underlying player software
///   - fixedPlayerSize: A fixed size of your player that will not change, inclusive of any letter boxed or pillar boxed areas. If monitoring audio only media, pass in CGSizeMake(0.0, 0.0)
- (nonnull id)initWithPlayerName:(nonnull NSString *)playerName
                    softwareName:(nullable NSString *)softwareName
                 fixedPlayerSize:(CGSize)fixedPlayerSize;


/// Initializes a binding that listens for and dispatches player events
/// - Parameters:
///   - playerName: A name for this instance of the player
///   - softwareName: The name of the underlying player software
///   - softwareVersion: The version of this player software
///   - fixedPlayerSize: A fixed size of your player that will not change, inclusive of any letter boxed or pillar boxed areas. If monitoring audio only media, pass in CGSizeMake(0.0, 0.0)
- (nonnull id)initWithPlayerName:(nonnull NSString *)playerName
                    softwareName:(nullable NSString *)softwareName
                 softwareVersion:(nullable NSString *)softwareVersion
                 fixedPlayerSize:(CGSize)fixedPlayerSize;

@end
