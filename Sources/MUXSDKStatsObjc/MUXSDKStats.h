//
//  MUSDKStats.h
//  MUXSDKStats

#if __has_feature(modules)
@import Foundation;
@import AVKit;
@import AVFoundation;
@import MuxCore;
@import SystemConfiguration;
#else
#import <Foundation/Foundation.h>
#import <AVKit/AVKit.h>
#import <AVFoundation/AVFoundation.h>
#import <SystemConfiguration/SystemConfiguration.h>
#endif

#import "MUXSDKViewOrientation.h"

@class MUXSDKCustomerData;

@class MUXSDKPlayerBinding;

/// MUXSDKStats monitors an AVPlayer performance by sending
/// tracking pings to Mux servers. 
///
/// In the simplest use case,
/// an AVPlayer can be provided to the MUXSDKStats API and
/// everything else is taken care of for you. The MUXSDKStats
/// monitor methods attach a set of timed state and key-value
/// observers on the AVPlayer. When you are done with an
/// AVPlayer instance, call destroyPlayer: to remove the
/// observers.
///
/// If you change the video that is playing in an AVPlayer,
/// you should call videoChangeForPlayer:withVideoData to
/// provide the updated video information. Not calling
/// videoChangeForPlayer:withVideoData when the video changes
/// will cause tracking pings to be associated with the last
/// video that was playing.
@interface MUXSDKStats : NSObject

- (_Null_unspecified instancetype)init NS_UNAVAILABLE;
+ (_Null_unspecified instancetype)new NS_UNAVAILABLE;

#pragma mark - AVPlayerViewController Monitoring

/// Starts to monitor a given AVPlayerViewController.
///
/// Use this method to start a Mux player monitor on the
/// given AVPlayerViewController. The player must have a 
/// globally unique name.
///
/// - Parameters:
///   - player: An AVPlayerViewController to monitor
///   - name: A name for this instance of the player
///   - customerData: A MUXSDKCustomerData object with player,
/// video, and view metadata
/// - Returns: an instance of MUXSDKAVPlayerViewControllerBinding
/// or nil
+ (nullable MUXSDKPlayerBinding *)monitorAVPlayerViewController:(nonnull AVPlayerViewController *)player
                                                 withPlayerName:(nonnull NSString *)name
                                                   customerData:(nonnull MUXSDKCustomerData *)customerData;

/// Starts to monitor a given AVPlayerViewController.
///
/// Use this method to start a Mux player monitor on the
/// given AVPlayerViewController. The player must have a name
/// which is globally unique. The config provided should match
/// the specifications in the Mux docs at https://docs.mux.com
/// - Parameters:
///   - player: An AVPlayerViewController to monitor
///   - name: A name for this instance of the player
///   - customerData: A MUXSDKCustomerData object with player,
/// video, and view metadata
///   - automaticErrorTracking: boolean to indicate if the
/// SDK should automatically track player errors
/// - Returns: an instance of MUXSDKAVPlayerViewControllerBinding
/// or nil
+ (nullable MUXSDKPlayerBinding *)monitorAVPlayerViewController:(nonnull AVPlayerViewController *)player
                                                 withPlayerName:(nonnull NSString *)name
                                                   customerData:(nonnull MUXSDKCustomerData *)customerData
                                         automaticErrorTracking:(BOOL)automaticErrorTracking;

/// Starts to monitor a given AVPlayerViewController.
///
/// Use this method to start a Mux player monitor on the
/// given AVPlayerViewController. The player must have a
/// name which is globally unique. The config provided
/// should match the specifications in the Mux docs at
/// https://docs.mux.com
///
/// - Parameters:
///   - player: An AVPlayerViewController to monitor
///   - name: A name for this instance of the player
///   - customerData: A MUXSDKCustomerData object with player,
/// video, and view metadata
///   - automaticErrorTracking: boolean to indicate if the
/// SDK should automatically track player errors
///   - collectionDomain: Domain to send tracking data to,
/// if you want to use a custom beacon domain. Optional.
/// - Returns: an instance of MUXSDKAVPlayerViewControllerBinding
/// or nil
+ (nullable MUXSDKPlayerBinding *)monitorAVPlayerViewController:(nonnull AVPlayerViewController *)player
                                                 withPlayerName:(nonnull NSString *)name
                                                   customerData:(nonnull MUXSDKCustomerData *)customerData
                                         automaticErrorTracking:(BOOL)automaticErrorTracking
                                         beaconCollectionDomain:(nullable NSString *)collectionDomain;

/// Updates the monitor for a player to a new AVPlayerViewController.
///
/// Use this method to change which AVPlayerViewController a
/// Mux player monitor is watching. The player monitor must
/// previously have been created via a monitorAVPlayerViewController
/// call.
/// - Parameters:
///   - player: The new AVPlayerViewController to monitor
///   - name: The name of the player instance to update
+ (void)updateAVPlayerViewController:(nonnull AVPlayerViewController *)player
                      withPlayerName:(nonnull NSString *)name;

#pragma mark - AVPlayerLayer Monitoring

/// Starts to monitor a given AVPlayerLayer.
///
/// Use this method to start a Mux player monitor on the
/// given AVPlayerLayer. The player must have a name which
/// is globally unique. The config provided should match the
/// specifications in the Mux docs at https://docs.mux.com
/// - Parameters:
///   - player: An AVPlayerLayer to monitor
///   - name: A name for this instance of the player
///   - customerData: A MUXSDKCustomerData object with player,
/// video, and view metadata
/// - Returns: an instance of MUXSDKAVPlayerLayerBinding or
/// nil
+ (nullable MUXSDKPlayerBinding *)monitorAVPlayerLayer:(nonnull AVPlayerLayer *)player
                                        withPlayerName:(nonnull NSString *)name
                                          customerData:(nonnull MUXSDKCustomerData *)customerData;

/// Starts to monitor a given AVPlayerLayer.
///
/// Use this method to start a Mux player monitor on the
/// given AVPlayerLayer. The player must have a name which
/// is globally unique. The config provided should match the
/// specifications in the Mux docs at https://docs.mux.com
/// - Parameters:
///   - player: An AVPlayerLayer to monitor
///   - name: A name for this instance of the player
///   - customerData: A MUXSDKCustomerData object with player,
/// video, and view metadata
///   - automaticErrorTracking: boolean to indicate if the
/// SDK should automatically track player errors
/// - Returns: an instance of MUXSDKAVPlayerLayerBinding or
/// nil
+ (nullable MUXSDKPlayerBinding *)monitorAVPlayerLayer:(nonnull AVPlayerLayer *)player
                                        withPlayerName:(nonnull NSString *)name
                                          customerData:(nonnull MUXSDKCustomerData *)customerData
                                automaticErrorTracking:(BOOL)automaticErrorTracking;

/// Starts to monitor a given AVPlayerLayer.
///
/// Use this method to start a Mux player monitor on the
/// given AVPlayerLayer. The player must have a name which
/// is globally unique. The config provided should match the
/// specifications in the Mux docs at https://docs.mux.com
/// - Parameters:
///   - player: An AVPlayerLayer to monitor
///   - name: A name for this instance of the player
///   - customerData: A MUXSDKCustomerData object with player,
/// video, and view metadata
///   - automaticErrorTracking: boolean to indicate if the
/// SDK should automatically track player errors
///   - collectionDomain: Domain to send tracking data to,
/// if you want to use a custom beacon domain. Optional.
/// - Returns: an instance of MUXSDKAVPlayerLayerBinding or
/// nil
+ (nullable MUXSDKPlayerBinding *)monitorAVPlayerLayer:(nonnull AVPlayerLayer *)player
                                        withPlayerName:(nonnull NSString *)name
                                          customerData:(nonnull MUXSDKCustomerData *)customerData
                                automaticErrorTracking:(BOOL)automaticErrorTracking
                                beaconCollectionDomain:(nullable NSString *)collectionDomain;

/// Updates the monitor for a player to a new AVPlayerLayer.
///
/// Use this method to change which AVPlayerLayer a Mux
/// player monitor is watching. The player monitor must
/// previously have been created via a monitorAVPlayerLayer
/// call.
/// - Parameters:
///   - player: The new AVPlayerLayer to monitor
///   - name: The name of the player instance to update
+ (void)updateAVPlayerLayer:(nonnull AVPlayerLayer *)player
             withPlayerName:(nonnull NSString *)name;

#pragma mark - AVPlayer Monitoring

/// Starts to monitor a given AVPlayer.
///
/// Use this method to start a Mux player monitor on the given
/// AVPlayer. The player must have a name which is globally
/// unique. The config provided should match the specifications
/// in the Mux docs at https://docs.mux.com
/// - Parameters:
///   - player: An AVPlayer to monitor
///   - name: A name for this instance of the player
///   - fixedPlayerSize: A fixed size of your player that will
///   not change, inclusive of any letter boxed or pillar
///   boxed areas. If monitoring audio only media, pass in
///   CGSizeMake(0.0, 0.0)
///   - customerData: A MUXSDKCustomerData object with player,
/// video, and view metadata
/// - Returns: an instance of MUXSDKPlayerBinding or nil
+ (nullable MUXSDKPlayerBinding *)monitorAVPlayer:(nonnull AVPlayer *)player
                                   withPlayerName:(nonnull NSString *)name
                                  fixedPlayerSize:(CGSize)fixedPlayerSize
                                     customerData:(nonnull MUXSDKCustomerData *)customerData;

/// Starts to monitor a given AVPlayer.
///
/// Use this method to start a Mux player monitor on the given
/// AVPlayer. The player must have a name which is globally
/// unique. The config provided should match the specifications
/// in the Mux docs at https://docs.mux.com
/// - Parameters:
///   - player: An AVPlayer to monitor
///   - name: A name for this instance of the player
///   - fixedPlayerSize: A fixed size of your player that will
///   not change, inclusive of any letter boxed or pillar
///   boxed areas. If monitoring audio only media, pass in
///   CGSizeMake(0.0, 0.0)
///   - customerData: A MUXSDKCustomerData object with player,
/// video, and view metadata
///   - automaticErrorTracking: boolean to indicate if the
///   SDK should automatically track player errors
/// - Returns: an instance of MUXSDKPlayerBinding or nil
+ (nullable MUXSDKPlayerBinding *)monitorAVPlayer:(nonnull AVPlayer *)player
                                   withPlayerName:(nonnull NSString *)name
                                  fixedPlayerSize:(CGSize)fixedPlayerSize
                                     customerData:(nonnull MUXSDKCustomerData *)customerData
                           automaticErrorTracking:(BOOL)automaticErrorTracking;

/// Starts to monitor a given AVPlayer.
///
/// Use this method to start a Mux player monitor on the given
/// AVPlayer. The player must have a name which is globally
/// unique. The config provided should match the specifications
/// in the Mux docs at https://docs.mux.com
/// - Parameters:
///   - player: An AVPlayer to monitor
///   - name: A name for this instance of the player
///   - fixedPlayerSize: A fixed size of your player that will
///   not change, inclusive of any letter boxed or pillar
///   boxed areas. If monitoring audio only media, pass in
///   CGSizeMake(0.0, 0.0)
///   - customerData: A MUXSDKCustomerData object with player,
/// video, and view metadata
///   - automaticErrorTracking: boolean to indicate if the
///   SDK should automatically track player errors
///   - collectionDomain: Domain to send tracking data to,
///   if you want to use a custom beacon domain. Optional.
/// - Returns: an instance of MUXSDKPlayerBinding or nil
+ (nullable MUXSDKPlayerBinding *)monitorAVPlayer:(nonnull AVPlayer *)player
                                   withPlayerName:(nonnull NSString *)name
                                  fixedPlayerSize:(CGSize)fixedPlayerSize
                                     customerData:(nonnull MUXSDKCustomerData *)customerData
                           automaticErrorTracking:(BOOL)automaticErrorTracking
                           beaconCollectionDomain:(nullable NSString *)collectionDomain;

/// Updates the monitor for a player to a new AVPlayer.
///
/// Use this method to change which AVPlayer a Mux player
/// monitor is watching. The player monitor must previously
/// have been created via a monitorAVPlayer call.
/// - Parameters:
///   - player: The new AVPlayer to monitor
///   - name: The name of the player instance to update
///   - fixedPlayerSize: A fixed size of your player that will
///   not change, inclusive of any letter boxed or pillar
///   boxed areas. If monitoring audio only media, pass in
///   CGSizeMake(0.0, 0.0)
+ (void)updateAVPlayer:(nonnull AVPlayer *)player
        withPlayerName:(nonnull NSString *)name
       fixedPlayerSize:(CGSize)fixedPlayerSize;

#pragma mark - Teardown Monitoring

/// Removes any AVPlayer observers on the associated player.
///
/// When you are done with a player, call destoryPlayer:
/// to remove all observers that were set up when
/// monitorPlayer:withPlayerName:andConfig: was called and
/// to ensure that any remaining tracking pings are sent to
/// complete the view. If the name of the player provided was
/// not previously initialized, an exception will be raised.
/// - Parameters:
///   - name: The name of the player to destroy
+ (void)destroyPlayer:(nonnull NSString *)name;

#pragma mark - Automatic Video Change

/// Allows default videochange functionality to be disabled.
///
/// Use this method to disable built in videochange calls
/// when using AVQueuePlayer. The player name provided must
/// been passed as the name in a monitorPlayer:withPlayerName:andConfig:
/// call. The config provided should match the specifications
/// in the Mux docs at https://docs.mux.com and should set
/// the enabled value to false. The default setting is true.
/// - Parameters:
///   - name: The name of the player to update
///   - enabled: Boolean indicating if automatic video change
///   is enabled or not
+ (void)setAutomaticVideoChange:(nonnull NSString *)name
                        enabled:(Boolean)enabled;

#pragma mark - Manual Video Change

/// Signals that a player is now playing a different video.
///
/// Use this method to signal that the player is now playing
/// a new video. The player name provided must been passed
/// as the name in a `monitor*` call. If the player name
/// hasn't been previously passed, an exception will be raised.
///
/// The customer data provided should include all applicable
/// fields and not just those that are specific to the video.
///
/// - Parameters:
///   - name: The name of the player to update
///   - customerData: A MUXSDKCustomerData object with player,
///   video, and view metadata
+ (void)videoChangeForPlayer:(nonnull NSString *)name
            withCustomerData:(nullable MUXSDKCustomerData *)customerData;

#pragma mark - Program Change

/// Signals that a player is now playing a different video
/// of a playlist; or a different program of a live stream
///
/// Use this method to signal that the player is now playing
/// a different video of a playlist, or a different program
/// of a live stream. The player name must previously have been
/// passed in a `monitor*` call call. If the player name
/// hasn't been previously passed, an exception will be raised.
///
/// The customer data provided should include all applicable
/// fields and not just those that are specific to the video.
///
/// - Parameters:
///   - name: The name of the player to update
///   - customerData: A MUXSDKCustomerData object with player,
///   video, and view metadata
+ (void)programChangeForPlayer:(nonnull NSString *)name
              withCustomerData:(nullable MUXSDKCustomerData *)customerData;

#pragma mark - Custom Data

/// Allows customerData to be set or updated for the player
///
/// Use this method after you have already initialized the
/// Mux SDK at any time before the player has been destroyed.
/// - Parameters:
///   - customerData: A MUXSDKCustomerData object with player,
///   video, and view metadata
///   - name: The name of the player to update
+ (void)setCustomerData:(nullable MUXSDKCustomerData *)customerData
              forPlayer:(nonnull NSString *)name;

#pragma mark - Orientation Change

/// Notifies the Mux SDK that the view's orientation has changed.
/// - Parameters:
///   - name: The name of the player to update
///   - orientation: A MUXSDKViewOrientation enum value
///   representing if the view has changed to portrait or
///   landscape
+ (void)orientationChangeForPlayer:(nonnull NSString *)name
                   withOrientation:(MUXSDKViewOrientation)orientation;

#pragma mark - Error Dispatch

/// Dispatches an error with the specified error code and
/// message for the given player
/// - Parameters:
///   - code: The error code in string format
///   - message: The error message in string format
///   - name: The name of the player
+ (void)dispatchError:(nonnull NSString *)code
          withMessage:(nonnull NSString *)message
            forPlayer:(nonnull NSString *)name;

@end
