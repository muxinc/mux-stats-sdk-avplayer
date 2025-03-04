//
//  MUXSDKCustomerViewDataStore.h
//  MUXSDKStats
//
//  Created by Nidhi Kulkarni on 9/24/20.
//  Copyright © 2020 Mux, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#if TARGET_OS_TV
#import <MuxCore/MuxCoreTv.h>
#elif TARGET_OS_VISION
#import <MuxCore/MuxCoreVision.h>
#else
#import <MuxCore/MuxCore.h>
#endif

@protocol MUXSDKCustomerViewDataStoring

- (void) setViewData:(nonnull MUXSDKCustomerViewData *)viewData forPlayerName:(nonnull NSString *)name;
- (void) removeDataForPlayerName:(nonnull NSString *)name;
- (MUXSDKCustomerViewData *_Nullable) viewDataForPlayerName:(nonnull NSString *)name;

@end
@interface MUXSDKCustomerViewDataStore : NSObject<MUXSDKCustomerViewDataStoring>

@end
