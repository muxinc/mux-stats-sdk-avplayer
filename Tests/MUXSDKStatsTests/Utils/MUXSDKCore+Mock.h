//
//  MUXSDKCore+Mock.h
//  MUXSDKStatsTests
//
//  Created by Nidhi Kulkarni on 2/4/20.
//  Copyright © 2020 Mux, Inc. All rights reserved.
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

@end

