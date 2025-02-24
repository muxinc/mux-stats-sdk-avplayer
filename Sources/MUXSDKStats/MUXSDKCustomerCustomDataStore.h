//
//  MUXSDKCustomerCustomDataStore.h
//  MUXSDKStats
//
//  Created by Nidhi Kulkarni on 8/20/21.
//  Copyright © 2021 Mux, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#if TARGET_OS_TV
#import <MuxCore/MuxCoreTv.h>
#elif TARGET_OS_VISION
#import <MuxCore/MuxCoreVision.h>
#else
#import <MuxCore/MuxCore.h>
#endif

@protocol MUXSDKCustomerCustomDataStoring

- (void) setCustomData:(nonnull MUXSDKCustomData *)customData forPlayerName:(nonnull NSString *)name;
- (void) removeDataForPlayerName:(nonnull NSString *)name;
- (MUXSDKCustomData *_Nullable) customDataForPlayerName:(nonnull NSString *)name;

@end
@interface MUXSDKCustomerCustomDataStore : NSObject<MUXSDKCustomerCustomDataStoring>

@end
