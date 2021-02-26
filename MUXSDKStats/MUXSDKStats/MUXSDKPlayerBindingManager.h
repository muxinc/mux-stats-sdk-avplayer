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
#import <MuxCore/MuxCore.h>
#endif
#import "MUXSDKPlayerBinding.h"
#import "MUXSDKCustomerPlayerDataStore.h"
#import "MUXSDKCustomerVideoDataStore.h"
#import "MUXSDKCustomerViewDataStore.h"

@interface MUXSDKPlayerBindingManager : NSObject<MUXSDKPlayDispatchDelegate>

@property (nonatomic, weak) id<MUXSDKCustomerPlayerDataStoring> _Nullable customerPlayerDataStore;
@property (nonatomic, weak) id<MUXSDKCustomerVideoDataStoring> _Nullable customerVideoDataStore;
@property (nonatomic, weak) id<MUXSDKCustomerViewDataStoring> _Nullable customerViewDataStore;
@property (nonatomic, weak) NSDictionary * _Nullable viewControllers;

- (void) newViewForPlayer:(NSString *_Nonnull) name;
- (void) onPlayerDestroyed:(NSString *_Nonnull) name;

@end

