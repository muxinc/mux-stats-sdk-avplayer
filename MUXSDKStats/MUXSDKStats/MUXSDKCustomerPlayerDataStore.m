//
//  MUXSDKCustomerPlayerDataStore.m
//  MUXSDKStats
//
//  Created by Nidhi Kulkarni on 2/3/20.
//  Copyright © 2020 Mux, Inc. All rights reserved.
//

#import "MUXSDKCustomerPlayerDataStore.h"

@interface MUXSDKCustomerPlayerDataStore()
@property (nonatomic, retain) NSMutableDictionary *customerPlayerDatas;
@end
@implementation MUXSDKCustomerPlayerDataStore

- (id) init {
    self = [super init];
    if (self) {
        self.customerPlayerDatas = [[NSMutableDictionary alloc] init];
    }
    return(self);
}

- (void) setPlayerData:(nonnull MUXSDKCustomerPlayerData *)playerData forPlayerName:(nonnull NSString *)name {
    [self.customerPlayerDatas setValue:playerData forKey:name];
}

- (MUXSDKCustomerPlayerData *_Nullable) playerDataForPlayerName:(nonnull NSString *)name {
    return [self.customerPlayerDatas valueForKey:name];
}

@end
