//
//  MUXSDKCustomerVideoDataStore.h
//  MUXSDKStats
//
//  Created by Nidhi Kulkarni on 2/3/20.
//  Copyright © 2020 Mux, Inc. All rights reserved.
//

#if __has_feature(modules)
@import Foundation;
@import MuxCore;
#else
#import <Foundation/Foundation.h>
#import <MuxCore/MuxCore.h>
#endif

@protocol MUXSDKCustomerVideoDataStoring

- (void) setVideoData:(nonnull MUXSDKCustomerVideoData *)videoData forPlayerName:(nonnull NSString *)name;
- (MUXSDKCustomerVideoData *_Nullable) videoDataForPlayerName:(nonnull NSString *)name;

@end
@interface MUXSDKCustomerVideoDataStore : NSObject<MUXSDKCustomerVideoDataStoring>

@end

