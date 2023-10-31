//
//  MUXSDKMonitor.m
//  

#import "MUXSDKMonitor.h"

#import "MUXSDKPlaceholderViewerData.h"
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

@property (nonatomic, strong) NSMutableDictionary *playerSoftwareNamesByPlayerName;

@property (nonatomic, strong) MUXSDKPlayerBindingManager *playerBindingManager;

@property (nonatomic, strong) MUXSDKPlaceholderViewerData *placeholderViewerData;

@property (nonatomic, strong, nullable) MUXSDKCustomerViewerData *customerViewerData;

@end

@implementation MUXSDKMonitor

#pragma mark - Initialization

- (_Null_unspecified instancetype)init {
    self = [super init];
    if (self) {
        _playerSoftwareNamesByPlayerName = [[NSMutableDictionary alloc] init];
        _playerBindingManager = [[MUXSDKPlayerBindingManager alloc] init];
        _placeholderViewerData = [[MUXSDKPlaceholderViewerData alloc] init];
    }

    return self;
}

+ (nonnull MUXSDKMonitor *)shared {
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

- (nonnull MUXSDKViewerData *)constructViewerDataWith:(nonnull MUXSDKCustomerViewerData *)customerViewerData
                                placeholderViewerData:(nonnull MUXSDKPlaceholderViewerData *)placeholderViewerData {
    MUXSDKViewerData *viewerData = [[MUXSDKViewerData alloc] init];

    if (customerViewerData.viewerApplicationName != nil) {
        [viewerData setViewerApplicationName:customerViewerData.viewerApplicationName];
    } else if ([placeholderViewerData viewerApplicationName] != nil) {
        [viewerData setViewerApplicationName:[placeholderViewerData viewerApplicationName]];
    }

    if ([placeholderViewerData viewerApplicationVersion] != nil) {
        [viewerData setViewerApplicationVersion:[placeholderViewerData viewerApplicationVersion]];
    }

    NSString *viewerDeviceModel = customerViewerData.viewerDeviceModel ?: [placeholderViewerData viewerDeviceModel];
    [viewerData setViewerDeviceModel:viewerDeviceModel];

    NSString *viewerDeviceCategory = customerViewerData.viewerDeviceCategory ?: [placeholderViewerData viewerDeviceCategory];
    [viewerData setViewerDeviceCategory:viewerDeviceCategory];

    NSString *viewerOsFamily = customerViewerData.viewerOsFamily ?: [placeholderViewerData viewerOsFamily];
    [viewerData setViewerOsFamily:viewerOsFamily];

    NSString *viewerOsVersion = customerViewerData.viewerOsVersion ?: [placeholderViewerData viewerOsVersion];
    [viewerData setViewerOsVersion:viewerOsVersion];

    NSString *viewerDeviceManufacturer = customerViewerData.viewerDeviceManufacturer ?: [placeholderViewerData viewerDeviceManufacturer];
    [viewerData setViewerDeviceManufacturer:viewerDeviceManufacturer];

    return viewerData;
}

- (void)dispatchInitialInstanceMonitoringDetailsWithCustomerViewerData:(nullable MUXSDKCustomerViewerData *)customerViewerData {
    MUXSDKDataEvent *dataEvent = [[MUXSDKDataEvent alloc] init];

    MUXSDKEnvironmentData *environmentData = [[MUXSDKEnvironmentData alloc] init];
    [environmentData setMuxViewerId:[self deviceIdentifier]];

    [dataEvent setEnvironmentData:environmentData];

    MUXSDKViewerData *viewerData = [self constructViewerDataWith:customerViewerData
                                           placeholderViewerData:_placeholderViewerData];

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

    NSString *playerSoftwareName = [_playerSoftwareNamesByPlayerName valueForKey:playerName];
    if (playerSoftwareName) {
        // Destroy any previously existing player with this name.
        [self stopMonitoringWithPlayerName:playerName];
    }

    if (playerViewController.player) {
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

        [_playerBindingManager setCustomerData:customerData
                                 forPlayerName:playerName];
        [_playerBindingManager.playerBindings setValue:newBinding forKey:playerName];
        [_playerSoftwareNamesByPlayerName setValue:MUXSDKPlayerSoftwareAVPlayerViewController forKey:playerName];

        [newBinding attachAVPlayer:playerViewController.player];
        [_playerBindingManager dispatchNewViewForPlayerName:playerName];
        return newBinding;
    } else {
        NSLog(@"MUXSDK-ERROR - Mux failed to configure the monitor because AVPlayerViewController.player was NULL for player name: %@", playerName);
        return nil;
    }
}

- (void)updatePlayerViewController:(nonnull AVPlayerViewController *)playerViewController
                    withPlayerName:(nonnull NSString *)playerName {
    [self dispatchInitialInstanceMonitoringDetailsWithCustomerViewerData:_customerViewerData];

    NSString *playerSoftwareName = [_playerSoftwareNamesByPlayerName valueForKey:playerName];
    if (playerSoftwareName) {
        if (!playerViewController.player) {
            NSLog(@"MUXSDK-ERROR - Mux failed to configure the monitor because AVPlayerViewController.player was NULL for player name: %@", playerName);
            return;
        }
        if (playerSoftwareName == MUXSDKPlayerSoftwareAVPlayerViewController) {
            MUXSDKAVPlayerViewControllerBinding *playerViewControllerBinding = [_playerBindingManager.playerBindings valueForKey:playerName];
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

    NSString *playerSoftwareName = [_playerSoftwareNamesByPlayerName valueForKey:playerName];
    if (playerSoftwareName) {
        // Destroy any previously existing player with this playerName.
        [self stopMonitoringWithPlayerName:playerName];
    }
    if (playerLayer.player) {
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


        [_playerBindingManager setCustomerData:customerData
                                 forPlayerName:playerName];
        [_playerBindingManager.playerBindings setValue:newBinding
                            forKey:playerName];
        [_playerSoftwareNamesByPlayerName setValue:MUXSDKPlayerSoftwareAVPlayerLayer 
                     forKey:playerName];

        [newBinding attachAVPlayer:playerLayer.player];
        [_playerBindingManager dispatchNewViewForPlayerName:playerName];
        return newBinding;
    } else {
        NSLog(@"MUXSDK-ERROR - Mux failed to configure the monitor because AVPlayerLayer.player was NULL for player name: %@", playerName);
        return nil;
    }
}

- (void)updatePlayerLayer:(nonnull AVPlayerLayer *)playerLayer
           withPlayerName:(nonnull NSString *)playerName {
    [self dispatchInitialInstanceMonitoringDetailsWithCustomerViewerData:_customerViewerData];

    NSString *playerSoftwareName = [_playerSoftwareNamesByPlayerName valueForKey:playerName];
    if (playerSoftwareName) {
        if (!playerLayer.player) {
            NSLog(@"MUXSDK-ERROR - Mux failed to configure the monitor because AVPlayerLayer.player was NULL for player name: %@", playerName);
            return;
        }
        if (playerSoftwareName == MUXSDKPlayerSoftwareAVPlayerLayer) {
            MUXSDKAVPlayerLayerBinding *playerLayerBinding = [_playerBindingManager.playerBindings valueForKey:playerName];
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

    NSString *existingPlayerSoftwareName = [_playerSoftwareNamesByPlayerName valueForKey:playerName];
    if (existingPlayerSoftwareName) {
        // Destroy any previously existing player with this name.
        [self stopMonitoringWithPlayerName:playerName];
    }

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

    [_playerBindingManager setCustomerData:customerData
                             forPlayerName:playerName];
    [_playerBindingManager.playerBindings setValue:newBinding
                        forKey:playerName];
    [_playerSoftwareNamesByPlayerName setValue:MUXSDKPlayerSoftwareAVPlayer
                 forKey:playerName];

    [newBinding attachAVPlayer:player];
    [_playerBindingManager dispatchNewViewForPlayerName:playerName];
    return newBinding;
}

- (void)updatePlayer:(nonnull AVPlayer *)player
      withPlayerName:(nonnull NSString *)playerName
     fixedPlayerSize:(CGSize)fixedPlayerSize {
    [self dispatchInitialInstanceMonitoringDetailsWithCustomerViewerData:_customerViewerData];

    NSString *playerSoftwareName = [_playerSoftwareNamesByPlayerName valueForKey:playerName];
    if (playerSoftwareName) {
        if (playerSoftwareName == MUXSDKPlayerSoftwareAVPlayer) {
            MUXSDKAVPlayerBinding *playerBinding = [_playerBindingManager.playerBindings valueForKey:playerName];
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
    NSString *playerSoftwareName = [_playerSoftwareNamesByPlayerName valueForKey:playerName];
    if (playerSoftwareName == MUXSDKPlayerSoftwareAVPlayerViewController) {
        MUXSDKAVPlayerViewControllerBinding *player = [_playerBindingManager.playerBindings valueForKey:playerName];
        [player dispatchViewEnd];
        [player detachAVPlayer];
        [_playerBindingManager.playerBindings removeObjectForKey:playerName];
    } else if (playerSoftwareName == MUXSDKPlayerSoftwareAVPlayerLayer) {
        MUXSDKAVPlayerLayerBinding *player = [_playerBindingManager.playerBindings valueForKey:playerName];
        [player dispatchViewEnd];
        [player detachAVPlayer];
        [_playerBindingManager.playerBindings removeObjectForKey:playerName];
    } else if (playerSoftwareName == MUXSDKPlayerSoftwareAVPlayer) {
        MUXSDKAVPlayerBinding *player = [_playerBindingManager.playerBindings valueForKey:playerName];
        [player dispatchViewEnd];
        [player detachAVPlayer];
        [_playerBindingManager.playerBindings removeObjectForKey:playerName];
    }
    [_playerSoftwareNamesByPlayerName removeObjectForKey:playerName];
    [_playerBindingManager removeBindingsForPlayerName:playerName];

}

- (void)stopMonitoringWithPlayerBinding:(nonnull MUXSDKPlayerBinding *)playerBinding {
    NSString *playerName = playerBinding.playerName;
    NSString *playerSoftwareName = [_playerSoftwareNamesByPlayerName valueForKey:playerName];
    if (playerSoftwareName == MUXSDKPlayerSoftwareAVPlayerViewController) {
        MUXSDKAVPlayerViewControllerBinding *player = [_playerBindingManager.playerBindings valueForKey:playerName];
        [player dispatchViewEnd];
        [player detachAVPlayer];
        [_playerBindingManager.playerBindings removeObjectForKey:playerName];
    } else if (playerSoftwareName == MUXSDKPlayerSoftwareAVPlayerLayer) {
        MUXSDKAVPlayerLayerBinding *player = [_playerBindingManager.playerBindings valueForKey:playerName];
        [player dispatchViewEnd];
        [player detachAVPlayer];
        [_playerBindingManager.playerBindings removeObjectForKey:playerName];
    } else if (playerSoftwareName == MUXSDKPlayerSoftwareAVPlayer) {
        MUXSDKAVPlayerBinding *player = [_playerBindingManager.playerBindings valueForKey:playerName];
        [player dispatchViewEnd];
        [player detachAVPlayer];
        [_playerBindingManager.playerBindings removeObjectForKey:playerName];
    }
    [_playerSoftwareNamesByPlayerName removeObjectForKey:playerName];
    [_playerBindingManager removeBindingsForPlayerName:playerName];
}

#pragma mark - Automatic Video Change

- (void)updateAutomaticVideoChangeForPlayerName:(nonnull NSString *)playerName
                                        enabled:(BOOL)enabled {
    MUXSDKPlayerBinding *player = [_playerBindingManager.playerBindings valueForKey:playerName];
    if (player) {
        [player setAutomaticVideoChange:enabled];
    }
}

#pragma mark - Manual Video Change

- (void)signalVideoChangeForPlayerName:(nonnull NSString *)playerName
               withUpdatedCustomerData:(nullable MUXSDKCustomerData *)customerData {
    MUXSDKCustomerPlayerData *playerData = customerData.customerPlayerData ?: [_playerBindingManager.customerPlayerDataStore playerDataForPlayerName:playerName];
    MUXSDKCustomerViewData *viewData = [customerData customerViewData];
    MUXSDKCustomerVideoData *videoData = [customerData customerVideoData];
    MUXSDKCustomData *customData = [customerData customData];

    if (!(videoData || viewData || customData)) {
        NSLog(@"MUXSDK-WARNING - Mux failed to signal a video change because no video, view, and custom data was supplied for new video playing on player name: %@", playerName);
        return;
    }
    MUXSDKPlayerBinding *player = [_playerBindingManager.playerBindings valueForKey:playerName];
    if (player) {
        [player didTriggerManualVideoChange];
        [player dispatchViewEnd];

        // FIXME: Previous implementation did a nil check
        // on playerData, current implementation does not
        [_playerBindingManager setCustomerData:customerData
                                 forPlayerName:playerName];
        [player prepareForAvQueuePlayerNextItem];
    }
}

#pragma mark - Program Change

- (void)signalProgramChangeForPlayerName:(nonnull NSString *)playerName
                 withUpdatedCustomerData:(nullable MUXSDKCustomerData *)customerData {
    [self signalVideoChangeForPlayerName:playerName
                 withUpdatedCustomerData:customerData];
    MUXSDKPlayerBinding *playerBinding = [_playerBindingManager.playerBindings valueForKey:playerName];
    if (playerBinding) {
        [playerBinding programChangedForPlayer];
    }
}

#pragma mark - Customer Data

- (void)updatePlayerName:(nonnull NSString *)playerName
        withCustomerData:(nullable MUXSDKCustomerData *)customerData {
    MUXSDKPlayerBinding *player = [_playerBindingManager.playerBindings valueForKey:playerName];
    if (!player) {
        NSLog(@"MUXSDK-WARNING - Mux failed to update customer data because no player exists with the player name: %@", playerName);
        return;
    }

    MUXSDKCustomerPlayerData *playerData = [customerData customerPlayerData];
    MUXSDKCustomerViewData *viewData = [customerData customerViewData];
    MUXSDKCustomerVideoData *videoData = [customerData customerVideoData];
    MUXSDKCustomData *customData = [customerData customData];

    if (playerData || videoData || viewData || customData) {
        MUXSDKDataEvent *dataEvent = [[MUXSDKDataEvent alloc] init];

        [_playerBindingManager setCustomerData:customerData
                                 forPlayerName:playerName];

        if (playerData) {
            [dataEvent setCustomerPlayerData:playerData];
        }
        if (videoData) {
            [dataEvent setCustomerVideoData:videoData];
        }
        if (viewData) {
            [dataEvent setCustomerViewData:viewData];
        }
        if (customData) {
            [dataEvent setCustomData:customData];
        }

        [MUXSDKCore dispatchEvent:dataEvent
                        forPlayer:playerName];
    }

    // Dispatch global data event if viewer data provided
    MUXSDKCustomerViewerData *customerViewerData = [customerData customerViewerData];
    if (customerViewerData) {
        _customerViewerData = customerViewerData;
        MUXSDKViewerData *viewerData = [self constructViewerDataWith:customerViewerData
                                               placeholderViewerData:_placeholderViewerData];
        MUXSDKDataEvent *dataEvent = [[MUXSDKDataEvent alloc] init];
        [dataEvent setViewerData:viewerData];
        [MUXSDKCore dispatchGlobalDataEvent:dataEvent];
    }
}

#pragma mark - Orientation Change

- (void)signalOrientationChangeForPlayerName:(nonnull NSString *)playerName
                          updatedOrientation:(MUXSDKViewOrientation)orientation {
    MUXSDKPlayerBinding *playerBinding = [_playerBindingManager.playerBindings valueForKey:playerName];
    if (!playerBinding) {
        NSLog(@"MUXSDK-WARNING - Mux failed to update view orientation because no player exists with the player name: %@", playerName);
        return;
    }
    [playerBinding dispatchOrientationChange:orientation];
}

#pragma mark - Error Dispatch

- (void)dispatchErrorForPlayerName:(nonnull NSString *)playerName
                         errorCode:(nonnull NSString *)errorCode
                      errorMessage:(nonnull NSString *)errorMessage {
    MUXSDKPlayerBinding *playerBinding = [_playerBindingManager.playerBindings valueForKey:playerName];
    if (!playerBinding) {
        NSLog(@"MUXSDK-WARNING - Mux failed to dispatch error data because no player exists with the player name: %@", playerName);
        return;
    }
    [playerBinding dispatchError:errorCode
                     withMessage:errorMessage];
}

@end
