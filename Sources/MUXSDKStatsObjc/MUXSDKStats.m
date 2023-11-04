#import "MUXSDKStats.h"
#import "MUXSDKPlayerBinding.h"
#import "MUXSDKMonitor.h"

#if __has_feature(modules)
@import AVFoundation;
@import AVKit;
@import Foundation;
#else
#import <AVKit/AVKit.h>
#import <AVFoundation/AVFoundation.h>
#import <Foundation/Foundation.h>
#endif

@implementation MUXSDKStats

#pragma mark Monitor AVPlayerViewController

+ (nullable MUXSDKPlayerBinding *)monitorAVPlayerViewController:(nonnull AVPlayerViewController *)player
                                                 withPlayerName:(nonnull NSString *)name
                                                   customerData:(nonnull MUXSDKCustomerData *)customerData
                                         automaticErrorTracking:(BOOL)automaticErrorTracking
                                         beaconCollectionDomain:(nullable NSString *)collectionDomain {
    
    return [[MUXSDKMonitor shared] startMonitoringPlayerViewController:player
                                                        withPlayerName:name
                                                          customerData:customerData
                                                automaticErrorTracking:automaticErrorTracking
                                                beaconCollectionDomain:collectionDomain];
}

+ (nullable MUXSDKPlayerBinding *)monitorAVPlayerViewController:(nonnull AVPlayerViewController *)player
                                                 withPlayerName:(nonnull NSString *)name
                                                   customerData:(nonnull MUXSDKCustomerData *)customerData
                                         automaticErrorTracking:(BOOL)automaticErrorTracking {
    return [self monitorAVPlayerViewController:player
                                withPlayerName:name
                                  customerData:customerData
                        automaticErrorTracking:automaticErrorTracking
                        beaconCollectionDomain:nil];
    
}

+ (nullable MUXSDKPlayerBinding *)monitorAVPlayerViewController:(nonnull AVPlayerViewController *)player
                                                 withPlayerName:(nonnull NSString *)name
                                                   customerData:(nonnull MUXSDKCustomerData *)customerData {
    return [self monitorAVPlayerViewController:player
                                withPlayerName:name
                                  customerData:customerData
                        automaticErrorTracking:YES
                        beaconCollectionDomain:nil];
}

+ (void)updateAVPlayerViewController:(nonnull AVPlayerViewController *)player withPlayerName:(nonnull NSString *)name {
    [[MUXSDKMonitor shared] updatePlayerViewController:player
                                        withPlayerName:name];
}

#pragma mark Monitor AVPlayerLayer

+ (nullable MUXSDKPlayerBinding *)monitorAVPlayerLayer:(nonnull AVPlayerLayer *)player
                                        withPlayerName:(nonnull NSString *)name
                                          customerData:(nonnull MUXSDKCustomerData *)customerData
                                automaticErrorTracking:(BOOL)automaticErrorTracking
                                beaconCollectionDomain:(nullable NSString *)collectionDomain {
    return [[MUXSDKMonitor shared] startMonitoringPlayerLayer:player
                                               withPlayerName:name
                                                 customerData:customerData
                                       automaticErrorTracking:automaticErrorTracking
                                       beaconCollectionDomain:collectionDomain];
}

+ (nullable MUXSDKPlayerBinding *)monitorAVPlayerLayer:(nonnull AVPlayerLayer *)player
                                        withPlayerName:(nonnull NSString *)name
                                          customerData:(nonnull MUXSDKCustomerData *)customerData
                                automaticErrorTracking:(BOOL)automaticErrorTracking {
    
    return [self monitorAVPlayerLayer:player
                       withPlayerName:name
                         customerData:customerData
               automaticErrorTracking:automaticErrorTracking
               beaconCollectionDomain:nil];
}

+ (nullable MUXSDKPlayerBinding *)monitorAVPlayerLayer:(nonnull AVPlayerLayer *)player
                                        withPlayerName:(nonnull NSString *)name
                                          customerData:(nonnull MUXSDKCustomerData *)customerData {
    
    return [self monitorAVPlayerLayer:player
                       withPlayerName:name
                         customerData:customerData
               automaticErrorTracking:YES];
}

+ (void)updateAVPlayerLayer:(AVPlayerLayer *)player withPlayerName:(NSString *)name {
    [[MUXSDKMonitor shared] updatePlayerLayer:player
                               withPlayerName:name];
}

#pragma mark Monitor AVPlayer

+ (nullable MUXSDKPlayerBinding *)monitorAVPlayer:(nonnull AVPlayer *)player
                                   withPlayerName:(nonnull NSString *)name
                                  fixedPlayerSize:(CGSize)fixedPlayerSize
                                     customerData:(nonnull MUXSDKCustomerData *)customerData {
    return [self monitorAVPlayer:player
                  withPlayerName:name
                 fixedPlayerSize:fixedPlayerSize
                    customerData:customerData
          automaticErrorTracking:YES
          beaconCollectionDomain:nil];
}

+ (nullable MUXSDKPlayerBinding *)monitorAVPlayer:(nonnull AVPlayer *)player
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

+ (nullable MUXSDKPlayerBinding *)monitorAVPlayer:(nonnull AVPlayer *)player
                                   withPlayerName:(nonnull NSString *)name
                                  fixedPlayerSize:(CGSize)fixedPlayerSize
                                     customerData:(nonnull MUXSDKCustomerData *)customerData
                           automaticErrorTracking:(BOOL)automaticErrorTracking
                           beaconCollectionDomain:(nullable NSString *)collectionDomain {
    return [[MUXSDKMonitor shared] startMonitoringPlayer:player
                                          withPlayerName:name
                                         fixedPlayerSize:fixedPlayerSize
                                            customerData:customerData
                                  automaticErrorTracking:automaticErrorTracking
                                  beaconCollectionDomain:collectionDomain];
}

+ (void)updateAVPlayer:(AVPlayer *)player
        withPlayerName:(NSString *)name
       fixedPlayerSize:(CGSize)fixedPlayerSize {
    [[MUXSDKMonitor shared] updatePlayer:player
                          withPlayerName:name
                         fixedPlayerSize:fixedPlayerSize];
}

#pragma mark Destroy Player

+ (void)destroyPlayer:(NSString *)name {
    [[MUXSDKMonitor shared] stopMonitoringWithPlayerName:name];
}

#pragma mark Video Change

+ (void)videoChangeForPlayer:(nonnull NSString *)name 
            withCustomerData:(nullable MUXSDKCustomerData *)customerData {
    
    [[MUXSDKMonitor shared] signalVideoChangeForPlayerName:name
                                   withUpdatedCustomerData:customerData];
}

#pragma mark Program Change

+ (void)programChangeForPlayer:(nonnull NSString *)name
              withCustomerData:(nullable MUXSDKCustomerData *)customerData {
    [[MUXSDKMonitor shared] signalProgramChangeForPlayerName:name
                                     withUpdatedCustomerData:customerData];
}

+ (void)setAutomaticVideoChange:(NSString *)name
                        enabled:(BOOL)enabled {
    [[MUXSDKMonitor shared] updateAutomaticVideoChangeForPlayerName:name
                                                            enabled:enabled];
}

#pragma mark Update Customer Data

+ (void)setCustomerData:(nullable MUXSDKCustomerData *)customerData 
              forPlayer:(nonnull NSString *)name {
    [[MUXSDKMonitor shared] updatePlayerName:name
                            withCustomerData:customerData];
}

#pragma mark Orientation Change

+ (void)orientationChangeForPlayer:(nonnull NSString *)name
                   withOrientation:(MUXSDKViewOrientation)orientation {
    [[MUXSDKMonitor shared] signalOrientationChangeForPlayerName:name
                                              updatedOrientation:orientation];
}

#pragma mark Error

+ (void)dispatchError:(nonnull NSString *)code 
          withMessage:(nonnull NSString *)message
            forPlayer:(nonnull NSString *)name {
    [[MUXSDKMonitor shared] dispatchErrorForPlayerName:name
                                             errorCode:code
                                          errorMessage:message];
}

@end
