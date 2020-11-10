//
//  MUXSDKCustomerVideoDataStore.h
//  MUXSDKStats
//
//  Created by Nidhi Kulkarni on 2/3/20.
//  Copyright © 2020 Mux, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
@import MuxCore;

@protocol MUXSDKCustomerVideoDataStoring

- (void) setVideoData:(nonnull MUXSDKCustomerVideoData *)videoData forPlayerName:(nonnull NSString *)name;
- (MUXSDKCustomerVideoData *_Nullable) videoDataForPlayerName:(nonnull NSString *)name;

@end
@interface MUXSDKCustomerVideoDataStore : NSObject<MUXSDKCustomerVideoDataStoring>

@end

