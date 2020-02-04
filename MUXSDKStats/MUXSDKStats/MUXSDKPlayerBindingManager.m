//
//  MUXSDKPlayerBindingManager.m
//  MUXSDKStats
//
//  Created by Nidhi Kulkarni on 1/30/20.
//  Copyright © 2020 Mux, Inc. All rights reserved.
//

#import "MUXSDKPlayerBindingManager.h"

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


- (BOOL) hasInitializedPlayerBinding:(NSString *) name {
    return [self.playerReadyBindings containsObject:name];
}

- (void) initializeCoreForPlayer:(NSString *_Nonnull) name {
    if (![self hasInitializedPlayerBinding: name]) {
        MUXSDKPlayerBinding *binding = [self.viewControllers valueForKey:name];
           if (binding != nil) {
               MUXSDKCustomerPlayerData *playerData = [self.customerPlayerDataStore playerDataForPlayerName:name];
               MUXSDKCustomerVideoData *videoData = [self.customerVideoDataStore videoDataForPlayerName:name];
               [binding dispatchViewInit];
               [self dispatchDataEventForPlayerName:name playerData:playerData videoData:videoData];
               [binding dispatchPlayerReady];
               [self.playerReadyBindings addObject:name];
           }
    }
}

- (void)playerWillDispatchPlay:(NSString *) name {
    if (![self hasInitializedPlayerBinding: name]) {
        NSLog(@"MUXSDK-WARNING - Detected SDK initialized after playback has started.");
        [self initializeCoreForPlayer:name];
    }
}

- (void)dispatchDataEventForPlayerName:(NSString *)name playerData:(MUXSDKCustomerPlayerData *)customerPlayerData videoData:(MUXSDKCustomerVideoData *)customerVideoData {
    MUXSDKDataEvent *dataEvent = [[MUXSDKDataEvent alloc] init];
    if (customerPlayerData) {
        [dataEvent setCustomerPlayerData:customerPlayerData];
    }
    if (customerVideoData) {
        [dataEvent setCustomerVideoData:customerVideoData];
    }
    if (customerPlayerData || customerVideoData) {
       [MUXSDKCore dispatchEvent:dataEvent forPlayer:name];
    }
}



@end
