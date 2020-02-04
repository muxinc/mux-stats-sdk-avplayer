//
//  MUXSDKCustomerPlayerDataStore.h
//  MUXSDKStats
//
//  Created by Nidhi Kulkarni on 2/3/20.
//  Copyright © 2020 Mux, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#if TARGET_OS_IOS
@import MuxCore;
#else
@import MuxCoreTv;
#endif

@protocol MUXSDKCustomerPlayerDataStoring

- (void) setPlayerData:(nonnull MUXSDKCustomerPlayerData *)playerData forPlayerName:(nonnull NSString *)name;
- (MUXSDKCustomerPlayerData *_Nullable) playerDataForPlayerName:(nonnull NSString *)name;

@end
@interface MUXSDKCustomerPlayerDataStore : NSObject<MUXSDKCustomerPlayerDataStoring>


@end


