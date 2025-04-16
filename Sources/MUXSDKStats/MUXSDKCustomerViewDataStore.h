//
//  MUXSDKCustomerViewDataStore.h
//  MUXSDKStats
//
//  Created by Nidhi Kulkarni on 9/24/20.
//  Copyright © 2020 Mux, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MuxCore/MuxCore.h>

@protocol MUXSDKCustomerViewDataStoring

- (void) setViewData:(nonnull MUXSDKCustomerViewData *)viewData forPlayerName:(nonnull NSString *)name;
- (void) removeDataForPlayerName:(nonnull NSString *)name;
- (MUXSDKCustomerViewData *_Nullable) viewDataForPlayerName:(nonnull NSString *)name;

@end
@interface MUXSDKCustomerViewDataStore : NSObject<MUXSDKCustomerViewDataStoring>

@end
