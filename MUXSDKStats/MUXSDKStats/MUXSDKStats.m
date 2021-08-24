#import "MUXSDKStats.h"
#import "MUXSDKPlayerBinding.h"
#import "MUXSDKPlayerBindingManager.h"
#import "MUXSDKCustomerPlayerDataStore.h"
#import "MUXSDKCustomerVideoDataStore.h"
#import "MUXSDKCustomerViewDataStore.h"
#import "MUXSDKCustomerCustomDataStore.h"
#import <sys/utsname.h>

#if __has_feature(modules)
@import AVFoundation;
@import AVKit;
@import Foundation;
#else
#import <AVKit/AVKit.h>
#import <AVFoundation/AVFoundation.h>
#import <Foundation/Foundation.h>
#endif

// Software constants.
NSString *const MuxPlayerSoftwareAVPlayerViewController = @"AVPlayerViewController";
NSString *const MuxPlayerSoftwareAVPlayerLayer = @"AVPlayerLayer";
NSString *const MuxDeviceIDUserDefaultsKey = @"MUX_DEVICE_ID";


@implementation MUXSDKStats

static MUXSDKDispatcher *_dispatcher;
// Name => MuxPlayerSoftware value.
static NSMutableDictionary *_bindings;
// Name => AVPlayerViewController or AVPlayerLayer
static NSMutableDictionary *_viewControllers;

static MUXSDKPlayerBindingManager *_playerBindingManager;
static MUXSDKCustomerPlayerDataStore *_customerPlayerDataStore;
static MUXSDKCustomerVideoDataStore *_customerVideoDataStore;
static MUXSDKCustomerViewDataStore *_customerViewDataStore;
static MUXSDKCustomerCustomDataStore *_customerCustomDataStore;

+ (void)initSDK {
    if (!_bindings) {
        _bindings = [[NSMutableDictionary alloc] init];
    }
    if (!_viewControllers) {
        _viewControllers = [[NSMutableDictionary alloc] init];
    }
    if (!_customerPlayerDataStore) {
        _customerPlayerDataStore = [[MUXSDKCustomerPlayerDataStore alloc] init];
    }
    if (!_customerVideoDataStore) {
        _customerVideoDataStore = [[MUXSDKCustomerVideoDataStore alloc] init];
    }
    if (!_customerViewDataStore) {
        _customerViewDataStore = [[MUXSDKCustomerViewDataStore alloc] init];
    }
    if (!_customerCustomDataStore) {
        _customerCustomDataStore = [[MUXSDKCustomerCustomDataStore alloc] init];
    }
    if (!_playerBindingManager) {
        _playerBindingManager = [[MUXSDKPlayerBindingManager alloc] init];
        _playerBindingManager.customerPlayerDataStore = _customerPlayerDataStore;
        _playerBindingManager.customerVideoDataStore = _customerVideoDataStore;
        _playerBindingManager.customerViewDataStore = _customerViewDataStore;
        _playerBindingManager.customerCustomDataStore = _customerCustomDataStore;
        _playerBindingManager.viewControllers = _viewControllers;
    }

    // Provide EnvironmentData and ViewerData to Core.
    MUXSDKEnvironmentData *environmentData = [[MUXSDKEnvironmentData alloc] init];
    [environmentData setMuxViewerId:[self getUUIDString]];
    /*
    NSString *debugData = [MUXSDKConfigParser getNSStringForKey:@"debug" fromDictionary:config];
    if (debugData) {
        [environmentData setDebug:debugData];
    }
    */
    MUXSDKViewerData *viewerData = [[MUXSDKViewerData alloc] init];
    NSString *bundleId = [[NSBundle mainBundle] bundleIdentifier];
    if (bundleId) {
        [viewerData setViewerApplicationName:bundleId];
    }
    NSString *bundleShortVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    NSString *bundleVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
    if (bundleShortVersion && bundleVersion) {
        NSString *fullVersion = [NSString stringWithFormat:@"%@ (%@)", bundleShortVersion, bundleVersion];
        [viewerData setViewerApplicationVersion:fullVersion];
    } else if (bundleShortVersion) {
        [viewerData setViewerApplicationVersion:bundleShortVersion];
    } else if (bundleVersion) {
        [viewerData setViewerApplicationVersion:bundleVersion];
    }
    [viewerData setViewerDeviceManufacturer:@"Apple"];
    struct utsname systemInfo;
    uname(&systemInfo);
    [viewerData setViewerDeviceModel:[NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding]];
    NSString *deviceCategory = @"unknown";
    NSString *osFamily = @"unknown";
    switch ([[UIDevice currentDevice] userInterfaceIdiom]) {
        case UIUserInterfaceIdiomTV:
            deviceCategory = @"tv";
            osFamily = @"tvOS";
            break;
        case UIUserInterfaceIdiomPad:
            deviceCategory = @"tablet";
            osFamily = @"iOS";
            break;
        case UIUserInterfaceIdiomPhone:
            deviceCategory = @"phone";
            osFamily = @"iOS";
            break;
        case UIUserInterfaceIdiomCarPlay:
            deviceCategory = @"car";
            osFamily = @"CarPlay";
            break;
        default:
            break;
    }
    [viewerData setViewerDeviceCategory:deviceCategory];
    [viewerData setViewerOsFamily:osFamily];
    [viewerData setViewerOsVersion:[[UIDevice currentDevice] systemVersion]];
    MUXSDKDataEvent *dataEvent = [[MUXSDKDataEvent alloc] init];
    [dataEvent setEnvironmentData:environmentData];
    [dataEvent setViewerData:viewerData];
    [MUXSDKCore dispatchGlobalDataEvent:dataEvent];
}

#pragma mark Monitor AVPlayerViewController

+ (MUXSDKPlayerBinding *_Nullable)monitorAVPlayerViewController:(nonnull AVPlayerViewController *)player
                                                 withPlayerName:(nonnull NSString *)name
                                                   customerData:(nonnull MUXSDKCustomerData *)customerData {
    return [self monitorAVPlayerViewController:player
                                withPlayerName:name
                                  customerData:customerData
                        automaticErrorTracking:true];
}

+ (MUXSDKPlayerBinding *_Nullable)monitorAVPlayerViewController:(nonnull AVPlayerViewController *)player
                                                 withPlayerName:(nonnull NSString *)name
                                                   customerData:(nonnull MUXSDKCustomerData *)customerData
                                         automaticErrorTracking:(BOOL)automaticErrorTracking {

    [self initSDK];
    NSString *binding = [_bindings valueForKey:name];
    if (binding) {
        // Destroy any previously existing player with this name.
        [self destroyPlayer:name];
    }
    if (player.player) {
        MUXSDKCustomerPlayerData *playerData = customerData.customerPlayerData;
        MUXSDKCustomerVideoData *videoData = customerData.customerVideoData;
        MUXSDKCustomerViewData *viewData = customerData.customerViewData;
        MUXSDKCustomData *customData = customerData.customData;

        MUXSDKAVPlayerViewControllerBinding *newBinding = [[MUXSDKAVPlayerViewControllerBinding alloc] initWithName:name software:MuxPlayerSoftwareAVPlayerViewController andView:player];
        [newBinding setAutomaticErrorTracking:automaticErrorTracking];
        newBinding.playDispatchDelegate = _playerBindingManager;
        [_customerPlayerDataStore setPlayerData:playerData forPlayerName:name];
        if (videoData) {
            [_customerVideoDataStore setVideoData:videoData forPlayerName:name];
        }
        if (viewData) {
            [_customerViewDataStore setViewData:viewData forPlayerName:name];
        }
        if (customData) {
            [_customerCustomDataStore setCustomData:customData forPlayerName:name];
        }
        [_viewControllers setValue:newBinding forKey:name];
        [_bindings setValue:MuxPlayerSoftwareAVPlayerViewController forKey:name];

        [newBinding attachAVPlayer:player.player];
        [_playerBindingManager newViewForPlayer:name];
        return newBinding;
    } else {
        NSLog(@"MUXSDK-ERROR - Mux failed to configure the monitor because AVPlayerViewController.player was NULL for player name: %@", name);
        return NULL;
    }
}

+ (MUXSDKPlayerBinding *_Nullable)monitorAVPlayerViewController:(nonnull AVPlayerViewController *)player
                                                 withPlayerName:(nonnull NSString *)name
                                                     playerData:(nonnull MUXSDKCustomerPlayerData *)playerData
                                                      videoData:(nullable MUXSDKCustomerVideoData *)videoData {
    return [self monitorAVPlayerViewController:player
                                withPlayerName:name
                                    playerData:playerData
                                     videoData:videoData
                                      viewData:nil
                        automaticErrorTracking: true];
}

+ (MUXSDKPlayerBinding *_Nullable)monitorAVPlayerViewController:(nonnull AVPlayerViewController *)player
                                                 withPlayerName:(nonnull NSString *)name
                                                     playerData:(nonnull MUXSDKCustomerPlayerData *)playerData
                                                      videoData:(nullable MUXSDKCustomerVideoData *)videoData
                                                       viewData:(nullable MUXSDKCustomerViewData *)viewData {
    return [self monitorAVPlayerViewController:player
                                withPlayerName:name
                                    playerData:playerData
                                     videoData:videoData
                                      viewData:viewData
                        automaticErrorTracking: true];
}

+ (MUXSDKPlayerBinding *_Nullable)monitorAVPlayerViewController:(nonnull AVPlayerViewController *)player
                                                 withPlayerName:(nonnull NSString *)name
                                                     playerData:(nonnull MUXSDKCustomerPlayerData *)playerData
                                                      videoData:(nullable MUXSDKCustomerVideoData *)videoData
                                         automaticErrorTracking:(BOOL) automaticErrorTracking {
    return [self monitorAVPlayerViewController:player
                         withPlayerName:name
                             playerData:playerData
                              videoData:videoData
                               viewData:nil
                 automaticErrorTracking:automaticErrorTracking];
}

+ (MUXSDKPlayerBinding *_Nullable)monitorAVPlayerViewController:(nonnull AVPlayerViewController *)player
                                                 withPlayerName:(nonnull NSString *)name
                                                     playerData:(nonnull MUXSDKCustomerPlayerData *)playerData
                                                      videoData:(nullable MUXSDKCustomerVideoData *)videoData
                                                       viewData:(nullable MUXSDKCustomerViewData *)viewData
                                         automaticErrorTracking:(BOOL) automaticErrorTracking {
    MUXSDKCustomerData *customerData = [[MUXSDKCustomerData alloc] initWithCustomerPlayerData:playerData
                                                                                    videoData:videoData
                                                                                     viewData:viewData];
    return [self monitorAVPlayerViewController:player
                                withPlayerName:name
                                  customerData:customerData
                        automaticErrorTracking:automaticErrorTracking];
}

+ (void)updateAVPlayerViewController:(nonnull AVPlayerViewController *)player withPlayerName:(nonnull NSString *)name {
    [self initSDK];
    NSString *binding = [_bindings valueForKey:name];
    if (binding) {
        if (!player.player) {
            NSLog(@"MUXSDK-ERROR - Mux failed to configure the monitor because AVPlayerViewController.player was NULL for player name: %@", name);
            return;
        }
        if (binding == MuxPlayerSoftwareAVPlayerViewController) {
            MUXSDKAVPlayerViewControllerBinding *playerController = [_viewControllers valueForKey:name];
            [playerController detachAVPlayer];
            [playerController attachAVPlayer:player.player];
        } else {
            NSLog(@"MUXSDK-ERROR - Mux failed to update the monitor because the previous player with name %@ was not set up via monitorAVPlayerViewController", name);
        }
    } else {
        NSLog(@"MUXSDK-ERROR - Mux failed to update the monitor because no player exists with the player name: %@", name);
    }
}

#pragma mark Monitor AVPlayerLayer

+ (MUXSDKPlayerBinding *_Nullable)monitorAVPlayerLayer:(nonnull AVPlayerLayer *)player
                                        withPlayerName:(nonnull NSString *)name
                                          customerData:(nonnull MUXSDKCustomerData *)customerData {

    return [self monitorAVPlayerLayer:player
                       withPlayerName:name
                         customerData:customerData
               automaticErrorTracking:true];
}

+ (MUXSDKPlayerBinding *_Nullable)monitorAVPlayerLayer:(nonnull AVPlayerLayer *)player
                                        withPlayerName:(nonnull NSString *)name
                                          customerData:(nonnull MUXSDKCustomerData *)customerData
                                automaticErrorTracking:(BOOL) automaticErrorTracking {

    [self initSDK];
    NSString *binding = [_bindings valueForKey:name];
    if (binding) {
        // Destroy any previously existing player with this name.
        [self destroyPlayer:name];
    }
    if (player.player) {
        MUXSDKCustomerPlayerData *playerData = customerData.customerPlayerData;
        MUXSDKCustomerVideoData *videoData = customerData.customerVideoData;
        MUXSDKCustomerViewData *viewData = customerData.customerViewData;
        MUXSDKCustomData *customData = customerData.customData;

        MUXSDKAVPlayerLayerBinding *newBinding = [[MUXSDKAVPlayerLayerBinding alloc] initWithName:name software:MuxPlayerSoftwareAVPlayerLayer andView:player];
        newBinding.playDispatchDelegate = _playerBindingManager;
        [newBinding setAutomaticErrorTracking:automaticErrorTracking];
        [_customerPlayerDataStore setPlayerData:playerData forPlayerName:name];
        if (videoData) {
            [_customerVideoDataStore setVideoData:videoData forPlayerName:name];
        }
        if (viewData) {
            [_customerViewDataStore setViewData:viewData forPlayerName:name];
        }
        if (customData) {
            [_customerCustomDataStore setCustomData:customData forPlayerName:name];
        }
        [_viewControllers setValue:newBinding forKey:name];
        [_bindings setValue:MuxPlayerSoftwareAVPlayerLayer forKey:name];

        [newBinding attachAVPlayer:player.player];
        [_playerBindingManager newViewForPlayer:name];
        return newBinding;
    } else {
        NSLog(@"MUXSDK-ERROR - Mux failed to configure the monitor because AVPlayerLayer.player was NULL for player name: %@", name);
        return NULL;
    }

}

+ (MUXSDKPlayerBinding *_Nullable)monitorAVPlayerLayer:(nonnull AVPlayerLayer *)player
                                        withPlayerName:(nonnull NSString *)name
                                            playerData:(nonnull MUXSDKCustomerPlayerData *)playerData
                                             videoData:(nullable MUXSDKCustomerVideoData *)videoData {
    return [self monitorAVPlayerLayer:player
                       withPlayerName:name
                           playerData:playerData
                            videoData:videoData
                             viewData:nil
               automaticErrorTracking:true];
}

+ (MUXSDKPlayerBinding *_Nullable)monitorAVPlayerLayer:(nonnull AVPlayerLayer *)player
                                        withPlayerName:(nonnull NSString *)name
                                            playerData:(nonnull MUXSDKCustomerPlayerData *)playerData
                                             videoData:(nullable MUXSDKCustomerVideoData *)videoData
                                              viewData:(nullable MUXSDKCustomerViewData *)viewData {
    return [self monitorAVPlayerLayer:player
                       withPlayerName:name
                           playerData:playerData
                            videoData:videoData
                             viewData:viewData
               automaticErrorTracking:true];
}

+ (MUXSDKPlayerBinding *_Nullable) monitorAVPlayerLayer:(nonnull AVPlayerLayer *)player
                                         withPlayerName:(nonnull NSString *)name
                                             playerData:(nonnull MUXSDKCustomerPlayerData *)playerData
                                              videoData:(nullable MUXSDKCustomerVideoData *)videoData
                                 automaticErrorTracking:(BOOL) automaticErrorTracking {
    return [self monitorAVPlayerLayer:player
                       withPlayerName:name
                           playerData:playerData
                            videoData:videoData
                             viewData:nil
               automaticErrorTracking:automaticErrorTracking];
}

+ (MUXSDKPlayerBinding *_Nullable) monitorAVPlayerLayer:(nonnull AVPlayerLayer *)player
                                         withPlayerName:(nonnull NSString *)name
                                             playerData:(nonnull MUXSDKCustomerPlayerData *)playerData
                                              videoData:(nullable MUXSDKCustomerVideoData *)videoData
                                               viewData:(nullable MUXSDKCustomerViewData *)viewData
                                 automaticErrorTracking:(BOOL) automaticErrorTracking {
    MUXSDKCustomerData *customerData = [[MUXSDKCustomerData alloc] initWithCustomerPlayerData:playerData
                                                                                    videoData:videoData
                                                                                     viewData:viewData];
    return [self monitorAVPlayerLayer:player
                       withPlayerName:name
                         customerData:customerData
               automaticErrorTracking:automaticErrorTracking];
}

+ (void)updateAVPlayerLayer:(AVPlayerLayer *)player withPlayerName:(NSString *)name {
    [self initSDK];
    NSString *binding = [_bindings valueForKey:name];
    if (binding) {
        if (!player.player) {
            NSLog(@"MUXSDK-ERROR - Mux failed to configure the monitor because AVPlayerLayer.player was NULL for player name: %@", name);
            return;
        }
        if (binding == MuxPlayerSoftwareAVPlayerLayer) {
            MUXSDKAVPlayerLayerBinding *playerLayer = [_viewControllers valueForKey:name];
            [playerLayer detachAVPlayer];
            [playerLayer attachAVPlayer:player.player];
        } else {
            NSLog(@"MUXSDK-ERROR - Mux failed to update the monitor because the previous player with name %@ was not set up via monitorAVPlayerLayer", name);
        }
    } else {
        NSLog(@"MUXSDK-ERROR - Mux failed to update the monitor because no player exists with the player name: %@", name);
    }
}

#pragma mark UUID

+ (NSString *)getUUIDString {
    NSString *uuid = [[NSUserDefaults standardUserDefaults] stringForKey:MuxDeviceIDUserDefaultsKey];
    if (uuid == nil) {
        uuid = [[NSUUID UUID] UUIDString];
        [[NSUserDefaults standardUserDefaults] setObject:uuid forKey:MuxDeviceIDUserDefaultsKey];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    return uuid;
}

#pragma mark Destroy Player

+ (void)destroyPlayer:(NSString *)name {
    NSString *binding = [_bindings valueForKey:name];
    if (binding == MuxPlayerSoftwareAVPlayerViewController) {
        MUXSDKAVPlayerViewControllerBinding *player = [_viewControllers valueForKey:name];
        [player dispatchViewEnd];
        [player detachAVPlayer];
        [_viewControllers removeObjectForKey:name];
    } else if (binding == MuxPlayerSoftwareAVPlayerLayer) {
        MUXSDKAVPlayerLayerBinding *player = [_viewControllers valueForKey:name];
        [player dispatchViewEnd];
        [player detachAVPlayer];
        [_viewControllers removeObjectForKey:name];
    }
    [_bindings removeObjectForKey:name];
    [_playerBindingManager onPlayerDestroyed:name];
}

#pragma mark Video Change

+ (void)videoChangeForPlayer:(nonnull NSString *)name withCustomerData:(nullable MUXSDKCustomerData *)customerData {
    MUXSDKCustomerPlayerData *playerData = [customerData customerPlayerData];
    if (!playerData) {
        playerData = [_customerPlayerDataStore playerDataForPlayerName:name];
    }
    MUXSDKCustomerViewData *viewData = [customerData customerViewData];
    MUXSDKCustomerVideoData *videoData = [customerData customerVideoData];
    MUXSDKCustomData *customData = [customerData customData];
    
    if (!(videoData || viewData || customData)) {
        return;
    }
    MUXSDKPlayerBinding *player = [_viewControllers valueForKey:name];
    if (player) {
        [player didTriggerManualVideoChange];
        [player dispatchViewEnd];
        if (videoData) {
            [_customerVideoDataStore setVideoData:videoData forPlayerName:name];
        }
        if (viewData) {
            [_customerViewDataStore setViewData:viewData forPlayerName:name];
        }
        if (playerData) {
            [_customerPlayerDataStore setPlayerData:playerData forPlayerName:name];
        }
        if (customData) {
            [_customerCustomDataStore setCustomData:customData forPlayerName:name];
        }
        [player prepareForAvQueuePlayerNextItem];
    }
}

+ (void)videoChangeForPlayer:(nonnull NSString *)name  withPlayerData:(nullable MUXSDKCustomerPlayerData *)playerData withVideoData:(nullable MUXSDKCustomerVideoData *)videoData viewData: (nullable MUXSDKCustomerViewData *) viewData {
    MUXSDKCustomerData *customerData = [[MUXSDKCustomerData alloc] initWithCustomerPlayerData:playerData videoData:videoData viewData:viewData];
    [self videoChangeForPlayer:name withCustomerData:customerData];
}

+ (void)videoChangeForPlayer:(nonnull NSString *)name withPlayerData:(nullable MUXSDKCustomerPlayerData *)playerData withVideoData:(nullable MUXSDKCustomerVideoData *)videoData {
    MUXSDKCustomerData *customerData = [[MUXSDKCustomerData alloc] initWithCustomerPlayerData:playerData videoData:videoData viewData:nil];
    [self videoChangeForPlayer:name withCustomerData:customerData];
}

+ (void)videoChangeForPlayer:(nonnull NSString *)name withVideoData:(nullable MUXSDKCustomerVideoData *)videoData {
    MUXSDKCustomerData *customerData = [[MUXSDKCustomerData alloc] init];
    customerData.customerVideoData = videoData;
    [self videoChangeForPlayer:name withCustomerData:customerData];
}

+ (void)programChangeForPlayer:(nonnull NSString *)name withVideoData:(nullable MUXSDKCustomerVideoData *)videoData {
    [MUXSDKStats videoChangeForPlayer: name withVideoData:videoData];
    MUXSDKPlayerBinding *player = [_viewControllers valueForKey:name];
    if (player) {
        [player programChangedForPlayer];
    }
}

+ (void)setAutomaticVideoChange:(NSString *)name  enabled:(Boolean)enabled {
    MUXSDKPlayerBinding *player = [_viewControllers valueForKey:name];
    if(player) {
        [player setAutomaticVideoChange:enabled];
    }
}

#pragma mark Update Customer Data

+ (void)setCustomerData:(nullable MUXSDKCustomerData *)customerData forPlayer:(nonnull NSString *)name {
    MUXSDKPlayerBinding *player = [_viewControllers valueForKey:name];
    if (!player) return;

    MUXSDKCustomerPlayerData *playerData = [customerData customerPlayerData];
    MUXSDKCustomerViewData *viewData = [customerData customerViewData];
    MUXSDKCustomerVideoData *videoData = [customerData customerVideoData];
    MUXSDKCustomData *customData = [customerData customData];

    if (!playerData && !videoData && !viewData && !customData) return;
    MUXSDKDataEvent *dataEvent = [MUXSDKDataEvent new];
    if (playerData) {
        [_customerPlayerDataStore setPlayerData:playerData forPlayerName:name];
        [dataEvent setCustomerPlayerData:playerData];
    }
    if (videoData) {
        [_customerVideoDataStore setVideoData:videoData forPlayerName:name];
        [dataEvent setCustomerVideoData:videoData];
    }
    if (viewData) {
        [_customerViewDataStore setViewData:viewData forPlayerName:name];
        [dataEvent setCustomerViewData:viewData];
    }
    if (customData) {
        [_customerCustomDataStore setCustomData:customData forPlayerName:name];
        [dataEvent setCustomData:customData];
    }
    [MUXSDKCore dispatchEvent:dataEvent forPlayer:name];

}

+ (void)updateCustomerDataForPlayer:(nonnull NSString *)name withPlayerData:(nullable MUXSDKCustomerPlayerData *)playerData withVideoData:(nullable MUXSDKCustomerVideoData *)videoData {
    [self updateCustomerDataForPlayer:name withPlayerData:playerData withVideoData:videoData viewData:nil];
}

+ (void)updateCustomerDataForPlayer:(nonnull NSString *)name withPlayerData:(nullable MUXSDKCustomerPlayerData *)playerData withVideoData:(nullable MUXSDKCustomerVideoData *)videoData viewData: (nullable MUXSDKCustomerViewData *) viewData {
    MUXSDKCustomerData *customerData = [[MUXSDKCustomerData alloc] initWithCustomerPlayerData:playerData
                                                                                    videoData:videoData
                                                                                     viewData:viewData];
    [self setCustomerData:customerData forPlayer:name];
}

#pragma mark Orientation Change

+ (void) orientationChangeForPlayer:(nonnull NSString *) name  withOrientation:(MUXSDKViewOrientation) orientation {
    MUXSDKPlayerBinding *player = [_viewControllers valueForKey:name];
    if (!player) return;
    [player dispatchOrientationChange:orientation];
}

#pragma mark Error

+ (void)dispatchError:(nonnull NSString *)code withMessage:(nonnull NSString *)message forPlayer:(nonnull NSString *)name {
    MUXSDKPlayerBinding *player = [_viewControllers valueForKey:name];
    if (!player) return;
    [player dispatchError:code withMessage:message];
}
@end
