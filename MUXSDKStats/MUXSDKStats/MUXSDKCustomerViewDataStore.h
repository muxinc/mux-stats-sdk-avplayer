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
#if TVOS
#import <MuxCore/MuxCoreTv.h>
#else
#import <MuxCore/MuxCore.h>
#endif
#endif

@protocol MUXSDKCustomerViewDataStoring

- (void) setViewData:(nonnull MUXSDKCustomerViewData *)viewData forPlayerName:(nonnull NSString *)name;
- (void) removeDataForPlayerName:(nonnull NSString *)name;
- (MUXSDKCustomerViewData *_Nullable) viewDataForPlayerName:(nonnull NSString *)name;

@end
@interface MUXSDKCustomerViewDataStore : NSObject<MUXSDKCustomerViewDataStoring>

@end
