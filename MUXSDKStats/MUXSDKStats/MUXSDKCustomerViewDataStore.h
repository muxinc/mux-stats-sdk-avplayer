//
//  MUXSDKCustomerViewDataStore.h
//  MUXSDKStats
//
//  Created by Nidhi Kulkarni on 9/24/20.
//  Copyright © 2020 Mux, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#if TARGET_OS_IOS
@import MuxCore;
#else
@import MuxCoreTv;
#endif

@protocol MUXSDKCustomerViewDataStoring

- (void) setViewData:(nonnull MUXSDKCustomerViewData *)viewData forPlayerName:(nonnull NSString *)name;
- (MUXSDKCustomerViewData *_Nullable) viewDataForPlayerName:(nonnull NSString *)name;

@end
@interface MUXSDKCustomerViewDataStore : NSObject<MUXSDKCustomerViewDataStoring>

@end
