//
//  MUXSDKPlayerBindingManager.h
//  MUXSDKStats
//
//  Created by Nidhi Kulkarni on 1/30/20.
//  Copyright © 2020 Mux, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#if TARGET_OS_TV
#import <MuxCore/MuxCoreTv.h>
#elif TARGET_OS_VISION
#import <MuxCore/MuxCoreVision.h>
#else
#import <MuxCore/MuxCore.h>
#endif

#import "MUXSDKPlayerBinding.h"

#import "MUXSDKCustomerPlayerDataStore.h"
#import "MUXSDKCustomerVideoDataStore.h"
#import "MUXSDKCustomerViewDataStore.h"
#import "MUXSDKCustomerCustomDataStore.h"

@interface MUXSDKPlayerBindingManager : NSObject<MUXSDKPlayDispatchDelegate>

@property (nonatomic, weak) id<MUXSDKCustomerPlayerDataStoring> _Nullable customerPlayerDataStore;
@property (nonatomic, weak) id<MUXSDKCustomerVideoDataStoring> _Nullable customerVideoDataStore;
@property (nonatomic, weak) id<MUXSDKCustomerViewDataStoring> _Nullable customerViewDataStore;
@property (nonatomic, weak) id<MUXSDKCustomerCustomDataStoring> _Nullable customerCustomDataStore;
@property (nonatomic, weak) NSDictionary * _Nullable viewControllers;

- (void) newViewForPlayer:(NSString *_Nonnull) name;
- (void) onPlayerDestroyed:(NSString *_Nonnull) name;

@end

