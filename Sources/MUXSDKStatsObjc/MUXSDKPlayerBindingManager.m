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
#import <MuxCore/MuxCore.h>
#endif

@interface MUXSDKPlayerBindingManager()

// Player bindings for which we have dispatched the viewinit, customer player & video data, & playerready events to Core
@property (nonatomic, retain) NSMutableSet *playerReadyBindings;

@end
@implementation MUXSDKPlayerBindingManager

- (id)init {
    self = [super init];
    if (self) {
        self.playerReadyBindings = [[NSMutableSet alloc] init];
    }
    return self;
}

- (void) onPlayerDestroyed:(NSString *_Nonnull) name {
    [self.playerReadyBindings removeObject:name];
    [self.customerPlayerDataStore removeDataForPlayerName:name];
    [self.customerVideoDataStore removeDataForPlayerName:name];
    [self.customerViewDataStore removeDataForPlayerName:name];
    [self.customerCustomDataStore removeDataForPlayerName:name];
}

- (BOOL) hasInitializedPlayerBinding:(NSString *) name {
    return [self.playerReadyBindings containsObject:name];
}

- (void) newViewForPlayer:(NSString *_Nonnull) name {
    if (![self hasInitializedPlayerBinding: name]) {
        MUXSDKPlayerBinding *binding = [self.viewControllers valueForKey:name];
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
        [self newViewForPlayer:name];
    }
}

- (void) videoChangedForPlayer:(NSString *_Nonnull) name {
    MUXSDKPlayerBinding *binding = [self.viewControllers valueForKey:name];
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
