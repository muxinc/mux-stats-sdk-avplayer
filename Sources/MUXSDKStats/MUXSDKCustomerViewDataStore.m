//
//  MUXSDKCustomerViewDataStore.m
//  MUXSDKStats
//
//  Created by Nidhi Kulkarni on 9/24/20.
//  Copyright © 2020 Mux, Inc. All rights reserved.
//

#import "MUXSDKCustomerViewDataStore.h"

@interface MUXSDKCustomerViewDataStore()
@property (nonatomic, retain) NSMutableDictionary *store;
@end
@implementation MUXSDKCustomerViewDataStore

- (id) init {
    self = [super init];
    if (self) {
        self.store = [[NSMutableDictionary alloc] init];
    }
    return(self);
}

- (void) setViewData:(nonnull MUXSDKCustomerViewData *)viewData forPlayerName:(nonnull NSString *)name {
    [self.store setValue:viewData forKey:name];
}

- (void)removeDataForPlayerName:(nonnull NSString *)name {
    [self.store removeObjectForKey:name];
}

- (MUXSDKCustomerViewData *_Nullable) viewDataForPlayerName:(nonnull NSString *)name {
     return [self.store valueForKey:name];
}

@end
