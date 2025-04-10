//
//  MUXSDKCore+Mock.h
//  MUXSDKStatsTests
//
//  Created by Nidhi Kulkarni on 2/4/20.
//  Copyright © 2020 Mux, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#if TARGET_OS_TV
#import <MuxCore/MuxCoreTv.h>
#elif TARGET_OS_VISION
#import <MuxCore/MuxCoreVision.h>
#else
#import <MuxCore/MuxCore.h>
#endif

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

