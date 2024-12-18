//
//  MUXSDKCore+Mock.h
//  MUXSDKStatsTests
//
//  Created by Nidhi Kulkarni on 2/4/20.
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

@interface MUXSDKCore (Mock)

+ (void) swizzleDispatchEvents;
+ (void) resetCapturedEvents;
+ (id<MUXSDKEventTyping>) eventAtIndex:(NSUInteger) index forPlayer:(NSString *)playerId;
+ (NSUInteger) eventsCountForPlayer:(NSString *)playerId;
+ (MUXSDKDataEvent *) globalEventAtIndex:(NSUInteger)index;
+ (NSUInteger) globalEventsCount;
+ (NSArray *) capturedEventsForPlayer: (NSString *)player;

@end

