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
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (void)updatePlayerViewController:(nonnull AVPlayerViewController *)playerViewController
                    withPlayerName:(nonnull NSString *)playerName {
    [self doesNotRecognizeSelector:_cmd];
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
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (void)updatePlayerLayer:(nonnull AVPlayerLayer *)playerLayer
           withPlayerName:(nonnull NSString *)playerName {
    [self doesNotRecognizeSelector:_cmd];
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
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (void)updatePlayer:(nonnull AVPlayer *)player
      withPlayerName:(nonnull NSString *)playerName
     fixedPlayerSize:(CGSize)fixedPlayerSize {
    [self doesNotRecognizeSelector:_cmd];
}

#pragma mark - Stop Monitoring

- (void)stopMonitoringWithPlayerName:(nonnull NSString *)playerName {
    [self doesNotRecognizeSelector:_cmd];
}

- (void)stopMonitoringWithPlayerBinding:(nonnull MUXSDKPlayerBinding *)playerBinding {
    [self doesNotRecognizeSelector:_cmd];
}

#pragma mark - Automatic Video Change

- (void)updateAutomaticVideoChangeForPlayerName:(nonnull NSString *)playerName
                                        enabled:(BOOL)enabled {
    [self doesNotRecognizeSelector:_cmd];
}

#pragma mark - Manual Video Change

- (void)signalVideoChangeForPlayerName:(nonnull NSString *)playerName
               withUpdatedCustomerData:(nullable MUXSDKCustomerData *)customerData {
    [self doesNotRecognizeSelector:_cmd];
}

#pragma mark - Program Change

- (void)signalProgramChangeForPlayerName:(nonnull NSString *)playerName
                 withUpdatedCustomerData:(nullable MUXSDKCustomerData *)customerData {
    [self doesNotRecognizeSelector:_cmd];
}

#pragma mark - Customer Data

- (void)updatePlayerName:(nonnull NSString *)playerName
        withCustomerData:(nullable MUXSDKCustomerData *)customerData {
    [self doesNotRecognizeSelector:_cmd];
}

#pragma mark - Orientation Change

- (void)signalOrientationChangeForPlayerName:(nonnull NSString *)playerName
                          updatedOrientation:(MUXSDKViewOrientation)orientation {
    [self doesNotRecognizeSelector:_cmd];
}

#pragma mark - Error Dispatch

- (void)dispatchErrorForPlayerName:(nonnull NSString *)playerName
                         errorCode:(nonnull NSString *)errorCode
                      errorMessage:(nonnull NSString *)errorMessage {
    [self doesNotRecognizeSelector:_cmd];
}

@end
