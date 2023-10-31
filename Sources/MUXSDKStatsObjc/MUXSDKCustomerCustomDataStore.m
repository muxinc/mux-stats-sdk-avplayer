//
//  MUXSDKCustomerCustomDataStore.m
//  MUXSDKStats
//
//  Created by Nidhi Kulkarni on 8/20/21.
//  Copyright © 2021 Mux, Inc. All rights reserved.
//

#import "MUXSDKCustomerCustomDataStore.h"

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

@interface MUXSDKCustomerCustomDataStore()
@property (nonatomic, retain) NSMutableDictionary *store;
@end
@implementation MUXSDKCustomerCustomDataStore

- (id) init {
    self = [super init];
    if (self) {
        self.store = [[NSMutableDictionary alloc] init];
    }
    return(self);
}

- (void)setCustomData:(nonnull MUXSDKCustomData *)customData forPlayerName:(nonnull NSString *)name {
    [self.store setValue:customData forKey:name];
}

- (void)removeDataForPlayerName:(nonnull NSString *)name {
    [self.store removeObjectForKey:name];
}

- (MUXSDKCustomData *_Nullable) customDataForPlayerName:(nonnull NSString *)name {
     return [self.store valueForKey:name];
}

@end
