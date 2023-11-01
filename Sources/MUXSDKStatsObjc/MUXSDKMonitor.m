//
//  MUXSDKMonitor.m
//  

#import "MUXSDKMonitor.h"

#import "MUXSDKPlayerBindingManager.h"
#import "MUXSDKConstants.h"

#if __has_feature(modules)
@import AVFoundation;
@import AVKit;
@import MuxCore;
#else
#import <AVKit/AVKit.h>
#import <AVFoundation/AVFoundation.h>
#if TVOS
#import <MuxCore/MuxCoreTv.h>
#else
#import <MuxCore/MuxCore.h>
#endif
#endif

#import <sys/utsname.h>

@interface MUXSDKMonitor ()

- (_Null_unspecified instancetype)init;

@property (nonatomic, strong) NSMutableDictionary *bindings;
@property (nonatomic, strong) NSMutableDictionary *viewControllers;

@property (nonatomic, strong) MUXSDKPlayerBindingManager *playerBindingManager;

@property (nonatomic, strong) MUXSDKCustomerPlayerDataStore *customerPlayerDataStore;
@property (nonatomic, strong) MUXSDKCustomerVideoDataStore *customerVideoDataStore;
@property (nonatomic, strong) MUXSDKCustomerViewDataStore *customerViewDataStore;
@property (nonatomic, strong) MUXSDKCustomerCustomDataStore *customerCustomDataStore;
@property (nonatomic, strong, nullable) MUXSDKCustomerViewerData *customerViewerData;

@end

@implementation MUXSDKMonitor

#pragma mark - Initialization

- (_Null_unspecified instancetype)init {
    self = [super init];
    if (self) {
        _bindings = [[NSMutableDictionary alloc] init];
        _viewControllers = [[NSMutableDictionary alloc] init];

        _customerPlayerDataStore = [[MUXSDKCustomerPlayerDataStore alloc] init];
        _customerVideoDataStore = [[MUXSDKCustomerVideoDataStore alloc] init];
        _customerViewDataStore = [[MUXSDKCustomerViewDataStore alloc] init];
        _customerCustomDataStore = [[MUXSDKCustomerCustomDataStore alloc] init];

        _playerBindingManager = [[MUXSDKPlayerBindingManager alloc] init];
        _playerBindingManager.customerPlayerDataStore = _customerPlayerDataStore;
        _playerBindingManager.customerVideoDataStore = _customerVideoDataStore;
        _playerBindingManager.customerViewDataStore = _customerViewDataStore;
        _playerBindingManager.customerCustomDataStore = _customerCustomDataStore;
        _playerBindingManager.viewControllers = _viewControllers;
    }

    return self;
}

+ (instancetype)sharedMonitor {
    static MUXSDKMonitor *sharedMonitor = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedMonitor = [[MUXSDKMonitor alloc] init];
    });
    return sharedMonitor;
}

#pragma mark - SDK Metadata

- (nonnull NSString *)pluginVersion {
    return MUXSDKPluginVersion;
}

- (nonnull NSString *)deviceIdentifier {
    NSString *deviceIdentifier = [[NSUserDefaults standardUserDefaults] stringForKey:@"MUX_DEVICE_ID"];

    if (deviceIdentifier == nil) {
        deviceIdentifier = [[NSUUID UUID] UUIDString];
        [[NSUserDefaults standardUserDefaults] setObject:deviceIdentifier
                                                  forKey:@"MUX_DEVICE_ID"];
    }

    return deviceIdentifier;
}

- (nullable NSString *)viewerApplicationVersion {
    NSString *bundleShortVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    NSString *bundleVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
    if (bundleShortVersion && bundleVersion) {
        NSString *fullVersion = [NSString stringWithFormat:@"%@ (%@)", bundleShortVersion, bundleVersion];
        return fullVersion;
    } else if (bundleShortVersion) {
        return bundleShortVersion;
    } else if (bundleVersion) {
        return bundleVersion;
    } else {
        return nil;
    }
}

- (nonnull NSString *)viewerDeviceModel {
    struct utsname systemInfo;
    uname(&systemInfo);
    NSString *systemDeviceModel = [NSString stringWithCString:systemInfo.machine
                                                     encoding:NSUTF8StringEncoding];
}

- (nonnull NSString *)viewerDeviceCategory {
    NSString *systemDeviceCategory = @"unknown";

    switch ([[UIDevice currentDevice] userInterfaceIdiom]) {
        case UIUserInterfaceIdiomTV:
            systemDeviceCategory = @"tv";
            break;
        case UIUserInterfaceIdiomPad:
            systemDeviceCategory = @"tablet";
            break;
        case UIUserInterfaceIdiomPhone:
            systemDeviceCategory = @"phone";
            break;
        case UIUserInterfaceIdiomCarPlay:
            systemDeviceCategory = @"car";
            break;
        default:
            break;
    }

    return systemDeviceCategory;
}

- (nonnull NSString *)viewerOsFamily {
    NSString *systemOsFamily = @"unknown";

    switch ([[UIDevice currentDevice] userInterfaceIdiom]) {
        case UIUserInterfaceIdiomTV:
            systemOsFamily = @"tvOS";
            break;
        case UIUserInterfaceIdiomPad:
            // FIXME: This should be iPadOS, keeping iOS for
            // consistency across versions
            systemOsFamily = @"iOS";
            break;
        case UIUserInterfaceIdiomPhone:
            systemOsFamily = @"iOS";
            break;
        case UIUserInterfaceIdiomCarPlay:
            systemOsFamily = @"CarPlay";
            break;
        default:
            break;
    }

    return systemOsFamily;
}

- (nonnull NSString *)viewerOsVersion {
    return [[UIDevice currentDevice] systemVersion];
}

- (nonnull NSString *)viewerDeviceManufacturer {
    return @"Apple";
}

#pragma mark - Internal Methods

- (void)configureBeaconCollectionDomain:(nullable NSString *)beaconCollectionDomain
                         forPlayerName:(nonnull NSString *)playerName {
    if (beaconCollectionDomain != nil && beaconCollectionDomain.length > 0) {
        [MUXSDKCore setBeaconCollectionDomain:beaconCollectionDomain
                                    forPlayer:playerName];
    }
}

- (void)configureDeviceID:(nonnull NSString *)deviceID
           forPlayerName:(nonnull NSString *)playerName {
    [MUXSDKCore setDeviceId:deviceID
                  forPlayer:playerName];
}

- (void)dispatchInitialInstanceMonitoringDetailsWithCustomerViewerData:(nullable MUXSDKCustomerViewerData *)customerViewerData {
    MUXSDKDataEvent *dataEvent = [[MUXSDKDataEvent alloc] init];

    MUXSDKEnvironmentData *environmentData = [[MUXSDKEnvironmentData alloc] init];
    [environmentData setMuxViewerId:[self deviceIdentifier]];

    [dataEvent setEnvironmentData:environmentData];

    MUXSDKViewerData *viewerData = [[MUXSDKViewerData alloc] init];

    if (customerViewerData.viewerApplicationName != nil) {
        [viewerData setViewerApplicationName:customerViewerData.viewerApplicationName];
    } else if ([[NSBundle mainBundle] bundleIdentifier] != nil) {
        [viewerData setViewerApplicationName:[[NSBundle mainBundle] bundleIdentifier]];
    }

    if ([self viewerApplicationVersion] != nil) {
        [viewerData setViewerApplicationVersion:[self viewerApplicationVersion]];
    }

    NSString *viewerDeviceModel = customerViewerData.viewerDeviceModel ?: [self viewerDeviceModel];
    [viewerData setViewerDeviceModel:viewerDeviceModel];

    NSString *viewerDeviceCategory = customerViewerData.viewerDeviceCategory ?: [self viewerDeviceCategory];
    [viewerData setViewerDeviceCategory:viewerDeviceCategory];

    NSString *viewerOsFamily = customerViewerData.viewerOsFamily ?: [self viewerOsFamily];
    [viewerData setViewerOsFamily:viewerOsFamily];

    NSString *viewerOsVersion = customerViewerData.viewerOsVersion ?: [self viewerOsVersion];
    [viewerData setViewerOsVersion:viewerOsVersion];

    NSString *viewerDeviceManufacturer = customerViewerData.viewerDeviceManufacturer ?: [self viewerDeviceManufacturer];
    [viewerData setViewerDeviceManufacturer:viewerDeviceManufacturer];

    [dataEvent setViewerData:viewerData];

    [MUXSDKCore dispatchGlobalDataEvent:dataEvent];
}

#pragma mark - Start Monitoring AVPlayerViewController

- (nullable MUXSDKPlayerBinding *)startMonitoringPlayerViewController:(nonnull AVPlayerViewController *)playerViewController
                                                       withPlayerName:(nonnull NSString *)playerName
                                                         customerData:(nonnull MUXSDKCustomerData *)customerData {
    return [self startMonitoringPlayerViewController:playerViewController
                                      withPlayerName:playerName
                                        customerData:customerData
                              automaticErrorTracking:YES
                              beaconCollectionDomain:nil];
}

- (nullable MUXSDKPlayerBinding *)startMonitoringPlayerViewController:(nonnull AVPlayerViewController *)playerViewController
                                                       withPlayerName:(nonnull NSString *)playerName
                                                         customerData:(nonnull MUXSDKCustomerData *)customerData
                                               automaticErrorTracking:(BOOL)automaticErrorTracking {
    return [self startMonitoringPlayerViewController:playerViewController
                                      withPlayerName:playerName
                                        customerData:customerData
                              automaticErrorTracking:automaticErrorTracking
                              beaconCollectionDomain:nil];
}

- (nullable MUXSDKPlayerBinding *)startMonitoringPlayerViewController:(nonnull AVPlayerViewController *)playerViewController
                                                       withPlayerName:(nonnull NSString *)playerName
                                                         customerData:(nonnull MUXSDKCustomerData *)customerData
                                               automaticErrorTracking:(BOOL)automaticErrorTracking
                                               beaconCollectionDomain:(nullable NSString *)beaconCollectionDomain {

    MUXSDKCustomerViewerData *customerViewerData = customerData.customerViewerData ?: _customerViewerData;
    [self dispatchInitialInstanceMonitoringDetailsWithCustomerViewerData:customerViewerData];

    NSString *binding = [_bindings valueForKey:playerName];
    if (binding) {
        // Destroy any previously existing player with this name.
        [self stopMonitoringWithPlayerName:playerName];
    }

    if (playerViewController.player) {
        MUXSDKCustomerPlayerData *playerData = customerData.customerPlayerData;
        MUXSDKCustomerVideoData *videoData = customerData.customerVideoData;
        MUXSDKCustomerViewData *viewData = customerData.customerViewData;
        MUXSDKCustomData *customData = customerData.customData;

        // If customerData sets a custom playerSoftwareName use that
        // If customerData playerSoftwareName is nil, use a default value
        NSString *playerSoftwareName = customerData.customerPlayerData.playerSoftwareName ?: MUXSDKPlayerSoftwareAVPlayerViewController;
        // MUXSDKStats sets a nil for playerSoftwareVersion by default
        // If customerData playerSoftware version is set, pass that along
        // If unset, it is nil and this keeps the existing behavior as the fallback
        NSString *playerSoftwareVersion = customerData.customerPlayerData.playerSoftwareVersion;
        MUXSDKAVPlayerViewControllerBinding *newBinding = [[MUXSDKAVPlayerViewControllerBinding alloc] initWithPlayerName:playerName
                                                                                                             softwareName:playerSoftwareName
                                                                                                          softwareVersion:playerSoftwareVersion
                                                                                                     playerViewController:playerViewController];
        [newBinding setAutomaticErrorTracking:automaticErrorTracking];
        newBinding.playDispatchDelegate = _playerBindingManager;

        [self configureBeaconCollectionDomain:beaconCollectionDomain
                               forPlayerName:playerName];
        [self configureDeviceID:[self deviceIdentifier]
                  forPlayerName:playerName];

        [_customerPlayerDataStore setPlayerData:playerData forPlayerName:playerName];
        if (videoData) {
            [_customerVideoDataStore setVideoData:videoData forPlayerName:playerName];
        }
        if (viewData) {
            [_customerViewDataStore setViewData:viewData forPlayerName:playerName];
        }
        if (customData) {
            [_customerCustomDataStore setCustomData:customData forPlayerName:playerName];
        }
        [_viewControllers setValue:newBinding forKey:playerName];
        [_bindings setValue:MUXSDKPlayerSoftwareAVPlayerViewController forKey:playerName];

        [newBinding attachAVPlayer:playerViewController.player];
        [_playerBindingManager newViewForPlayer:playerName];
        return newBinding;
    } else {
        NSLog(@"MUXSDK-ERROR - Mux failed to configure the monitor because AVPlayerViewController.player was NULL for player name: %@", playerName);
        return nil;
    }
}

- (void)updatePlayerViewController:(nonnull AVPlayerViewController *)playerViewController
                    withPlayerName:(nonnull NSString *)playerName {
    [self dispatchInitialInstanceMonitoringDetailsWithCustomerViewerData:_customerViewerData];

    NSString *binding = [_bindings valueForKey:playerName];
    if (binding) {
        if (!playerViewController.player) {
            NSLog(@"MUXSDK-ERROR - Mux failed to configure the monitor because AVPlayerViewController.player was NULL for player name: %@", playerName);
            return;
        }
        if (binding == MUXSDKPlayerSoftwareAVPlayerViewController) {
            MUXSDKAVPlayerViewControllerBinding *playerViewControllerBinding = [_viewControllers valueForKey:playerName];
            [playerViewControllerBinding detachAVPlayer];
            [playerViewControllerBinding attachAVPlayer:playerViewController.player];
        } else {
            NSLog(@"MUXSDK-ERROR - Mux failed to update the monitor because the previous player with name %@ was not set up via monitorAVPlayerViewController", playerName);
        }
    } else {
        NSLog(@"MUXSDK-ERROR - Mux failed to update the monitor because no player exists with the player name: %@", playerName);
    }

}

#pragma mark - Start Monitoring AVPlayerLayer

- (nullable MUXSDKPlayerBinding *)startMonitoringPlayerLayer:(nonnull AVPlayerLayer *)playerLayer
                                              withPlayerName:(nonnull NSString *)playerName
                                                customerData:(nonnull MUXSDKCustomerData *)customerData {
    return [self startMonitoringPlayerLayer:playerLayer
                             withPlayerName:playerName
                               customerData:customerData
                     automaticErrorTracking:YES
                     beaconCollectionDomain:nil];
}

- (nullable MUXSDKPlayerBinding *)startMonitoringPlayerLayer:(nonnull AVPlayerLayer *)playerLayer
                                              withPlayerName:(nonnull NSString *)playerName
                                                customerData:(nonnull MUXSDKCustomerData *)customerData
                                      automaticErrorTracking:(BOOL)automaticErrorTracking {
    return [self startMonitoringPlayerLayer:playerLayer
                             withPlayerName:playerName
                               customerData:customerData
                     automaticErrorTracking:automaticErrorTracking
                     beaconCollectionDomain:nil];
}

- (nullable MUXSDKPlayerBinding *)startMonitoringPlayerLayer:(nonnull AVPlayerLayer *)playerLayer
                                              withPlayerName:(nonnull NSString *)playerName
                                                customerData:(nonnull MUXSDKCustomerData *)customerData
                                      automaticErrorTracking:(BOOL)automaticErrorTracking
                                      beaconCollectionDomain:(nullable NSString *)beaconCollectionDomain {
    MUXSDKCustomerViewerData *customerViewerData = customerData.customerViewerData ?: _customerViewerData;
    [self dispatchInitialInstanceMonitoringDetailsWithCustomerViewerData:customerViewerData];

    NSString *binding = [_bindings valueForKey:playerName];
    if (binding) {
        // Destroy any previously existing player with this playerName.
        [self stopMonitoringWithPlayerName:playerName];
    }
    if (playerLayer.player) {
        MUXSDKCustomerPlayerData *playerData = customerData.customerPlayerData;
        MUXSDKCustomerVideoData *videoData = customerData.customerVideoData;
        MUXSDKCustomerViewData *viewData = customerData.customerViewData;
        MUXSDKCustomData *customData = customerData.customData;

        // If customerData sets a custom playerSoftwareName use that
        // If customerData playerSoftwareName is nil, use a default value
        NSString *playerSoftwareName = customerData.customerPlayerData.playerSoftwareName ?: MUXSDKPlayerSoftwareAVPlayerLayer;
        // MUXSDKStats sets a nil for playerSoftwareVersion by default
        // If customerData playerSoftware version is set, pass that along
        // If unset, it is nil and this keeps the existing behavior as the fallback
        NSString *playerSoftwareVersion = customerData.customerPlayerData.playerSoftwareVersion;
        MUXSDKAVPlayerLayerBinding *newBinding = [[MUXSDKAVPlayerLayerBinding alloc] initWithPlayerName:playerName
                                                                                           softwareName:playerSoftwareName
                                                                                        softwareVersion:playerSoftwareVersion
                                                                                            playerLayer:playerLayer];
        newBinding.playDispatchDelegate = _playerBindingManager;
        [newBinding setAutomaticErrorTracking:automaticErrorTracking];
        [self configureBeaconCollectionDomain:beaconCollectionDomain
                               forPlayerName:playerName];
        [self configureDeviceID:[self deviceIdentifier]
                  forPlayerName:playerName];


        [_customerPlayerDataStore setPlayerData:playerData 
                                  forPlayerName:playerName];
        if (videoData) {
            [_customerVideoDataStore setVideoData:videoData 
                                    forPlayerName:playerName];
        }
        if (viewData) {
            [_customerViewDataStore setViewData:viewData 
                                  forPlayerName:playerName];
        }
        if (customData) {
            [_customerCustomDataStore setCustomData:customData 
                                      forPlayerName:playerName];
        }
        [_viewControllers setValue:newBinding 
                            forKey:playerName];
        [_bindings setValue:MUXSDKPlayerSoftwareAVPlayerLayer 
                     forKey:playerName];

        [newBinding attachAVPlayer:playerLayer.player];
        [_playerBindingManager newViewForPlayer:playerName];
        return newBinding;
    } else {
        NSLog(@"MUXSDK-ERROR - Mux failed to configure the monitor because AVPlayerLayer.player was NULL for player name: %@", playerName);
        return nil;
    }
}

- (void)updatePlayerLayer:(nonnull AVPlayerLayer *)playerLayer
           withPlayerName:(nonnull NSString *)playerName {
    [self dispatchInitialInstanceMonitoringDetailsWithCustomerViewerData:_customerViewerData];

    NSString *binding = [_bindings valueForKey:playerName];
    if (binding) {
        if (!playerLayer.player) {
            NSLog(@"MUXSDK-ERROR - Mux failed to configure the monitor because AVPlayerLayer.player was NULL for player name: %@", playerName);
            return;
        }
        if (binding == MUXSDKPlayerSoftwareAVPlayerLayer) {
            MUXSDKAVPlayerLayerBinding *playerLayerBinding = [_viewControllers valueForKey:playerName];
            [playerLayerBinding detachAVPlayer];
            [playerLayerBinding attachAVPlayer:playerLayer.player];
        } else {
            NSLog(@"MUXSDK-ERROR - Mux failed to update the monitor because the previous player with name %@ was not set up via monitorAVPlayerLayer", playerName);
        }
    } else {
        NSLog(@"MUXSDK-ERROR - Mux failed to update the monitor because no player exists with the player name: %@", playerName);
    }
}

#pragma mark - Start Monitoring AVPlayer

- (nullable MUXSDKPlayerBinding *)startMonitoringPlayer:(nonnull AVPlayer *)player
                                         withPlayerName:(nonnull NSString *)playerName
                                        fixedPlayerSize:(CGSize)fixedPlayerSize
                                           customerData:(nonnull MUXSDKCustomerData *)customerData {
    return [self startMonitoringPlayer:player
                        withPlayerName:playerName
                       fixedPlayerSize:fixedPlayerSize
                          customerData:customerData
                automaticErrorTracking:YES
                beaconCollectionDomain:nil];
}

- (nullable MUXSDKPlayerBinding *)startMonitoringPlayer:(nonnull AVPlayer *)player
                                         withPlayerName:(nonnull NSString *)playerName
                                        fixedPlayerSize:(CGSize)fixedPlayerSize
                                           customerData:(nonnull MUXSDKCustomerData *)customerData
                                 automaticErrorTracking:(BOOL)automaticErrorTracking {
    return [self startMonitoringPlayer:player
                        withPlayerName:playerName
                       fixedPlayerSize:fixedPlayerSize
                          customerData:customerData
                automaticErrorTracking:automaticErrorTracking
                beaconCollectionDomain:nil];
}

- (nullable MUXSDKPlayerBinding *)startMonitoringPlayer:(nonnull AVPlayer *)player
                                         withPlayerName:(nonnull NSString *)playerName
                                        fixedPlayerSize:(CGSize)fixedPlayerSize
                                           customerData:(nonnull MUXSDKCustomerData *)customerData
                                 automaticErrorTracking:(BOOL)automaticErrorTracking
                                 beaconCollectionDomain:(nullable NSString *)beaconCollectionDomain {
    MUXSDKCustomerViewerData *customerViewerData = customerData.customerViewerData ?: _customerViewerData;
    [self dispatchInitialInstanceMonitoringDetailsWithCustomerViewerData:customerViewerData];

    NSString *binding = [_bindings valueForKey:playerName];
    if (binding) {
        // Destroy any previously existing player with this name.
        [self stopMonitoringWithPlayerName:playerName];
    }

    MUXSDKCustomerPlayerData *playerData = customerData.customerPlayerData;
    MUXSDKCustomerVideoData *videoData = customerData.customerVideoData;
    MUXSDKCustomerViewData *viewData = customerData.customerViewData;
    MUXSDKCustomData *customData = customerData.customData;

    // If customerData sets a custom playerSoftwareName use that
    // If customerData playerSoftwareName is nil, use a default value
    NSString *playerSoftwareName = customerData.customerPlayerData.playerSoftwareName ?: MUXSDKPlayerSoftwareAVPlayer;
    // MUXSDKStats sets nil for playerSoftwareVersion by default
    // If customerData playerSoftwareVersion is set, pass that along
    // If unset, it is nil and this keeps the existing behavior as the fallback
    NSString *playerSoftwareVersion = customerData.customerPlayerData.playerSoftwareVersion;
    MUXSDKAVPlayerBinding *newBinding = [[MUXSDKAVPlayerBinding alloc] initWithPlayerName:playerName
                                                                             softwareName:playerSoftwareName
                                                                          softwareVersion:playerSoftwareVersion
                                                                          fixedPlayerSize:fixedPlayerSize];
    [newBinding setAutomaticErrorTracking:automaticErrorTracking];
    newBinding.playDispatchDelegate = _playerBindingManager;

    [self configureBeaconCollectionDomain:beaconCollectionDomain
                           forPlayerName:playerName];
    [self configureDeviceID:[self deviceIdentifier]
              forPlayerName:playerName];

    [_customerPlayerDataStore setPlayerData:playerData 
                              forPlayerName:playerName];
    if (videoData) {
        [_customerVideoDataStore setVideoData:videoData 
                                forPlayerName:playerName];
    }
    if (viewData) {
        [_customerViewDataStore setViewData:viewData 
                              forPlayerName:playerName];
    }
    if (customData) {
        [_customerCustomDataStore setCustomData:customData 
                                  forPlayerName:playerName];
    }
    [_viewControllers setValue:newBinding 
                        forKey:playerName];
    [_bindings setValue:MUXSDKPlayerSoftwareAVPlayer
                 forKey:playerName];

    [newBinding attachAVPlayer:player];
    [_playerBindingManager newViewForPlayer:playerName];
    return newBinding;
}

- (void)updatePlayer:(nonnull AVPlayer *)player
      withPlayerName:(nonnull NSString *)playerName
     fixedPlayerSize:(CGSize)fixedPlayerSize {
    [self dispatchInitialInstanceMonitoringDetailsWithCustomerViewerData:_customerViewerData];

    NSString *binding = [_bindings valueForKey:playerName];
    if (binding) {
        if (binding == MUXSDKPlayerSoftwareAVPlayer) {
            MUXSDKAVPlayerBinding *playerBinding = [_viewControllers valueForKey:playerName];
            [playerBinding detachAVPlayer];
            [playerBinding attachAVPlayer:player];
        } else {
            NSLog(@"MUXSDK-ERROR - Mux failed to update the monitor because the previous player with name %@ was not set up via monitorAVPlayer", playerName);
        }
    } else {
        NSLog(@"MUXSDK-ERROR - Mux failed to update the monitor because no player exists with the player name: %@", playerName);
    }
}

#pragma mark - Stop Monitoring

- (void)stopMonitoringWithPlayerName:(nonnull NSString *)playerName {
    NSString *binding = [_bindings valueForKey:playerName];
    if (binding == MUXSDKPlayerSoftwareAVPlayerViewController) {
        MUXSDKAVPlayerViewControllerBinding *player = [_viewControllers valueForKey:playerName];
        [player dispatchViewEnd];
        [player detachAVPlayer];
        [_viewControllers removeObjectForKey:playerName];
    } else if (binding == MUXSDKPlayerSoftwareAVPlayerLayer) {
        MUXSDKAVPlayerLayerBinding *player = [_viewControllers valueForKey:playerName];
        [player dispatchViewEnd];
        [player detachAVPlayer];
        [_viewControllers removeObjectForKey:playerName];
    } else if (binding == MUXSDKPlayerSoftwareAVPlayer) {
        MUXSDKAVPlayerBinding *player = [_viewControllers valueForKey:playerName];
        [player dispatchViewEnd];
        [player detachAVPlayer];
        [_viewControllers removeObjectForKey:playerName];
    }
    [_bindings removeObjectForKey:playerName];
    [_playerBindingManager onPlayerDestroyed:playerName];

}

- (void)stopMonitoringWithPlayerBinding:(nonnull MUXSDKPlayerBinding *)playerBinding {
    NSString *playerName = playerBinding.playerName;
    NSString *binding = [_bindings valueForKey:playerName];
    if (binding == MUXSDKPlayerSoftwareAVPlayerViewController) {
        MUXSDKAVPlayerViewControllerBinding *player = [_viewControllers valueForKey:playerName];
        [player dispatchViewEnd];
        [player detachAVPlayer];
        [_viewControllers removeObjectForKey:playerName];
    } else if (binding == MUXSDKPlayerSoftwareAVPlayerLayer) {
        MUXSDKAVPlayerLayerBinding *player = [_viewControllers valueForKey:playerName];
        [player dispatchViewEnd];
        [player detachAVPlayer];
        [_viewControllers removeObjectForKey:playerName];
    } else if (binding == MUXSDKPlayerSoftwareAVPlayer) {
        MUXSDKAVPlayerBinding *player = [_viewControllers valueForKey:playerName];
        [player dispatchViewEnd];
        [player detachAVPlayer];
        [_viewControllers removeObjectForKey:playerName];
    }
    [_bindings removeObjectForKey:playerName];
    [_playerBindingManager onPlayerDestroyed:playerName];
}

#pragma mark - Automatic Video Change

- (void)enableAutomaticVideoChangeDetectionForPlayerName:(nonnull NSString *)playerName {
    
}

- (void)disableAutomaticVideoChangeDetectionForPlayerName:(nonnull NSString *)playerName {
    
}

#pragma mark - Manual Video Change

- (void)signalVideoChangeForPlayerName:(nonnull NSString *)playerName
               withUpdatedCustomerData:(nullable MUXSDKCustomerData *)customerData {
    
}

#pragma mark - Program Change

- (void)signalProgramChangeForPlayerName:(nonnull NSString *)playerName
                 withUpdatedCustomerData:(nullable MUXSDKCustomerData *)customerData {
    
}

#pragma mark - Customer Data

- (void)updatePlayerName:(nonnull NSString *)playerName
        withCustomerData:(nullable MUXSDKCustomerData *)customerData {
    
}

#pragma mark - Orientation Change

- (void)signalOrientationChangeForPlayerName:(nonnull NSString *)playerName
                          updatedOrientation:(MUXSDKViewOrientation)orientation {
    
}

#pragma mark - Error Dispatch

- (void)dispatchErrorForPlayerName:(nonnull NSString *)playerName
                         errorCode:(nonnull NSString *)errorCode
                      errorMessage:(nonnull NSString *)errorMessage {

}

@end
