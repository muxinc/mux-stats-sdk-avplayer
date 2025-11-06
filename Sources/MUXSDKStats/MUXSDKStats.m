#import <AVKit/AVKit.h>
#import <AVFoundation/AVFoundation.h>
#import <Foundation/Foundation.h>

#import <sys/utsname.h>

#import "MUXSDKStats/MUXSDKStats.h"
#import "MUXSDKStats/MUXSDKPlayerBinding.h"
#import "MUXSDKPlayerBindingManager.h"
#import "MUXSDKCustomerPlayerDataStore.h"
#import "MUXSDKCustomerVideoDataStore.h"
#import "MUXSDKCustomerViewDataStore.h"
#import "MUXSDKCustomerCustomDataStore.h"

// Software constants.
static NSString *const MuxPlayerSoftwareAVPlayerViewController = @"AVPlayerViewController";
static NSString *const MuxPlayerSoftwareAVPlayerLayer = @"AVPlayerLayer";
static NSString *const MuxPlayerSoftwareAVPlayer = @"AVPlayer";
static NSString *const MuxDeviceIDUserDefaultsKey = @"MUX_DEVICE_ID";


@implementation MUXSDKStats

static NSMutableDictionary<NSString *, __kindof MUXSDKPlayerBinding *> *_bindingsByPlayerName;

static MUXSDKPlayerBindingManager *_playerBindingManager;
static MUXSDKCustomerPlayerDataStore *_customerPlayerDataStore;
static MUXSDKCustomerVideoDataStore *_customerVideoDataStore;
static MUXSDKCustomerViewDataStore *_customerViewDataStore;
static MUXSDKCustomerCustomDataStore *_customerCustomDataStore;

+ (void)initSDKWithCustomerViewerData:(MUXSDKCustomerViewerData *)customerViewerData {
    if (!_bindingsByPlayerName) {
        _bindingsByPlayerName = [[NSMutableDictionary alloc] init];
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
        _playerBindingManager.bindingsByPlayerName = _bindingsByPlayerName;
    }

    // Provide Environment/Viewer/CustomerViewer to Core.
    MUXSDKEnvironmentData *environmentData = [self buildEnvironmentData];
    MUXSDKViewerData *viewerData = [self buildViewerData];
    MUXSDKDataEvent *dataEvent = [[MUXSDKDataEvent alloc] init];
    [dataEvent setEnvironmentData:environmentData];
    [dataEvent setViewerData:viewerData];
    [dataEvent setCustomerViewerData:customerViewerData];
    [MUXSDKCore dispatchGlobalDataEvent:dataEvent];
}

+ (void)dispatchGlobalEventForCustomerData:(MUXSDKCustomerData *)customerData {
    MUXSDKCustomerViewerData *customerViewerData = customerData.customerViewerData;
    if (customerViewerData == nil) {
        return;
    }
    MUXSDKDataEvent *dataEvent = [[MUXSDKDataEvent alloc] init];
    dataEvent.customerViewerData = customerViewerData;
    [MUXSDKCore dispatchGlobalDataEvent:dataEvent];
}

+ (MUXSDKEnvironmentData *)buildEnvironmentData {
    MUXSDKEnvironmentData *environmentData = [[MUXSDKEnvironmentData alloc] init];
    [environmentData setMuxViewerId:[self getUUIDString]];
    /*
    NSString *debugData = [MUXSDKConfigParser getNSStringForKey:@"debug" fromDictionary:config];
    if (debugData) {
        [environmentData setDebug:debugData];
    }
    */
    return environmentData;
}

+ (MUXSDKViewerData *)buildViewerData {
    MUXSDKViewerData *viewerData = [[MUXSDKViewerData alloc] init];

    NSString *applicationName = [[NSBundle mainBundle] bundleIdentifier];
    if (applicationName != nil) {
        [viewerData setViewerApplicationName:applicationName];
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
    NSString *systemDeviceCategory = @"unknown";
    NSString *systemOsFamily = @"unknown";
    struct utsname systemInfo;
    uname(&systemInfo);
    NSString *systemDeviceModel = [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
    NSString *systemOsVersion = [[UIDevice currentDevice] systemVersion];
    switch ([[UIDevice currentDevice] userInterfaceIdiom]) {
        case UIUserInterfaceIdiomTV:
            systemDeviceCategory = @"tv";
            systemOsFamily = @"tvOS";
            break;
        case UIUserInterfaceIdiomPad:
            systemDeviceCategory = @"tablet";
            systemOsFamily = @"iOS";
            break;
        case UIUserInterfaceIdiomPhone:
            systemDeviceCategory = @"phone";
            systemOsFamily = @"iOS";
            break;
        case UIUserInterfaceIdiomCarPlay:
            systemDeviceCategory = @"car";
            systemOsFamily = @"CarPlay";
            break;
        case UIUserInterfaceIdiomVision:
            systemDeviceCategory = @"headset";
            systemOsFamily = @"visionOS";
        default:
            break;
    }
    
    // Detected values for device metadata
    [viewerData setMuxViewerDeviceModel:systemDeviceModel];
    [viewerData setMuxViewerDeviceCategory:systemDeviceCategory];
    [viewerData setMuxViewerOsFamily:systemOsFamily];
    [viewerData setMuxViewerOsVersion:systemOsVersion];
    [viewerData setMuxViewerDeviceManufacturer:@"Apple"];
    
    return viewerData;
}

#pragma mark Monitor AVPlayerViewController

+ (MUXSDKPlayerBinding *_Nullable)monitorAVPlayerViewController:(nonnull AVPlayerViewController *)player
                                                 withPlayerName:(nonnull NSString *)name
                                                   customerData:(nonnull MUXSDKCustomerData *)customerData
                                         automaticErrorTracking:(BOOL)automaticErrorTracking
                                         beaconCollectionDomain:(nullable NSString *)collectionDomain {
    [self initSDKWithCustomerViewerData:customerData.customerViewerData];

    // Destroy any previously existing player with this name.
    [self destroyPlayer:name];

    if (player.player) {
        MUXSDKCustomerPlayerData *playerData = customerData.customerPlayerData;
        MUXSDKCustomerVideoData *videoData = customerData.customerVideoData;
        MUXSDKCustomerViewData *viewData = customerData.customerViewData;
        MUXSDKCustomData *customData = customerData.customData;

        // If customerData sets a custom playerSoftwareName use that
        // If customerData playerSoftwareName is nil, use a default value
        NSString *playerSoftwareName = customerData.customerPlayerData.playerSoftwareName ?: MuxPlayerSoftwareAVPlayerViewController;
        // MUXSDKStats sets a nil for playerSoftwareVersion by default
        // If customerData playerSoftware version is set, pass that along
        // If unset, it is nil and this keeps the existing behavior as the fallback
        NSString *playerSoftwareVersion = customerData.customerPlayerData.playerSoftwareVersion;
        MUXSDKAVPlayerViewControllerBinding *newBinding = [[MUXSDKAVPlayerViewControllerBinding alloc] initWithPlayerName:name
                                                                                                             softwareName:playerSoftwareName
                                                                                                          softwareVersion:playerSoftwareVersion
                                                                                                     playerViewController:player];

        [newBinding setAutomaticErrorTracking:automaticErrorTracking];
        newBinding.playDispatchDelegate = _playerBindingManager;
        
        if (collectionDomain != nil && collectionDomain.length > 0) {
            [MUXSDKCore setBeaconCollectionDomain:collectionDomain forPlayer:name];
        }
        [MUXSDKCore setDeviceId:[MUXSDKStats getUUIDString] forPlayer:name];
        
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
        [_bindingsByPlayerName setValue:newBinding forKey:name];

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
                                                   customerData:(nonnull MUXSDKCustomerData *)customerData
                                         automaticErrorTracking:(BOOL)automaticErrorTracking {
    return [self monitorAVPlayerViewController:player
                                withPlayerName:name
                                  customerData:customerData
                        automaticErrorTracking:automaticErrorTracking
                        beaconCollectionDomain:nil];

}

+ (MUXSDKPlayerBinding *_Nullable)monitorAVPlayerViewController:(nonnull AVPlayerViewController *)player
                                                 withPlayerName:(nonnull NSString *)name
                                                   customerData:(nonnull MUXSDKCustomerData *)customerData {
    return [self monitorAVPlayerViewController:player
                                withPlayerName:name
                                  customerData:customerData
                        automaticErrorTracking:true
                        beaconCollectionDomain:nil];
}

+ (void)updateAVPlayerViewController:(nonnull AVPlayerViewController *)viewController
                      withPlayerName:(nonnull NSString *)name {
    [self initSDKWithCustomerViewerData:nil];

    __kindof MUXSDKPlayerBinding *binding = _bindingsByPlayerName[name];
    if (binding) {
        if (!viewController.player) {
            NSLog(@"MUXSDK-ERROR - Mux failed to configure the monitor because AVPlayerViewController.player was NULL for player name: %@", name);
            return;
        }
        if ([binding isKindOfClass:MUXSDKAVPlayerViewControllerBinding.class]) {
            MUXSDKAVPlayerViewControllerBinding *avpvcBinding = binding;
            [avpvcBinding attachAVPlayer:viewController.player];
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
                                          customerData:(nonnull MUXSDKCustomerData *)customerData
                                automaticErrorTracking:(BOOL)automaticErrorTracking
                                beaconCollectionDomain:(nullable NSString *)collectionDomain API_UNAVAILABLE(visionos) {
    [self initSDKWithCustomerViewerData:customerData.customerViewerData];

    // Destroy any previously existing player with this name.
    [self destroyPlayer:name];

    if (player.player) {
        MUXSDKCustomerPlayerData *playerData = customerData.customerPlayerData;
        MUXSDKCustomerVideoData *videoData = customerData.customerVideoData;
        MUXSDKCustomerViewData *viewData = customerData.customerViewData;
        MUXSDKCustomData *customData = customerData.customData;
        
        // If customerData sets a custom playerSoftwareName use that
        // If customerData playerSoftwareName is nil, use a default value
        NSString *playerSoftwareName = customerData.customerPlayerData.playerSoftwareName ?: MuxPlayerSoftwareAVPlayerLayer;
        // MUXSDKStats sets a nil for playerSoftwareVersion by default
        // If customerData playerSoftware version is set, pass that along
        // If unset, it is nil and this keeps the existing behavior as the fallback
        NSString *playerSoftwareVersion = customerData.customerPlayerData.playerSoftwareVersion;
        MUXSDKAVPlayerLayerBinding *newBinding = [[MUXSDKAVPlayerLayerBinding alloc] initWithPlayerName:name
                                                                                           softwareName:playerSoftwareName
                                                                                        softwareVersion:playerSoftwareVersion
                                                                                            playerLayer:player];
        newBinding.playDispatchDelegate = _playerBindingManager;
        [newBinding setAutomaticErrorTracking:automaticErrorTracking];
        if (collectionDomain != nil && collectionDomain.length > 0) {
            [MUXSDKCore setBeaconCollectionDomain:collectionDomain forPlayer:name];
        }
        [MUXSDKCore setDeviceId:[MUXSDKStats getUUIDString] forPlayer:name];


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
        [_bindingsByPlayerName setValue:newBinding forKey:name];

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
                                          customerData:(nonnull MUXSDKCustomerData *)customerData
                                automaticErrorTracking:(BOOL)automaticErrorTracking API_UNAVAILABLE(visionos) {

    return [self monitorAVPlayerLayer:player
                       withPlayerName:name
                         customerData:customerData
               automaticErrorTracking:automaticErrorTracking
                         beaconCollectionDomain:nil];
}

+ (MUXSDKPlayerBinding *_Nullable)monitorAVPlayerLayer:(nonnull AVPlayerLayer *)player
                                        withPlayerName:(nonnull NSString *)name
                                          customerData:(nonnull MUXSDKCustomerData *)customerData API_UNAVAILABLE(visionos) {

    return [self monitorAVPlayerLayer:player
                       withPlayerName:name
                         customerData:customerData
               automaticErrorTracking:true];
}

+ (void)updateAVPlayerLayer:(AVPlayerLayer *)playerLayer
             withPlayerName:(NSString *)name API_UNAVAILABLE(visionos) {
    [self initSDKWithCustomerViewerData:nil];

    __kindof MUXSDKPlayerBinding *binding = _bindingsByPlayerName[name];
    if (binding) {
        if (!playerLayer.player) {
            NSLog(@"MUXSDK-ERROR - Mux failed to configure the monitor because AVPlayerLayer.player was NULL for player name: %@", name);
            return;
        }
        if ([binding isKindOfClass:MUXSDKAVPlayerLayerBinding.class]) {
            MUXSDKAVPlayerLayerBinding *avplBinding = binding;
            [avplBinding attachAVPlayer:playerLayer.player];
        } else {
            NSLog(@"MUXSDK-ERROR - Mux failed to update the monitor because the previous player with name %@ was not set up via monitorAVPlayerLayer", name);
        }
    } else {
        NSLog(@"MUXSDK-ERROR - Mux failed to update the monitor because no player exists with the player name: %@", name);
    }
}

#pragma mark Monitor AVPlayer

+ (MUXSDKPlayerBinding *_Nullable)monitorAVPlayer:(nonnull AVPlayer *)player
                                   withPlayerName:(nonnull NSString *)name
                                  fixedPlayerSize:(CGSize)fixedPlayerSize
                                     customerData:(nonnull MUXSDKCustomerData *)customerData {
    return [self monitorAVPlayer:player
                  withPlayerName:name
                 fixedPlayerSize:fixedPlayerSize
                    customerData:customerData
          automaticErrorTracking:true
          beaconCollectionDomain:nil];
}

+ (MUXSDKPlayerBinding *_Nullable)monitorAVPlayer:(nonnull AVPlayer *)player
                                   withPlayerName:(nonnull NSString *)name
                                  fixedPlayerSize:(CGSize)fixedPlayerSize
                                     customerData:(nonnull MUXSDKCustomerData *)customerData
                           automaticErrorTracking:(BOOL)automaticErrorTracking {
    return [self monitorAVPlayer:player
                  withPlayerName:name
                 fixedPlayerSize:fixedPlayerSize
                    customerData:customerData
          automaticErrorTracking:automaticErrorTracking
          beaconCollectionDomain:nil];
}

+ (MUXSDKPlayerBinding *_Nullable)monitorAVPlayer:(nonnull AVPlayer *)player
                                   withPlayerName:(nonnull NSString *)name
                                  fixedPlayerSize:(CGSize)fixedPlayerSize
                                     customerData:(nonnull MUXSDKCustomerData *)customerData
                           automaticErrorTracking:(BOOL)automaticErrorTracking
                           beaconCollectionDomain:(nullable NSString *)collectionDomain {
    [self initSDKWithCustomerViewerData:customerData.customerViewerData];

    // Destroy any previously existing player with this name.
    [self destroyPlayer:name];

    MUXSDKCustomerPlayerData *playerData = customerData.customerPlayerData;
    MUXSDKCustomerVideoData *videoData = customerData.customerVideoData;
    MUXSDKCustomerViewData *viewData = customerData.customerViewData;
    MUXSDKCustomData *customData = customerData.customData;

    // If customerData sets a custom playerSoftwareName use that
    // If customerData playerSoftwareName is nil, use a default value
    NSString *playerSoftwareName = customerData.customerPlayerData.playerSoftwareName ?: MuxPlayerSoftwareAVPlayer;
    // MUXSDKStats sets nil for playerSoftwareVersion by default
    // If customerData playerSoftwareVersion is set, pass that along
    // If unset, it is nil and this keeps the existing behavior as the fallback
    NSString *playerSoftwareVersion = customerData.customerPlayerData.playerSoftwareVersion;
    MUXSDKFixedPlayerSizeBinding *newBinding = [[MUXSDKFixedPlayerSizeBinding alloc] initWithPlayerName:name
                                                                             softwareName:playerSoftwareName
                                                                          softwareVersion:playerSoftwareVersion
                                                                          fixedPlayerSize:fixedPlayerSize];
    [newBinding setAutomaticErrorTracking:automaticErrorTracking];
    newBinding.playDispatchDelegate = _playerBindingManager;

    if (collectionDomain != nil && collectionDomain.length > 0) {
        [MUXSDKCore setBeaconCollectionDomain:collectionDomain forPlayer:name];
    }
    [MUXSDKCore setDeviceId:[MUXSDKStats getUUIDString] forPlayer:name];

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
    [_bindingsByPlayerName setValue:newBinding forKey:name];

    [newBinding attachAVPlayer:player];
    [_playerBindingManager newViewForPlayer:name];
    return newBinding;
}

+ (void)updateAVPlayer:(AVPlayer *)player
        withPlayerName:(NSString *)name
       fixedPlayerSize:(CGSize)fixedPlayerSize {
    [self initSDKWithCustomerViewerData:nil];

    __kindof MUXSDKPlayerBinding *binding = _bindingsByPlayerName[name];
    if (binding) {
        if ([binding isKindOfClass:MUXSDKFixedPlayerSizeBinding.class]) {
            MUXSDKFixedPlayerSizeBinding *fixedSizeBinding = binding;
            [fixedSizeBinding attachAVPlayer:player];
        } else {
            NSLog(@"MUXSDK-ERROR - Mux failed to update the monitor because the previous player with name %@ was not set up via monitorAVPlayer", name);
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
    __kindof MUXSDKPlayerBinding *binding = _bindingsByPlayerName[name];
    [_bindingsByPlayerName removeObjectForKey:name];
    if ([binding isKindOfClass:MUXSDKAVPlayerViewControllerBinding.class]) {
        MUXSDKAVPlayerViewControllerBinding *avpvcBinding = binding;
        [avpvcBinding dispatchViewEnd];
        [avpvcBinding detachAVPlayer];
#if !TARGET_OS_VISION
    } else if ([binding isKindOfClass:MUXSDKAVPlayerLayerBinding.class]) {
        MUXSDKAVPlayerLayerBinding *avplBinding = binding;
        [avplBinding dispatchViewEnd];
        [avplBinding detachAVPlayer];
#endif // !TARGET_OS_VISION
    } else if ([binding isKindOfClass:MUXSDKFixedPlayerSizeBinding.class]) {
        MUXSDKFixedPlayerSizeBinding *fixedSizeBinding = binding;
        [fixedSizeBinding dispatchViewEnd];
        [fixedSizeBinding detachAVPlayer];
    }
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
    
    MUXSDKPlayerBinding *player = [_bindingsByPlayerName valueForKey:name];
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

    [self dispatchGlobalEventForCustomerData:customerData];
}

#pragma mark Program Change

+ (void)programChangeForPlayer:(nonnull NSString *)name
              withCustomerData:(nullable MUXSDKCustomerData *)customerData {
    [MUXSDKStats videoChangeForPlayer:name withCustomerData:customerData];
    MUXSDKPlayerBinding *player = [_bindingsByPlayerName valueForKey:name];
    if (player) {
        [player programChangedForPlayer];
    }
}

+ (void)setAutomaticVideoChange:(NSString *)name enabled:(Boolean)enabled {
    MUXSDKPlayerBinding *player = [_bindingsByPlayerName valueForKey:name];
    if (player) {
        [player setAutomaticVideoChange:enabled];
    }
}

#pragma mark Update Customer Data

+ (void)setCustomerData:(nullable MUXSDKCustomerData *)customerData forPlayer:(nonnull NSString *)name {
    MUXSDKPlayerBinding *player = [_bindingsByPlayerName valueForKey:name];
    if (!player) return;

    MUXSDKCustomerPlayerData *playerData = [customerData customerPlayerData];
    MUXSDKCustomerViewData *viewData = [customerData customerViewData];
    MUXSDKCustomerVideoData *videoData = [customerData customerVideoData];
    MUXSDKCustomData *customData = [customerData customData];

    if (playerData || videoData || viewData || customData) {
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
    
    [self dispatchGlobalEventForCustomerData:customerData];
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
    MUXSDKPlayerBinding *player = [_bindingsByPlayerName valueForKey:name];
    if (!player) return;
    [player dispatchOrientationChange:orientation];
}

#pragma mark Playback Mode

+ (void) playbackModeChangeForPlayer:(nonnull NSString *) name
                    withPlaybackMode:(nonnull MUXSDKPlaybackMode) mode {
    MUXSDKPlayerBinding *binding = [_bindingsByPlayerName valueForKey:name];
    if (binding) {
        [binding dispatchPlaybackModeChange:mode withData:nil];
    }
}

+ (void) playbackModeChangeForPlayer:(nonnull NSString *) name
                    withPlaybackMode:(nonnull MUXSDKPlaybackMode) mode
            extraEncodedJSONData:(nonnull NSData *) encodedData {
    MUXSDKPlayerBinding *binding = [_bindingsByPlayerName valueForKey:name];
    if (binding) {
        [binding dispatchPlaybackModeChange:mode withData:encodedData];
    }
}

+ (void) playbackModeChangeForPlayer:(nonnull NSString *) name
                    withPlaybackMode:(nonnull MUXSDKPlaybackMode) mode
                       extraData:(nonnull NSDictionary *) extraData {
    NSData *jsonData = nil;
    if ([NSJSONSerialization isValidJSONObject:extraData]) {
        NSError *serializationError = nil;
        jsonData = [NSJSONSerialization dataWithJSONObject:extraData
                                                   options:(NSJSONWritingOptions)0
                                                     error:&serializationError];
        if (serializationError) {
            NSLog(@"Unexpected error while serilzing playback mode JSON: %@", serializationError.localizedDescription);
            return;
        }
    } else {
        NSLog(@"Provided playback_mode_data was not serializeable as JSON");
        return;
    }
    
    [MUXSDKStats playbackModeChangeForPlayer:name withPlaybackMode:mode extraEncodedJSONData:jsonData];
}
    
#pragma mark Error

+ (void)dispatchError:(nonnull NSString *)errorCode
          withMessage:(nonnull NSString *)message
            forPlayer:(nonnull NSString *)name {
    MUXSDKPlayerBinding *player = [_bindingsByPlayerName valueForKey:name];

    if (!player) {
        return;
    }
    [player dispatchError:errorCode 
              withMessage:message];
}

+ (void)dispatchError:(nonnull NSString *)errorCode
          withMessage:(nonnull NSString *)message
         errorContext:(nullable NSString *)errorContext
            forPlayer:(nonnull NSString *)name {
    MUXSDKPlayerBinding *player = [_bindingsByPlayerName valueForKey:name];

    if (!player) {
        return;
    }

    [player dispatchError:errorCode
              withMessage:message
         withErrorContext:errorContext];
}

+ (void)dispatchError:(nonnull NSString *)errorCode
          withMessage:(nonnull NSString *)message
             severity:(MUXSDKErrorSeverity)severity
            forPlayer:(nonnull NSString *)name {
    MUXSDKPlayerBinding *player = [_bindingsByPlayerName valueForKey:name];

    if (!player) {
        return;
    }

    [player dispatchError:errorCode
              withMessage:message
                 severity:severity];
}

+ (void)dispatchError:(nonnull NSString *)errorCode
          withMessage:(nonnull NSString *)message
             severity:(MUXSDKErrorSeverity)severity
         errorContext:(nonnull NSString *)errorContext
            forPlayer:(nonnull NSString *)name {
    MUXSDKPlayerBinding *player = [_bindingsByPlayerName valueForKey:name];

    if (!player) {
        return;
    }

    [player dispatchError:errorCode
              withMessage:message
                 severity:severity
             errorContext:errorContext];
}

+ (void)dispatchError:(nonnull NSString *)errorCode
          withMessage:(nonnull NSString *)message
             severity:(MUXSDKErrorSeverity)severity
  isBusinessException:(BOOL)isBusinessException
            forPlayer:(nonnull NSString *)name {
    MUXSDKPlayerBinding *player = [_bindingsByPlayerName valueForKey:name];

    if (!player) {
        return;
    }

    [player dispatchError:errorCode
              withMessage:message
                 severity:severity
      isBusinessException:isBusinessException];
}

+ (void)dispatchError:(nonnull NSString *)errorCode
          withMessage:(nonnull NSString *)message
             severity:(MUXSDKErrorSeverity)severity
  isBusinessException:(BOOL)isBusinessException
         errorContext:(nonnull NSString *)errorContext
            forPlayer:(nonnull NSString *)name {
    MUXSDKPlayerBinding *player = [_bindingsByPlayerName valueForKey:name];
    
    if (!player) {
        return;
    }

    [player dispatchError:errorCode
              withMessage:message
                 severity:severity
      isBusinessException:isBusinessException
             errorContext:errorContext];
}


@end
