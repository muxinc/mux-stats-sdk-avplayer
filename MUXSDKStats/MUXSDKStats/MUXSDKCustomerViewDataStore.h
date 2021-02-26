//
//  MUXSDKCustomerViewDataStore.h
//  MUXSDKStats
//
//  Created by Nidhi Kulkarni on 9/24/20.
//  Copyright © 2020 Mux, Inc. All rights reserved.
//

#if __has_feature(modules)
@import Foundation;
@import MuxCore;
#else
#import <Foundation/Foundation.h>
#import <MuxCore/MuxCore.h>
#endif

@protocol MUXSDKCustomerViewDataStoring

- (void) setViewData:(nonnull MUXSDKCustomerViewData *)viewData forPlayerName:(nonnull NSString *)name;
- (MUXSDKCustomerViewData *_Nullable) viewDataForPlayerName:(nonnull NSString *)name;

@end
@interface MUXSDKCustomerViewDataStore : NSObject<MUXSDKCustomerViewDataStoring>

@end
