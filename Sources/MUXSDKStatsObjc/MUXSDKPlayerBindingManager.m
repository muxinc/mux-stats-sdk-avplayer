//
//  MUXSDKPlayerBindingManager.m
//  MUXSDKStats
//
//  Created by Nidhi Kulkarni on 1/30/20.
//  Copyright © 2020 Mux, Inc. All rights reserved.
//

#import "MUXSDKPlayerBinding.h"
#import "MUXSDKPlayerBindingManager.h"

#if __has_feature(modules)
@import Foundation;
@import MuxCore;
#else
#import <Foundation/Foundation.h>
#if TVOS
#import <MuxCore/MuxCoreTv.h>
#else
#import <MuxCore/MuxCore.h>
#endif
#endif

@interface MUXSDKPlayerBindingManager()

// Player bindings for which we have dispatched the viewinit, customer player & video data, & playerready events to Core
@property (nonatomic, retain) NSMutableSet *playerReadyBindings;

@end
@implementation MUXSDKPlayerBindingManager

- (nonnull instancetype)init {
    self = [super init];
    if (self) {
        _playerReadyBindings = [[NSMutableSet alloc] init];
        _customerPlayerDataStore = [[MUXSDKCustomerPlayerDataStore alloc] init];
        _customerVideoDataStore = [[MUXSDKCustomerVideoDataStore alloc] init];
        _customerViewDataStore = [[MUXSDKCustomerViewDataStore alloc] init];
        _customerCustomDataStore = [[MUXSDKCustomerCustomDataStore alloc] init];
        _playerBindings = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (void)setCustomerData:(nonnull MUXSDKCustomerData *)customerData
          forPlayerName:(nonnull NSString *)name {
    MUXSDKCustomerPlayerData *playerData = customerData.customerPlayerData;
    MUXSDKCustomerVideoData *videoData = customerData.customerVideoData;
    MUXSDKCustomerViewData *viewData = customerData.customerViewData;
    MUXSDKCustomData *customData = customerData.customData;

    [_customerPlayerDataStore setPlayerData:playerData
                              forPlayerName:name];
    if (videoData) {
        [_customerVideoDataStore setVideoData:videoData
                                forPlayerName:name];
    }
    if (viewData) {
        [_customerViewDataStore setViewData:viewData
                              forPlayerName:name];
    }
    if (customData) {
        [_customerCustomDataStore setCustomData:customData
                                  forPlayerName:name];
    }
}

- (void)removeBindingsForPlayerName:(NSString *_Nonnull) name {
    [self.playerReadyBindings removeObject:name];
    [self.customerPlayerDataStore removeDataForPlayerName:name];
    [self.customerVideoDataStore removeDataForPlayerName:name];
    [self.customerViewDataStore removeDataForPlayerName:name];
    [self.customerCustomDataStore removeDataForPlayerName:name];
}

- (BOOL) hasInitializedPlayerBinding:(NSString *) name {
    return [self.playerReadyBindings containsObject:name];
}

- (void)dispatchNewViewForPlayerName:(NSString *_Nonnull) name {
    if (![self hasInitializedPlayerBinding: name]) {
        MUXSDKPlayerBinding *binding = [self.playerBindings valueForKey:name];
        if (binding != nil) {
            MUXSDKCustomerPlayerData *playerData = [self.customerPlayerDataStore playerDataForPlayerName:name];
            MUXSDKCustomerVideoData *videoData = [self.customerVideoDataStore videoDataForPlayerName:name];
            MUXSDKCustomerViewData *viewData = [self.customerViewDataStore viewDataForPlayerName:name];
            MUXSDKCustomData *customData = [self.customerCustomDataStore customDataForPlayerName:name];
            [binding dispatchViewInit];
            [self dispatchDataEventForPlayerName:name playerData:playerData videoData:videoData viewData: viewData customData:customData videoChange:NO];
            [binding dispatchPlayerReady];
            [self.playerReadyBindings addObject:name];
        }
    }
}

- (void)dispatchDataEventForPlayerName:(NSString *)name playerData:(MUXSDKCustomerPlayerData *)customerPlayerData videoData:(MUXSDKCustomerVideoData *)customerVideoData viewData:(MUXSDKCustomerViewData *)customerViewData customData:(MUXSDKCustomData *)customData videoChange:(BOOL) videoChange {
    MUXSDKDataEvent *dataEvent = [[MUXSDKDataEvent alloc] init];
    if (customerPlayerData) {
        [dataEvent setCustomerPlayerData:customerPlayerData];
    }
    if (customerVideoData) {
        [dataEvent setCustomerVideoData:customerVideoData];
    }
    if (customerViewData) {
        [dataEvent setCustomerViewData:customerViewData];
    }
    if (customData) {
        [dataEvent setCustomData:customData];
    }
    if (customerPlayerData || customerVideoData || customerViewData || customData) {
        dataEvent.videoChange = videoChange;
        [MUXSDKCore dispatchEvent:dataEvent forPlayer:name];
    }
}

#pragma MARK - MUXSDKPlayDispatchDelegate

- (void)playbackStartedForPlayer:(NSString *) name {
    if (![self hasInitializedPlayerBinding: name]) {
        NSLog(@"MUXSDK-WARNING - Detected SDK initialized after playback has started.");
        [self dispatchNewViewForPlayerName:name];
    }
}

- (void) videoChangedForPlayer:(NSString *_Nonnull) name {
    MUXSDKPlayerBinding *binding = [self.playerBindings valueForKey:name];
    if (binding != nil) {
        [binding dispatchViewInit];
        MUXSDKCustomerPlayerData *playerData = [self.customerPlayerDataStore playerDataForPlayerName:name];
        MUXSDKCustomerVideoData *videoData = [self.customerVideoDataStore videoDataForPlayerName:name];
        MUXSDKCustomerViewData *viewData = [self.customerViewDataStore viewDataForPlayerName:name];
        MUXSDKCustomData *customData = [self.customerCustomDataStore customDataForPlayerName:name];
        [self dispatchDataEventForPlayerName:name playerData:playerData videoData:videoData viewData: viewData customData:customData videoChange:YES];
    }
}

@end
