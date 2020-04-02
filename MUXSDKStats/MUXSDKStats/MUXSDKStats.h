/*
    File:  MUXSDKStats.h

	Framework:  MUXSDKStats

	Copyright © 2016 Mux, Inc. All rights reserved.
 */

/*!
	@class			MUXSDKStats

	@abstract
 MUXSDKStats offers an interface for monitoring video players.

	@discussion
 MUXSDKStats monitors an AVPlayer performance by sending tracking pings to Mux servers.

 In the simplest use case, an AVPlayer can be provided to the MUXSDKStats API and everything else is taken care of for you. The MUXSDKStats monitor methods attach a set of timed state and key-value observers on the AVPlayer. When you are done with an AVPlayer instance, call destroyPlayer: to remove the observers.

 If you change the video that is playing in an AVPlayer, you should call videoChangeForPlayer:withVideoData to provide the updated video information. Not calling videoChangeForPlayer:withVideoData when the video changes will cause tracking pings to be associated with the last video that was playing.
 */

#import <Foundation/Foundation.h>

@import AVKit;
@import AVFoundation;
#if TARGET_OS_IOS
@import MuxCore;
#else
@import MuxCoreTv;
#endif
#import "MUXSDKPlayerBinding.h"

FOUNDATION_EXPORT
@interface MUXSDKStats : NSObject

- (_Null_unspecified instancetype)init NS_UNAVAILABLE;
+ (_Null_unspecified instancetype)new NS_UNAVAILABLE;

/*!
 @method      monitorAVPlayerViewController:withPlayerName:playerData:videoData:
 @abstract    Starts to monitor a given AVPlayerViewController.
 @param       player An AVPlayerViewController to monitor
 @param       name A name for this instance of the player
 @param       playerData A MUXSDKCustomerPlayerData object with player metadata
 @param       videoData A MUXSDKCustomerVideoData object with video metadata
 @return      an instance of MUXSDKAVPlayerLayerBinding or null
 @discussion  Use this method to start a Mux player monitor on the given AVPlayerViewController. The player must have a name which is globally unique. The config provided should match the specifications in the Mux docs at https://docs.mux.com
 */
+ (MUXSDKPlayerBinding *_Nullable)monitorAVPlayerViewController:(nonnull AVPlayerViewController *)player withPlayerName:(nonnull NSString *)name playerData:(nonnull MUXSDKCustomerPlayerData *)playerData videoData:(nullable MUXSDKCustomerVideoData *)videoData;

/*!
 @method      updateAVPlayerViewController:withPlayerName
 @abstract    Updates the monitor for a player to a new AVPlayerViewController.
 @param       player The new AVPlayerViewController to monitor
 @param       name The name of the player instance to update
 @discussion  Use this method to modify the AVPlayerViewController a Mux player monitor is watching. The player monitor must previously have been created via a monitorAVPlayerViewController call.
 */
+ (void)updateAVPlayerViewController:(nonnull AVPlayerViewController *)player withPlayerName:(nonnull NSString *)name;

/*!
 @method      monitorAVPlayerLayer:withPlayerName:playerData:videoData:
 @abstract    Starts to monitor a given AVPlayerLayer.
 @param       player An AVPlayerLayer to monitor
 @param       name A name for this instance of the player
 @param       playerData A MUXSDKCustomerPlayerData object with player metadata
 @param       videoData A MUXSDKCustomerVideoData object with video metadata
 @return      an instance of MUXSDKAVPlayerLayerBinding or null
 @discussion  Use this method to start a Mux player monitor on the given AVPlayerLayer. The player must have a name which is globally unique. The config provided should match the specifications in the Mux docs at https://docs.mux.com
 */
+ (MUXSDKPlayerBinding *_Nullable)monitorAVPlayerLayer:(nonnull AVPlayerLayer *)player withPlayerName:(nonnull NSString *)name playerData:(nonnull MUXSDKCustomerPlayerData *)playerData videoData:(nullable MUXSDKCustomerVideoData *)videoData;

/*!
 @method      updateAVPlayerLayer:withPlayerName:
 @abstract    Updates the monitor for a player to a new AVPlayerLayer.
 @param       player The new AVPlayerLayer to monitor
 @param       name The name of the player instance to update
 @discussion  Use this method to modify the AVPlayerLayer a Mux player monitor is watching. The player monitor must previously have been created via a monitorAVPlayerViewController call.
 */
+ (void)updateAVPlayerLayer:(nonnull AVPlayerLayer *)player withPlayerName:(nonnull NSString *)name;

/*!
 @method			destroyPlayer:
 @abstract    Removes any AVPlayer observers on the associated player.
 @param       name The name of the player to destory
 @discussion  When you are done with a player, call destoryPlayer: to remove all observers that were set up when monitorPlayer:withPlayerName:andConfig: was called and to ensure that any remaining tracking pings are sent to complete the view. If the name of the player provided was not previously initialized, an exception will be raised.
 */
+ (void)destroyPlayer:(nonnull NSString *)name;

/*!
 @method      videoChangeForPlayer:withVideoData:
 @abstract    Signals that a player is now playing a different video.
 @param       name The name of the player to update
 @param       videoData A MUXSDKCustomerVideoData object with video metadata
 @discussion  Use this method to signal that the player is now playing a new video. The player name provided must been passed as the name in a monitorPlayer:withPlayerName:andConfig: call. The config provided should match the specifications in the Mux docs at https://docs.mux.com and should include all desired keys, not just those keys that are specific to this video. If the name of the player provided was not previously initialized, an exception will be raised.

 */
+ (void)videoChangeForPlayer:(nonnull NSString *)name withVideoData:(nullable MUXSDKCustomerVideoData *)videoData;

/*!
 @method      videoChangeForPlayer:withPlayerData:withVideoData
 @abstract    Signals that a player is now playing a different video.
 @param       name The name of the player to update
 @param       playerData A MUXSDKCustomerPlayerData object with video metadata
 @param       videoData A MUXSDKCustomerVideoData object with video metadata
 @discussion  Use this method to signal that the player is now playing a new video. The player name provided must been passed as the name in a monitorPlayer:withPlayerName:andConfig: call. The config provided should match the specifications in the Mux docs at https://docs.mux.com and should include all desired keys, not just those keys that are specific to this video. If the name of the player provided was not previously initialized, an exception will be raised.

 */
+ (void)videoChangeForPlayer:(nonnull NSString *)name  withPlayerData:(nullable MUXSDKCustomerPlayerData *)playerData withVideoData:(nullable MUXSDKCustomerVideoData *)videoData;

/*!
 @method      programChangeForPlayer:withVideoData:
 @abstract    Signals that a player is now playing a different video of a playlist; or a different program of a live stream
 @param       name The name of the player to update
 @param       videoData A MUXSDKCustomerVideoData object with video metadata
 @discussion  Use this method to signal that the player is now playing a differnt video of a playlist, or a different program of a live stream. The player name provided must been passed as the name in a monitorPlayer:withPlayerName:andConfig: call. The config provided should match the specifications in the Mux docs at https://docs.mux.com and should include all desired keys, not just those keys that are specific to this video. If the name of the player provided was not previously initialized, an exception will be raised.
 */
+ (void)programChangeForPlayer:(nonnull NSString *)name withVideoData:(nullable MUXSDKCustomerVideoData *)videoData;

/*!
 @method      updateCustomerData:forPlayer:withPlayerData:withVideoData
 @abstract    allows videoData to be set or updated for the player
 @param       name The name of the player to update
 @param       playerData A MUXSDKCustomerPlayerData object with video metadata
 @param       videoData A MUXSDKCustomerVideoData object with video metadata
 @discussion  Use this method after you have already initialized the Mux SDK at any time before the player has been destroyed. Pass in either videoData or playerData.
 */
+ (void)updateCustomerDataForPlayer:(nonnull NSString *)name withPlayerData:(nullable MUXSDKCustomerPlayerData *)playerData withVideoData:(nullable MUXSDKCustomerVideoData *)videoData;


/*!
@method      orientationChangeForPlayer:withOrientation:
@abstract    Notifies the Mux SDK that the view's orientation has changed.
@param       name The name of the player to update
@param       orientation A MUXSDKViewOrientation enum value representing if the view has changed to portrait or landscape
*/
+ (void) orientationChangeForPlayer:(nonnull NSString *) name  withOrientation:(MUXSDKViewOrientation) orientation;

@end
