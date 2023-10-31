//
//  MUXSDKMonitor.h
//

#if __has_feature(modules)
@import Foundation;
#else
#import <Foundation/Foundation.h>
#endif

#import "MUXSDKPlayerBinding.h"

@class AVPlayer;
@class AVPlayerLayer;
@class AVPlayerViewController;

@class MUXSDKCustomerData;

@class MUXSDKPlayerBinding;

NS_ASSUME_NONNULL_BEGIN

/// MUXSDKMonitor monitors media playback performance and QoS
/// by sending beacons containing player events and metadata
/// to Mux servers.
///
/// In the simplest case MUXSDKMonitor observes an instance
/// of AVPlayerViewController or AVPlayerLayer that you
/// you provide. Timed state and key-value observers will
/// be setup for you.
///
/// A standalone AVPlayer can be monitored as well if a fixed
/// player size is provided.
///
/// When you are done with the AVPlayerViewController,
/// AVPlayerLayer, or AVPlayer instance call stopMonitoring
/// in order to remove the observers.
///
/// If you change the video that is playing, you should signal
/// MUXSDKMonitor to provide updated video information by calling
/// ``signalVideoChangeForPlayerName:withUpdatedCustomerData``.
/// Not calling ``signalVideoChangeForPlayerName:withUpdatedCustomerData``
/// will associate player events with the last video that
/// was playing.
@interface MUXSDKMonitor : NSObject

#pragma mark - Initialization

- (_Null_unspecified instancetype)init NS_UNAVAILABLE;
+ (_Null_unspecified instancetype)new NS_UNAVAILABLE;

/// Retrieves a shared monitor reference.
+ (nonnull instancetype)sharedMonitor;

#pragma mark - SDK Metadata

- (nonnull NSString *)pluginVersion;

#pragma mark - Start Monitoring AVPlayerViewController

/// Starts to monitor a given AVPlayerViewController instance.
/// The instance must be identified with a globally unique
/// player name.
///
/// - Parameters:
///   - playerViewController: An AVPlayerViewController to monitor
///   - playerName: globally unique name for this instance
///   of the player
///   - customerData: A MUXSDKCustomerData object with player,
/// video, and view metadata
/// - Returns: an instance of MUXSDKPlayerBinding or nil
- (nullable MUXSDKPlayerBinding *)startMonitoringPlayerViewController:(nonnull AVPlayerViewController *)playerViewController
                                                       withPlayerName:(nonnull NSString *)playerName
                                                         customerData:(nonnull MUXSDKCustomerData *)customerData;

/// Starts to monitor a given AVPlayerViewController instance.
/// The instance must be identified with a globally unique
/// player name.
///
/// - Parameters:
///   - playerViewController: An AVPlayerViewController to monitor
///   - playerName: A globally unique name for this instance
///   of the player
///   - customerData: A MUXSDKCustomerData object with player,
/// video, and view metadata
///   - automaticErrorTracking: boolean to indicate if the
/// SDK should automatically track player errors
/// - Returns: an instance of MUXSDKPlayerBinding or nil
- (nullable MUXSDKPlayerBinding *)startMonitoringPlayerViewController:(nonnull AVPlayerViewController *)playerViewController
                                                       withPlayerName:(nonnull NSString *)playerName
                                                         customerData:(nonnull MUXSDKCustomerData *)customerData
                                               automaticErrorTracking:(BOOL)automaticErrorTracking;

/// Starts to monitor a given AVPlayerViewController instance.
/// The instance must be identified with a globally unique
/// player name.
///
/// - Parameters:
///   - playerViewController: An AVPlayerViewController to monitor
///   - playerName: A globally unique name for this instance
///   of the player
///   - customerData: A MUXSDKCustomerData object with player,
/// video, and view metadata
///   - automaticErrorTracking: boolean to indicate if the
/// SDK should automatically track player errors
///   - beaconCollectionDomain: Domain to send tracking data
///   to, if you want to use a custom beacon domain. Optional.
/// - Returns: an instance of MUXSDKPlayerBinding or nil
- (nullable MUXSDKPlayerBinding *)startMonitoringPlayerViewController:(nonnull AVPlayerViewController *)playerViewController
                                                       withPlayerName:(nonnull NSString *)playerName
                                                         customerData:(nonnull MUXSDKCustomerData *)customerData
                                               automaticErrorTracking:(BOOL)automaticErrorTracking
                                               beaconCollectionDomain:(nullable NSString *)beaconCollectionDomain;

/// Updates the AVPlayerViewController instance being monitored
/// for the provided player name.
///
/// Monitoring must have already been started for the player name.
///
/// - Parameters:
///   - playerViewController: The new AVPlayerViewController to monitor
///   - playerName: The name of the player instance to update
- (void)updatePlayerViewController:(nonnull AVPlayerViewController *)playerViewController
                    withPlayerName:(nonnull NSString *)playerName;

#pragma mark - Start Monitoring AVPlayerLayer

/// Starts to monitor a given AVPlayerLayer instance.
/// The instance must be identified with a globally unique
/// player name.
///
/// - Parameters:
///   - playerLayer: An AVPlayerLayer to monitor
///   - playerName: A globally unique name for this instance
///   of the player
///   - customerData: A MUXSDKCustomerData object with player,
/// video, and view metadata
/// - Returns: an instance of MUXSDKPlayerBinding or nil
- (nullable MUXSDKPlayerBinding *)startMonitoringPlayerLayer:(nonnull AVPlayerLayer *)playerLayer
                                              withPlayerName:(nonnull NSString *)playerName
                                                customerData:(nonnull MUXSDKCustomerData *)customerData;

/// Starts to monitor a given AVPlayerLayer instance.
/// The instance must be identified with a globally unique
/// player name.
///
/// - Parameters:
///   - playerLayer: An AVPlayerLayer to monitor
///   - playerName: A globally unique name for this instance
///   of the player
///   - customerData: A MUXSDKCustomerData object with player,
/// video, and view metadata
///   - automaticErrorTracking: boolean to indicate if the
/// SDK should automatically track player errors
/// - Returns: an instance of MUXSDKPlayerBinding or nil
- (nullable MUXSDKPlayerBinding *)startMonitoringPlayerLayer:(nonnull AVPlayerLayer *)playerLayer
                                              withPlayerName:(nonnull NSString *)playerName
                                                customerData:(nonnull MUXSDKCustomerData *)customerData
                                      automaticErrorTracking:(BOOL)automaticErrorTracking;

/// Starts to monitor a given AVPlayerLayer instance.
/// The instance must be identified with a globally unique
/// player name.
///
/// - Parameters:
///   - playerLayer: An AVPlayerLayer to monitor
///   - playerName: A globally unique name for this instance
///   of the player
///   - customerData: A MUXSDKCustomerData object with player,
/// video, and view metadata
///   - automaticErrorTracking: boolean to indicate if the
/// SDK should automatically track player errors
///   - beaconCollectionDomain: Domain to send tracking data
///   to, if you want to use a custom beacon domain. Optional.
/// - Returns: an instance of MUXSDKPlayerBinding or nil
- (nullable MUXSDKPlayerBinding *)startMonitoringPlayerLayer:(nonnull AVPlayerLayer *)playerLayer
                                              withPlayerName:(nonnull NSString *)playerName
                                                customerData:(nonnull MUXSDKCustomerData *)customerData
                                      automaticErrorTracking:(BOOL)automaticErrorTracking
                                      beaconCollectionDomain:(nullable NSString *)beaconCollectionDomain;

/// Updates the AVPlayerLayer instance being monitored
/// for the provided player name.
///
/// Monitoring must have already been started for the player name.
///
/// - Parameters:
///   - playerLayer: The new AVPlayerLayer to monitor
///   - playerName: The name of the player instance to update
- (void)updatePlayerLayer:(nonnull AVPlayerLayer *)playerLayer
           withPlayerName:(nonnull NSString *)playerName;

#pragma mark - Start Monitoring AVPlayer

/// Starts to monitor a given AVPlayer instance.
/// The instance must be identified with a globally unique
/// player name.
///
/// - Parameters:
///   - player: An AVPlayer to monitor
///   - playerName: A globally unique name for this instance
///   of the player
///   - fixedPlayerSize: A fixed size of your player that will
///   not change, inclusive of any letter boxed or pillar
///   boxed areas. If monitoring audio only media, pass in
///   `CGSizeMake(0.0, 0.0)`
///   - customerData: A MUXSDKCustomerData object with player,
/// video, and view metadata
/// - Returns: an instance of MUXSDKPlayerBinding or nil
- (nullable MUXSDKPlayerBinding *)startMonitoringPlayer:(nonnull AVPlayer *)player
                                         withPlayerName:(nonnull NSString *)playerName
                                        fixedPlayerSize:(CGSize)fixedPlayerSize
                                           customerData:(nonnull MUXSDKCustomerData *)customerData;

/// Starts to monitor a given AVPlayer instance.
/// The instance must be identified with a globally unique
/// player name.
///
/// - Parameters:
///   - player: An AVPlayer to monitor
///   - playerName: A globally unique name for this instance
///   of the player
///   - fixedPlayerSize: A fixed size of your player that will
///   not change, inclusive of any letter boxed or pillar
///   boxed areas. If monitoring audio only media, pass in
///   `CGSizeMake(0.0, 0.0)`
///   - customerData: A MUXSDKCustomerData object with player,
/// video, and view metadata
///   - automaticErrorTracking: boolean to indicate if the
/// SDK should automatically track player errors
/// - Returns: an instance of MUXSDKPlayerBinding or nil
- (nullable MUXSDKPlayerBinding *)startMonitoringPlayer:(nonnull AVPlayer *)player
                                         withPlayerName:(nonnull NSString *)playerName
                                        fixedPlayerSize:(CGSize)fixedPlayerSize
                                           customerData:(nonnull MUXSDKCustomerData *)customerData
                                 automaticErrorTracking:(BOOL)automaticErrorTracking;

/// Starts to monitor a given AVPlayer instance.
/// The instance must be identified with a globally unique
/// player name.
///
/// - Parameters:
///   - player: An AVPlayer to monitor
///   - playerName: A globally unique name for this instance
///   of the player
///   - fixedPlayerSize: A fixed size of your player that will
///   not change, inclusive of any letter boxed or pillar
///   boxed areas. If monitoring audio only media, pass in
///   `CGSizeMake(0.0, 0.0)`
///   - customerData: A MUXSDKCustomerData object with player,
/// video, and view metadata
///   - automaticErrorTracking: boolean to indicate if the
/// SDK should automatically track player errors
///   - beaconCollectionDomain: Domain to send tracking data
///   to, if you want to use a custom beacon domain. Optional.
/// - Returns: an instance of MUXSDKPlayerBinding or nil
- (nullable MUXSDKPlayerBinding *)startMonitoringPlayer:(nonnull AVPlayer *)player
                                         withPlayerName:(nonnull NSString *)playerName
                                        fixedPlayerSize:(CGSize)fixedPlayerSize
                                           customerData:(nonnull MUXSDKCustomerData *)customerData
                                 automaticErrorTracking:(BOOL)automaticErrorTracking
                                 beaconCollectionDomain:(nullable NSString *)beaconCollectionDomain;

/// Updates the AVPlayer instance being monitored
/// for the provided player name.
///
/// Monitoring must have already been started for the 
/// player name.
///
/// - Parameters:
///   - player: The new AVPlayer to monitor
///   - playerName: The name of the player instance to update
///   - fixedPlayerSize: A fixed size of your player that will
///   not change, inclusive of any letter boxed or pillar
///   boxed areas. If monitoring audio only media, pass in
///   `CGSizeMake(0.0, 0.0)`
- (void)updatePlayer:(nonnull AVPlayer *)player
      withPlayerName:(nonnull NSString *)playerName
     fixedPlayerSize:(CGSize)fixedPlayerSize;

#pragma mark - Stop Monitoring

/// Removes any observers monitoring the instance with the
/// provided player name
///
/// - Parameter playerName: The player name to stop monitoring
- (void)stopMonitoringWithPlayerName:(nonnull NSString *)playerName;


/// Removes any observers monitoring the instance associated
/// with the provided player binding
///
/// - Parameter playerBinding: The player binding for the
/// instance to stop monitoring
- (void)stopMonitoringWithPlayerBinding:(nonnull MUXSDKPlayerBinding *)playerBinding;

#pragma mark - Automatic Video Change

// TODO: Consider whether to use a single method with BOOL parameter vs separate methods here. Should this also be exposed as a parameter for the startMonitoring methods?

/// Enables automatic video change detection, if automatic
/// video change detection is already enabled then this method
/// does nothing. Automatic video change detection is enabled
/// by default.
///
/// - Parameter playerName: The name of the player for which
/// automatic video change detection should be enabled.
- (void)enableAutomaticVideoChangeDetectionForPlayerName:(nonnull NSString *)playerName;

/// Disables automatic video change detection, if automatic
/// video change detection is already disabled then this method
/// does nothing. Automatic video change detection is enabled
/// by default.
///
/// - Parameter playerName: The name of the player for which
/// automatic video change detection should be disabled.
- (void)disableAutomaticVideoChangeDetectionForPlayerName:(nonnull NSString *)playerName;

#pragma mark - Manual Video Change

/// Signals that a player is now playing a different video.
///
/// Use this method to signal that the player is now playing
/// a new video. The player name must previously have been
/// passed in a `startMonitoring*` call. If the player name 
/// hasn't been previously passed, an exception will be raised.
///
/// - Parameters:
///   - playerName: The name of the player now playing a
///   different video.
///   - customerData: A MUXSDKCustomerData object with player,
///   video, and view metadata
- (void)signalVideoChangeForPlayerName:(nonnull NSString *)playerName
               withUpdatedCustomerData:(nullable MUXSDKCustomerData *)customerData;

#pragma mark - Program Change

/// Signals that a player is now playing a different video
/// of a playlist; or a different program of a live stream
///
/// Use this method to signal that the player is now playing
/// a different video of a playlist, or a different program
/// of a live stream. The player name must previously have been
/// passed in a `startMonitoring*` call. If the player name
/// hasn't been previously passed, an exception will be raised.
///
/// - Parameters:
///   - playerName: The name of the player now playing a 
///   different video of a playlist; or a different program
///   of a live stream
///   - customerData: A MUXSDKCustomerData object with player,
///   video, and view metadata
- (void)signalProgramChangeForPlayerName:(nonnull NSString *)playerName
                 withUpdatedCustomerData:(nullable MUXSDKCustomerData *)customerData;

#pragma mark - Customer Data

/// Allows customerData to be set or updated for a player
/// instance
///
/// - Parameters:
///   - playerName: The name of the player for which to update
///   the customer data
///   - customerData: A MUXSDKCustomerData object with player,
///   video, and view metadata
- (void)updatePlayerName:(nonnull NSString *)playerName
        withCustomerData:(nullable MUXSDKCustomerData *)customerData;

#pragma mark - Orientation Change

// TODO: Move MUXSDKViewOrientation to its own header

// TODO: We should probably allow a starting orientation to be set when calling startMonitoring on an AVPlayer

/// Signals that the player's visual orientation has changed.
///
/// - Parameters:
///   - playerName: The name of the player for which the
///   orientation has changed
///   - orientation: A ``MUXSDKViewOrientation`` enum representing
///   the new orientation of the player's view
- (void)signalOrientationChangeForPlayerName:(nonnull NSString *)playerName
                          updatedOrientation:(MUXSDKViewOrientation)orientation;

#pragma mark - Error Dispatch

/// Dispatches an error with the specified error code and
/// message for the player with the given name
///
/// - Parameters:
///   - playerName: The name of the player
///   - errorCode: The error code in string format
///   - errorMessage: The error message in string format
- (void)dispatchErrorForPlayerName:(nonnull NSString *)playerName
                         errorCode:(nonnull NSString *)errorCode
                      errorMessage:(nonnull NSString *)errorMessage;

@end

NS_ASSUME_NONNULL_END
