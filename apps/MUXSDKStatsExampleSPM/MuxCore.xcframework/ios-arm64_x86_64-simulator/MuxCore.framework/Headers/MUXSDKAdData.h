//
//  MUXSDKAdData.h
//  MuxCore
//
//  Created by Emily Dixon on 1/30/23.
//  Copyright © 2023 Mux. All rights reserved.
//

#ifndef MUXSDKAdData_h
#define MUXSDKAdData_h

#import "MUXSDKQueryData.h"
#import "MUXSDKViewDeviceOrientationData.h"
#import <Foundation/Foundation.h>
#import "MUXSDKViewDeviceOrientationData.h"
#import "MUXSDKUpsertable.h"

@interface MUXSDKAdData : MUXSDKQueryData<MUXSDKUpsertable>

@property (nullable) NSString *adAssetUrl;
@property (nullable) NSString *adCreativeId;
@property (nullable) NSString *adId;
@property (nullable) NSString *adTagUrl;
@property (nullable) NSString *adUniversalId;

+ (NSSet *_Nonnull)requiredKeys;

@end

#endif /* MUXSDKAdData_h */
