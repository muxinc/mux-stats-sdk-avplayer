//
//  MUXSDKCore+Mock.h
//
//  Created by Fabrizio Persichetti on 05/15/2025.
//  Copyright © 2025 Mux, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MuxCore/MuxCore.h>

@interface MUXSDKCore (Mock)

+ (void) swizzleDispatchEvents;
+ (void) resetCapturedEvents;
+ (id<MUXSDKEventTyping>) eventAtIndex:(NSUInteger) index forPlayer:(NSString *)playerId;
+ (NSUInteger) eventsCountForPlayer:(NSString *)playerId;
+ (MUXSDKDataEvent *) globalEventAtIndex:(NSUInteger)index;
+ (NSUInteger) globalEventsCount;
+ (NSArray<MUXSDKDataEvent *> *) snapshotOfGlobalEvents;
+ (NSArray<MUXSDKDataEvent *> *) snapshotOfEventsForPlayer:(NSString *)playerId;
+ (NSArray<MUXSDKBaseEvent *> *) getEventsForPlayer: (NSString *)playerId;
+ (NSArray *) getPlayheadTimeStampsForPlayer:(NSString *)playerId;
+ (NSArray *) getPlayheadTimeDeltasForPlayer:(NSString *)playerId;

@end

