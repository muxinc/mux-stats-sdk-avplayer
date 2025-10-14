#import <Foundation/Foundation.h>
#import <AVKit/AVKit.h>
#import <AVFoundation/AVFoundation.h>
#import <MuxCore/MuxCore.h>

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

@interface MUXSDKPlayerBinding : NSObject

@property (nonatomic, weak) id<MUXSDKPlayDispatchDelegate>  playDispatchDelegate;

- (id)initWithName:(NSString *)name 
       andSoftware:(NSString *)software;

- (void)attachAVPlayer:(AVPlayer *)player;
- (void)detachAVPlayer;
- (void)programChangedForPlayer;
- (void)prepareForAvQueuePlayerNextItem;
- (CGRect)getViewBounds DEPRECATED_ATTRIBUTE;
- (nullable NSValue *)getViewBoundsValue;
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
- (void)dispatchPlaybackModeChange:(nonnull MUXSDKPlaybackMode) mode
                          withData:(nullable NSData *)data;
- (float)getCurrentPlayheadTimeMs;
- (void)dispatchRenditionChange;
- (void)setAdPlaying:(BOOL)isAdPlaying;
- (BOOL)setAutomaticErrorTracking:(BOOL)automaticErrorTracking;
- (BOOL)setAutomaticVideoChange:(BOOL)automaticVideoChange;
- (void)didTriggerManualVideoChange;

#pragma clang diagnostic pop


/// Records an error related to the player attached to this binding
/// and dispatches it to Mux
/// - Parameters:
///   - code: error code that should be numeric
///   - message: message describing the error
- (void)dispatchError:(nonnull NSString *)code
          withMessage:(nonnull NSString *)message;

/// Records an error related to the player attached to this binding
/// and dispatches it to Mux
/// - Parameters:
///   - code: error code that should be numeric
///   - message: message describing the error
///   - errorContext: additional details for the error such
///   as a stack trace
- (void)dispatchError:(nonnull NSString *)code
          withMessage:(nonnull NSString *)message
     withErrorContext:(nonnull NSString *)errorContext;

/// Records an error related to the player attached to this binding
/// and dispatches it to Mux
/// - Parameters:
///   - code: error code that should be numeric
///   - message: message describing the error
///   - severity: severity of a player error recorded by the SDK
- (void)dispatchError:(nonnull NSString *)code
          withMessage:(nonnull NSString *)message
             severity:(MUXSDKErrorSeverity)severity;

/// Records an error related to the player attached to this binding
/// and dispatches it to Mux
/// - Parameters:
///   - code: error code that should be numeric
///   - message: message describing the error
///   - severity: severity of a player error recorded by the SDK
///   - errorContext: additional details for the error such
///   as a stack trace
- (void)dispatchError:(nonnull NSString *)code
          withMessage:(nonnull NSString *)message
             severity:(MUXSDKErrorSeverity)severity
         errorContext:(nonnull NSString *)errorContext;

/// Records an error related to the player attached to this binding
/// and dispatches it to Mux
/// - Parameters:
///   - code: error code that should be numeric
///   - message: message describing the error
///   - severity: severity of a player error recorded by the SDK
///   - isBusinessException: If ``YES`` indicates that the error
///   is classified to be a business exception. If ``NO``
///   indicates that the error is classified as a technical
///   failure. Defaults to ``NO`.
- (void)dispatchError:(nonnull NSString *)code
          withMessage:(nonnull NSString *)message
             severity:(MUXSDKErrorSeverity)severity
  isBusinessException:(BOOL)isBusinessException;

/// Records an error related to the player attached to this binding
/// and dispatches it to Mux
/// - Parameters:
///   - code: error code that should be numeric
///   - message: message describing the error
///   - severity: severity of a player error recorded by the SDK
///   - isBusinessException: If ``YES`` indicates that the error
///   is classified to be a business exception. If ``NO``
///   indicates that the error is classified as a technical
///   failure. Defaults to ``NO`.
///   - errorContext: additional details for the error such
///     as a stack trace
- (void)dispatchError:(nonnull NSString *)code
          withMessage:(nonnull NSString *)message
             severity:(MUXSDKErrorSeverity)severity
  isBusinessException:(BOOL)isBusinessException
         errorContext:(nonnull NSString *)errorContext;

- (nonnull id)initWithPlayerName:(nonnull NSString *)playerName
                    softwareName:(nullable NSString *)softwareName;

- (nonnull id)initWithPlayerName:(nonnull NSString *)playerName
                    softwareName:(nullable NSString *)softwareName
                 softwareVersion:(nullable NSString *)softwareVersion;

@end

@interface MUXSDKAVPlayerViewControllerBinding : MUXSDKPlayerBinding

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

API_UNAVAILABLE(visionos) 
@interface MUXSDKAVPlayerLayerBinding : MUXSDKPlayerBinding

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

@interface MUXSDKFixedPlayerSizeBinding : MUXSDKPlayerBinding


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

// Support a previous naming of this class
DEPRECATED_MSG_ATTRIBUTE("Please migrate to MUXSDKFixedPlayerSizeBinding")
@interface MUXSDKAVPlayerBinding: MUXSDKFixedPlayerSizeBinding
@end
