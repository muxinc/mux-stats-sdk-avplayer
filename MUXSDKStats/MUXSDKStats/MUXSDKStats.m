#import "MUXSDKStats.h"
#import "MUXSDKPlayerBinding.h"

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
// Name => MUXSDKCustomerPlayerData
static NSMutableDictionary *_customerPlayerDatas;

+ (void)initSDK {
    if (!_bindings) {
        _bindings = [[NSMutableDictionary alloc] init];
    }
    if (!_viewControllers) {
        _viewControllers = [[NSMutableDictionary alloc] init];
    }
    if (!_customerPlayerDatas) {
        _customerPlayerDatas = [[NSMutableDictionary alloc] init];
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

+ (void)dispatchDataEventForPlayerName:(NSString *)name playerData:(MUXSDKCustomerPlayerData *)customerPlayerData videoData:(MUXSDKCustomerVideoData *)customerVideoData {
    MUXSDKDataEvent *dataEvent = [[MUXSDKDataEvent alloc] init];
    if (customerPlayerData) {
        [dataEvent setCustomerPlayerData:customerPlayerData];
        [_customerPlayerDatas setValue:customerPlayerData forKey:name];
    }
    if (customerVideoData) {
        [dataEvent setCustomerVideoData:customerVideoData];
    }
    if (customerPlayerData || customerVideoData) {
        [MUXSDKCore dispatchEvent:dataEvent forPlayer:name];
    }
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
        [newBinding attachAVPlayer:player.player];
        [newBinding dispatchViewInit];
        [self dispatchDataEventForPlayerName:name playerData:playerData videoData:videoData];
        [newBinding dispatchPlayerReady];
        [_viewControllers setValue:newBinding forKey:name];
        [_bindings setValue:MuxPlayerSoftwareAVPlayerViewController forKey:name];
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
        [newBinding attachAVPlayer:player.player];
        [newBinding dispatchViewInit];
        [self dispatchDataEventForPlayerName:name playerData:playerData videoData:videoData];
        [newBinding dispatchPlayerReady];
        [_viewControllers setValue:newBinding forKey:name];
        [_bindings setValue:MuxPlayerSoftwareAVPlayerLayer forKey:name];
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
            [player dispatchViewInit];
            MUXSDKDataEvent *dataEvent = [MUXSDKDataEvent new];
            [dataEvent setCustomerVideoData:videoData];
            MUXSDKCustomerPlayerData *playerData = [_customerPlayerDatas valueForKey:name];
            if (playerData) {
                [dataEvent setCustomerPlayerData:playerData];
            }
            dataEvent.videoChange = YES;
            [MUXSDKCore dispatchEvent:dataEvent forPlayer:name];
        }
    }
}

+ (void)videoChangeForPlayer:(nonnull NSString *)name withVideoData:(nullable MUXSDKCustomerVideoData *)videoData {
    MUXSDKCustomerPlayerData *playerData = [_customerPlayerDatas valueForKey:name];
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
        [dataEvent setCustomerPlayerData:playerData];
        [_customerPlayerDatas setValue:playerData forKey:name];
    }
    if (videoData) {
        [dataEvent setCustomerVideoData:videoData];
    }
    [MUXSDKCore dispatchEvent:dataEvent forPlayer:name];
}

@end
