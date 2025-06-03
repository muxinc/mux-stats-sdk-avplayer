//
//  MUXSDKCore+Mock.h
//
//  Created by Fabrizio Persichetti on 05/15/2025.
//  Copyright © 2025 Mux, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MuxCore/MuxCore.h>

NS_ASSUME_NONNULL_BEGIN

@interface MUXSDKCore (Mock)

+ (void) swizzleDispatchEvents;
+ (void) resetCapturedEvents;
+ (void) resetCapturedEventsForPlayer:(NSString *)playerId;
+ (nullable id<MUXSDKEventTyping>) eventAtIndex:(NSUInteger) index forPlayer:(NSString *)playerId;
+ (NSUInteger) eventsCountForPlayer:(NSString *)playerId;
+ (nullable MUXSDKDataEvent *) globalEventAtIndex:(NSUInteger)index;
+ (NSUInteger) globalEventsCount;
+ (NSArray<MUXSDKDataEvent *> *) snapshotOfGlobalEvents;
+ (NSArray<MUXSDKDataEvent *> *) snapshotOfEventsForPlayer:(NSString *)playerId;
+ (NSArray<MUXSDKBaseEvent *> *) getEventsForPlayer: (NSString *)playerId;
+ (NSArray<NSNumber *> *) getPlayheadTimeStampsForPlayer:(NSString *)playerId;
+ (NSArray<NSNumber *> *) getPlayheadTimeDeltasForPlayer:(NSString *)playerId;

@end

NS_ASSUME_NONNULL_END
