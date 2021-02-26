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
#import <MuxCore/MuxCore.h>
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

@protocol MUXSDKPlayDispatchDelegate
- (void) playbackStartedForPlayer:(NSString *) name;
- (void) videoChangedForPlayer:(NSString *) name;
@end

@interface MUXSDKPlayerBinding : NSObject {
@private
    NSString *_name;
    NSString *_software;
    AVPlayer *_player;
    AVPlayerItem *_playerItem;
    id _timeObserver;
    MUXSDKPlayerState _state;
    CGSize _videoSize;
    CMTime _videoDuration;
    BOOL _videoIsLive;
    NSString *_videoURL;
    CFAbsoluteTime _lastTimeUpdate;
    NSTimer *_timeUpdateTimer;
    CFAbsoluteTime _lastPlayheadTimeUpdated;
    float _lastPlayheadTimeMs;
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
}

@property (nonatomic, weak) id<MUXSDKPlayDispatchDelegate>  playDispatchDelegate;

- (id)initWithName:(NSString *)name andSoftware:(NSString *)software;
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
- (BOOL)setAutomaticErrorTracking:(BOOL)automaticErrorTracking;
- (void)dispatchError:(NSString *)code withMessage:(NSString *)message;

@end


@interface MUXSDKAVPlayerViewControllerBinding : MUXSDKPlayerBinding {
@private
    AVPlayerViewController *_viewController;
}

- (id)initWithName:(NSString *)name software:(NSString *)software andView:(AVPlayerViewController *)view;

@end


@interface MUXSDKAVPlayerLayerBinding : MUXSDKPlayerBinding {
@private
    AVPlayerLayer *_view;
}

- (id)initWithName:(NSString *)name software:(NSString *)software andView:(AVPlayerLayer *)view;

@end
