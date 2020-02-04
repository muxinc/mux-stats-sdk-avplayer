//
//  MUXSDKCustomerVideoDataStore.m
//  MUXSDKStats
//
//  Created by Nidhi Kulkarni on 2/3/20.
//  Copyright © 2020 Mux, Inc. All rights reserved.
//

#import "MUXSDKCustomerVideoDataStore.h"

@interface MUXSDKCustomerVideoDataStore()
@property (nonatomic, retain) NSMutableDictionary *customerVideoDatas;
@end
@implementation MUXSDKCustomerVideoDataStore

- (id) init {
    self = [super init];
    if (self) {
        self.customerVideoDatas = [[NSMutableDictionary alloc] init];
    }
    return(self);
}

- (void) setVideoData:(nonnull MUXSDKCustomerVideoData *)videoData forPlayerName:(nonnull NSString *)name {
    [self.customerVideoDatas setValue:videoData forKey:name];
}

- (MUXSDKCustomerVideoData *_Nullable) videoDataForPlayerName:(nonnull NSString *)name {
     return [self.customerVideoDatas valueForKey:name];
}

@end
