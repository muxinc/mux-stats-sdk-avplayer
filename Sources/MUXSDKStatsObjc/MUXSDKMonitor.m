//
//  MUXSDKMonitor.m
//  

#import "MUXSDKMonitor.h"

#import "MUXSDKPlayerBindingManager.h"

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
@property (nonatomic, strong) MUXSDKCustomerViewerData *customerViewerData;

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

        // TODO: Should NOT be in the init, gets called at
        // each monitor call

        // TODO: Tests

        // Provide EnvironmentData and ViewerData to Core.

        NSString *uuid = [[NSUserDefaults standardUserDefaults] stringForKey:@"MUX_DEVICE_ID"];
        if (uuid == nil) {
            uuid = [[NSUUID UUID] UUIDString];
            [[NSUserDefaults standardUserDefaults] setObject:uuid 
                                                      forKey:@"MUX_DEVICE_ID"];
        }

        MUXSDKEnvironmentData *environmentData = [[MUXSDKEnvironmentData alloc] init];
        [environmentData setMuxViewerId:uuid];

        MUXSDKViewerData *viewerData = [[MUXSDKViewerData alloc] init];

        NSString *applicationName = [_customerViewerData viewerApplicationName];
        if (applicationName == nil) {
            applicationName = [[NSBundle mainBundle] bundleIdentifier];
        }
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
            default:
                break;
        }

        // Detected values for device metadata
        [viewerData setMuxViewerDeviceModel:systemDeviceModel];
        [viewerData setMuxViewerDeviceCategory:systemDeviceCategory];
        [viewerData setMuxViewerOsFamily:systemOsFamily];
        [viewerData setMuxViewerOsVersion:systemOsVersion];
        [viewerData setMuxViewerDeviceManufacturer:@"Apple"];

        // Overridden values for device metadata
        if(_customerViewerData.viewerDeviceModel) {
            [viewerData setViewerDeviceModel:_customerViewerData.viewerDeviceModel];
        }
        if(_customerViewerData.viewerDeviceCategory) {
            [viewerData setViewerDeviceCategory:_customerViewerData.viewerDeviceCategory];
        }
        if(_customerViewerData.viewerOsFamily) {
            [viewerData setViewerOsFamily:_customerViewerData.viewerOsFamily];
        }
        if(_customerViewerData.viewerOsVersion) {
            [viewerData setViewerOsVersion:_customerViewerData.viewerOsVersion];
        }
        if(_customerViewerData.viewerDeviceManufacturer) {
            [viewerData setViewerDeviceManufacturer:_customerViewerData.viewerDeviceManufacturer];
        }

        MUXSDKDataEvent *dataEvent = [[MUXSDKDataEvent alloc] init];
        [dataEvent setEnvironmentData:environmentData];
        [dataEvent setViewerData:viewerData];
        [MUXSDKCore dispatchGlobalDataEvent:dataEvent];
    }

    return self;
}

+ (instancetype)sharedMonitor {
    static MUXSDKMonitor *sharedMonitor = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedMonitor = [[MUXSDKMonitor alloc] init];
    });
}

#pragma mark - SDK Metadata

- (nonnull NSString *)pluginVersion {
    // TODO: Move MUXSDKPluginVersion to its own header
//    return MUXSDKPluginVersion;
    return @"4.0.0";;
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
    return nil;
}

- (void)updatePlayerViewController:(nonnull AVPlayerViewController *)playerViewController
                    withPlayerName:(nonnull NSString *)playerName {
    
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
    return nil;
}

- (void)updatePlayerLayer:(nonnull AVPlayerLayer *)playerLayer
           withPlayerName:(nonnull NSString *)name {
    
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
    return nil;
}

- (void)updatePlayer:(nonnull AVPlayer *)player
      withPlayerName:(nonnull NSString *)playerName
     fixedPlayerSize:(CGSize)fixedPlayerSize {
    
}

#pragma mark - Stop Monitoring

- (void)stopMonitoringWithPlayerName:(nonnull NSString *)playerName {
    
}

- (void)stopMonitoringWithPlayerBinding:(nonnull MUXSDKPlayerBinding *)playerBinding {
    
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
