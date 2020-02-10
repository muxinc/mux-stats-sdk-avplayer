#import "MUXSDKStats.h"
#import "MUXSDKPlayerBinding.h"
#import "MUXSDKPlayerBindingManager.h"
#import "MUXSDKCustomerPlayerDataStore.h"
#import "MUXSDKCustomerVideoDataStore.h"
#import <Foundation/Foundation.h>
#import <sys/utsname.h>

@import AVFoundation;
@import AVKit;
@import Foundation;
@import UIKit;

// Software constants.
NSString *const MuxPlayerSoftwareAVPlayerViewController = @"AVPlayerViewController";
NSString *const MuxPlayerSoftwareAVPlayerLayer = @"AVPlayerLayer";


@implementation MUXSDKStats

static MUXSDKDispatcher *_dispatcher;
// Name => MuxPlayerSoftware value.
static NSMutableDictionary *_bindings;
// Name => AVPlayerViewController or AVPlayerLayer
static NSMutableDictionary *_viewControllers;

static MUXSDKPlayerBindingManager *_playerBindingManager;
static MUXSDKCustomerPlayerDataStore *_customerPlayerDataStore;
static MUXSDKCustomerVideoDataStore *_customerVideoDataStore;

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
    if (!_playerBindingManager) {
        _playerBindingManager = [[MUXSDKPlayerBindingManager alloc] init];
        _playerBindingManager.customerPlayerDataStore = _customerPlayerDataStore;
        _playerBindingManager.customerVideoDataStore = _customerVideoDataStore;
        _playerBindingManager.viewControllers = _viewControllers;
    }
    
    // Provide EnvironmentData and ViewerData to Core.
    MUXSDKEnvironmentData *environmentData = [[MUXSDKEnvironmentData alloc] init];
    [environmentData setMuxViewerId:[[[UIDevice currentDevice] identifierForVendor] UUIDString]];
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
    [viewerData setViewerDeviceName:[NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding]];
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

+ (MUXSDKPlayerBinding *_Nullable)monitorAVPlayerViewController:(nonnull AVPlayerViewController *)player withPlayerName:(nonnull NSString *)name playerData:(nonnull MUXSDKCustomerPlayerData *)playerData videoData:(nullable MUXSDKCustomerVideoData *)videoData {
    [self initSDK];
    NSString *binding = [_bindings valueForKey:name];
    if (binding) {
        // Destory any previously existing player with this name.
        [self destroyPlayer:name];
    }
    if (player.player) {
        MUXSDKAVPlayerViewControllerBinding *newBinding = [[MUXSDKAVPlayerViewControllerBinding alloc] initWithName:name software:MuxPlayerSoftwareAVPlayerViewController andView:player];
        newBinding.playDispatchDelegate = _playerBindingManager;
        [_customerPlayerDataStore setPlayerData:playerData forPlayerName:name];
        [_customerVideoDataStore setVideoData:videoData forPlayerName:name];
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

+ (MUXSDKPlayerBinding *_Nullable)monitorAVPlayerLayer:(nonnull AVPlayerLayer *)player withPlayerName:(nonnull NSString *)name playerData:(nonnull MUXSDKCustomerPlayerData *)playerData videoData:(nullable MUXSDKCustomerVideoData *)videoData {
    [self initSDK];
    NSString *binding = [_bindings valueForKey:name];
    if (binding) {
        // Destory any previously existing player with this name.
        [self destroyPlayer:name];
    }
    if (player.player) {
        MUXSDKAVPlayerLayerBinding *newBinding = [[MUXSDKAVPlayerLayerBinding alloc] initWithName:name software:MuxPlayerSoftwareAVPlayerLayer andView:player];
        newBinding.playDispatchDelegate = _playerBindingManager;
        [_customerPlayerDataStore setPlayerData:playerData forPlayerName:name];
        [_customerVideoDataStore setVideoData:videoData forPlayerName:name];
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

+ (void)destroyPlayer:(NSString *)name {
    NSString *binding = [_bindings valueForKey:name];
    if (binding == MuxPlayerSoftwareAVPlayerViewController) {
        MUXSDKAVPlayerViewControllerBinding *player = [_viewControllers valueForKey:name];
        [player detachAVPlayer];
        [_viewControllers removeObjectForKey:name];
    } else if (binding == MuxPlayerSoftwareAVPlayerLayer) {
        MUXSDKAVPlayerLayerBinding *player = [_viewControllers valueForKey:name];
        [player detachAVPlayer];
        [_viewControllers removeObjectForKey:name];
    }
    [_bindings removeObjectForKey:name];
}

+ (void)videoChangeForPlayer:(nonnull NSString *)name withPlayerData:(nullable MUXSDKCustomerPlayerData *)playerData withVideoData:(nullable MUXSDKCustomerVideoData *)videoData {
    if (videoData) {
        MUXSDKPlayerBinding *player = [_viewControllers valueForKey:name];
        if (player) {
            [player dispatchViewEnd];
            [_customerVideoDataStore setVideoData:videoData forPlayerName:name];
            if (playerData) {
                [_customerPlayerDataStore setPlayerData:playerData forPlayerName:name];
            }
        }
    }
}

+ (void)videoChangeForPlayer:(nonnull NSString *)name withVideoData:(nullable MUXSDKCustomerVideoData *)videoData {
    MUXSDKCustomerPlayerData *playerData = [_customerPlayerDataStore playerDataForPlayerName:name];
    [self videoChangeForPlayer:name withPlayerData:playerData withVideoData:videoData];
}

+ (void)programChangeForPlayer:(nonnull NSString *)name withVideoData:(nullable MUXSDKCustomerVideoData *)videoData {
    [MUXSDKStats videoChangeForPlayer: name withVideoData:videoData];
    MUXSDKPlayerBinding *player = [_viewControllers valueForKey:name];
    if (player) {
        [player dispatchPlay];
        [player dispatchPlaying];
    }
}

+ (void)updateCustomerDataForPlayer:(nonnull NSString *)name withPlayerData:(nullable MUXSDKCustomerPlayerData *)playerData withVideoData:(nullable MUXSDKCustomerVideoData *)videoData {
    MUXSDKPlayerBinding *player = [_viewControllers valueForKey:name];
    if (!player) return;
    if (!playerData && !videoData) return;
    MUXSDKDataEvent *dataEvent = [MUXSDKDataEvent new];
    if (playerData) {
         [_customerPlayerDataStore setPlayerData:playerData forPlayerName:name];
        [dataEvent setCustomerPlayerData:playerData];
    }
    if (videoData) {
        [_customerVideoDataStore setVideoData:videoData forPlayerName:name];
        [dataEvent setCustomerVideoData:videoData];
    }
    [MUXSDKCore dispatchEvent:dataEvent forPlayer:name];
}


@end
