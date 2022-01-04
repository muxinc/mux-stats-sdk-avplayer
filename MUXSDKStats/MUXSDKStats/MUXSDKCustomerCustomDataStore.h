//
//  MUXSDKCustomerCustomDataStore.h
//  MUXSDKStats
//
//  Created by Nidhi Kulkarni on 8/20/21.
//  Copyright © 2021 Mux, Inc. All rights reserved.
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

@protocol MUXSDKCustomerCustomDataStoring

- (void) setCustomData:(nonnull MUXSDKCustomData *)customData forPlayerName:(nonnull NSString *)name;
- (void) removeDataForPlayerName:(nonnull NSString *)name;
- (MUXSDKCustomData *_Nullable) customDataForPlayerName:(nonnull NSString *)name;

@end
@interface MUXSDKCustomerCustomDataStore : NSObject<MUXSDKCustomerCustomDataStoring>

@end
