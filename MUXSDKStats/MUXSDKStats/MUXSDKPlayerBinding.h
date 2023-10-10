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

/// Player software name reported by events dispatched
/// by this binding
@property (nonatomic) NSString *softwareName;

/// Player software version reported by events dispatched
/// by this binding
@property (nonatomic) NSString *softwareVersion;

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

- (id)initWithName:(NSString *)name 
          software:(NSString *)software
           andView:(AVPlayerViewController *)view __attribute__((deprecated("Please migrate to initWithPlayerName:softwareName:playerViewController:")));

#pragma clang diagnostic pop

- (nonnull id)initWithPlayerName:(nonnull NSString *)playerName
                    softwareName:(nullable NSString *)softwareName
            playerViewController:(nonnull AVPlayerViewController *)playerViewController;

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

- (id)initWithName:(NSString *)name
          software:(NSString *)software
           andView:(AVPlayerLayer *)view __attribute__((deprecated("Please migrate to initWithPlayerName:softwareName:playerLayer:")));;

#pragma clang diagnostic pop

- (nonnull id)initWithPlayerName:(nonnull NSString *)playerName
                    softwareName:(nullable NSString *)softwareName
                     playerLayer:(nonnull AVPlayerLayer *)playerLayer;

- (nonnull id)initWithPlayerName:(nonnull NSString *)playerName
                    softwareName:(nullable NSString *)softwareName
                 softwareVersion:(nullable NSString *)softwareVersion
                     playerLayer:(nonnull AVPlayerLayer *)playerLayer;

@end

@interface MUXSDKAVPlayerBinding : MUXSDKPlayerBinding {
@private
    CGSize _fixedPlayerSize;
}

- (nonnull id)initWithPlayerName:(nonnull NSString *)playerName
                    softwareName:(nullable NSString *)softwareName
                 fixedPlayerSize:(CGSize)fixedPlayerSize;

- (nonnull id)initWithPlayerName:(nonnull NSString *)playerName
                    softwareName:(nullable NSString *)softwareName
                 softwareVersion:(nullable NSString *)softwareVersion
                 fixedPlayerSize:(CGSize)fixedPlayerSize;

@end
