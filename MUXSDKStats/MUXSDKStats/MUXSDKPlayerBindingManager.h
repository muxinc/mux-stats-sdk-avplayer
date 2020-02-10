//
//  MUXSDKPlayerBindingManager.h
//  MUXSDKStats
//
//  Created by Nidhi Kulkarni on 1/30/20.
//  Copyright © 2020 Mux, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#if TARGET_OS_IOS
@import MuxCore;
#else
@import MuxCoreTv;
#endif
#import "MUXSDKPlayerBinding.h"
#import "MUXSDKCustomerPlayerDataStore.h"
#import "MUXSDKCustomerVideoDataStore.h"

@interface MUXSDKPlayerBindingManager : NSObject<MUXSDKPlayDispatchDelegate>

@property (nonatomic, weak) id<MUXSDKCustomerPlayerDataStoring> _Nullable customerPlayerDataStore;
@property (nonatomic, weak) id<MUXSDKCustomerVideoDataStoring> _Nullable customerVideoDataStore;
@property (nonatomic, weak) NSDictionary * _Nullable viewControllers;

- (void) newViewForPlayer:(NSString *_Nonnull) name;

@end

