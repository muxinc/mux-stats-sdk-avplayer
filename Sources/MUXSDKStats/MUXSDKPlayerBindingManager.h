//
//  MUXSDKPlayerBindingManager.h
//  MUXSDKStats
//
//  Created by Nidhi Kulkarni on 1/30/20.
//  Copyright © 2020 Mux, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MuxCore/MuxCore.h>

#import "MUXSDKStats/MUXSDKPlayerBinding.h"

#import "MUXSDKCustomerPlayerDataStore.h"
#import "MUXSDKCustomerVideoDataStore.h"
#import "MUXSDKCustomerViewDataStore.h"
#import "MUXSDKCustomerCustomDataStore.h"

@interface MUXSDKPlayerBindingManager : NSObject<MUXSDKPlayDispatchDelegate>

@property (nonatomic, weak) id<MUXSDKCustomerPlayerDataStoring> _Nullable customerPlayerDataStore;
@property (nonatomic, weak) id<MUXSDKCustomerVideoDataStoring> _Nullable customerVideoDataStore;
@property (nonatomic, weak) id<MUXSDKCustomerViewDataStoring> _Nullable customerViewDataStore;
@property (nonatomic, weak) id<MUXSDKCustomerCustomDataStoring> _Nullable customerCustomDataStore;
@property (nonatomic, weak) NSDictionary<NSString *, __kindof MUXSDKPlayerBinding *> *bindingsByPlayerName;

- (void) newViewForPlayer:(NSString *_Nonnull) name;
- (void) onPlayerDestroyed:(NSString *_Nonnull) name;

@end

