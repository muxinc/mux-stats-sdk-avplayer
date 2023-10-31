//
//  MUXSDKPlayerBindingManager.h
//  MUXSDKStats
//
//  Created by Nidhi Kulkarni on 1/30/20.
//  Copyright © 2020 Mux, Inc. All rights reserved.
//

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
#import "MUXSDKPlayerBinding.h"
#import "MUXSDKCustomerPlayerDataStore.h"
#import "MUXSDKCustomerVideoDataStore.h"
#import "MUXSDKCustomerViewDataStore.h"
#import "MUXSDKCustomerCustomDataStore.h"

@interface MUXSDKPlayerBindingManager : NSObject<MUXSDKPlayDispatchDelegate>

@property (nonatomic, strong, nullable) id<MUXSDKCustomerPlayerDataStoring> customerPlayerDataStore;
@property (nonatomic, strong, nullable) id<MUXSDKCustomerVideoDataStoring> customerVideoDataStore;
@property (nonatomic, strong, nullable) id<MUXSDKCustomerViewDataStoring> customerViewDataStore;
@property (nonatomic, strong, nullable) id<MUXSDKCustomerCustomDataStoring> customerCustomDataStore;

// Name => AVPlayerViewController or AVPlayerLayer or AVPlayer
@property (nonatomic, strong, nullable) NSMutableDictionary *playerBindings;

- (void)setCustomerData:(nonnull MUXSDKCustomerData *)customerData
          forPlayerName:(nonnull NSString *)name;

- (void)dispatchNewViewForPlayerName:(nonnull NSString *)name;
- (void)removeBindingsForPlayerName:(nonnull NSString *)name;

@end

