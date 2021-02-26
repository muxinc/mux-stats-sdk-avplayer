//
//  MUXSDKCustomerPlayerDataStore.h
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

@protocol MUXSDKCustomerPlayerDataStoring

- (void) setPlayerData:(nonnull MUXSDKCustomerPlayerData *)playerData forPlayerName:(nonnull NSString *)name;
- (MUXSDKCustomerPlayerData *_Nullable) playerDataForPlayerName:(nonnull NSString *)name;

@end
@interface MUXSDKCustomerPlayerDataStore : NSObject<MUXSDKCustomerPlayerDataStoring>


@end


