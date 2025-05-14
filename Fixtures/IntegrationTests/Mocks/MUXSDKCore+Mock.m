//
//  MUXSDKCore+Mock.m
//  MUXSDKStatsTests
//
//  Created by Nidhi Kulkarni on 2/4/20.
//  Copyright © 2020 Mux, Inc. All rights reserved.
//

#import "MUXSDKCore+Mock.h"
#include <objc/runtime.h>


@implementation MUXSDKCore (Mock)

static NSMutableDictionary *events;
static NSMutableDictionary<NSString *, NSMutableArray<NSNumber *> *> *timeDeltas;
static NSMutableDictionary<NSString *, NSMutableArray<NSNumber *> *> *timeStamps;
static NSMutableArray *globalEvents;

+ (void) swizzleDispatchEvents {
    static dispatch_once_t once_token;
    dispatch_once(&once_token,  ^{
        [MUXSDKCore _swizzle];
    });
}

+ (void) _swizzle {
    [self _swizzleEvent];
    [self _swizzleGlobalEvent];
}

+ (void) _swizzleEvent {
    SEL dispatchEventsSelector = @selector(dispatchEvent:forPlayer:);
    SEL dispatchEventsMockSelector = @selector(mock_dispatchEvent:forPlayer:);

    Method originalMethod = class_getClassMethod(self, dispatchEventsSelector);
    Method extendedMethod = class_getClassMethod(self, dispatchEventsMockSelector);
    method_exchangeImplementations(originalMethod, extendedMethod);
}

+ (void) _swizzleGlobalEvent {
    SEL dispatchGlobalEventsSelector = @selector(dispatchGlobalDataEvent:);
    SEL dispatchGlobalEventsMockSelector = @selector(mock_dispatchGlobalDataEvent:);

    Method originalMethod = class_getClassMethod(self, dispatchGlobalEventsSelector);
    Method extendedMethod = class_getClassMethod(self, dispatchGlobalEventsMockSelector);
    method_exchangeImplementations(originalMethod, extendedMethod);
}

+ (void) resetCapturedEvents {
    events = [[NSMutableDictionary alloc] init];
    globalEvents = [[NSMutableArray alloc] init];
}

+ (void)resetCapturedEventsForPlayer:(NSString *)playerId {
    if (events && [events objectForKey:playerId]) {
        NSMutableArray *playerEvents = [events objectForKey:playerId];
        [playerEvents removeAllObjects];
    }
}

+ (void) mock_dispatchGlobalDataEvent:(MUXSDKDataEvent *)event {
    [globalEvents addObject:event];
}

+ (void) mock_dispatchEvent:(id<MUXSDKEventTyping>)event forPlayer:(NSString *)playerId {
    if (![events objectForKey:playerId]) {
        [events setObject:[[NSMutableArray alloc] init] forKey:playerId];
    }
    NSMutableArray *eventsForPlayer = [events objectForKey:playerId];
    [eventsForPlayer addObject:event];
    
    if ([(NSObject *)event isKindOfClass:[MUXSDKTimeUpdateEvent class]]) {
        [self trackTimeForEvent:event playerId:playerId];
    }
}

+ (void) trackTimeForEvent:(id<MUXSDKEventTyping>)event playerId:(NSString *)playerId {
    if (!timeDeltas) {
        timeDeltas = [NSMutableDictionary new];
    }
    
    if (!timeStamps) {
        timeStamps = [NSMutableDictionary new];
    }

    if (![timeDeltas objectForKey:playerId]) {
        [timeDeltas setObject:[[NSMutableArray alloc] init] forKey:playerId];
    }
    
    if (![timeStamps objectForKey:playerId]) {
        [timeStamps setObject:[[NSMutableArray alloc] init] forKey:playerId];
    }
    
    MUXSDKTimeUpdateEvent *timeEvent = (MUXSDKTimeUpdateEvent *)event;
    NSNumber *timestamp = timeEvent.playerData.playerPlayheadTime;
    
    NSMutableArray *timeStampsForPlayer = [timeStamps objectForKey:playerId];
    NSMutableArray *playerTimeDeltas = [timeDeltas objectForKey:playerId];

    if (playerTimeDeltas.count == 0) {
        [timeStampsForPlayer addObject:timestamp];
        [playerTimeDeltas addObject:@(0)];
    } else {
        NSNumber *lastTimestamp = [timeStampsForPlayer lastObject];
        [timeStampsForPlayer addObject:timestamp];

        double delta = timestamp.doubleValue - lastTimestamp.doubleValue;

        [playerTimeDeltas addObject:@(delta)];
    }
}

+ (id<MUXSDKEventTyping>) eventAtIndex:(NSUInteger) index forPlayer:(NSString *)playerId {
    NSMutableArray *eventsForPlayer = [events objectForKey:playerId];
    if(!eventsForPlayer) {
        return nil;
    }
    return [eventsForPlayer objectAtIndex:index];
}

+ (NSArray<MUXSDKBaseEvent *> *) getEventsForPlayer: (NSString *)playerId {
    NSMutableArray *eventsForPlayer = [events objectForKey:playerId];
    if(!eventsForPlayer) {
        return nil;
    }
    return eventsForPlayer;
}

+ (NSArray *)getTimeStampsForPlayer:(NSString *)playerId {
    NSMutableArray *playerTimeStamps = [timeStamps objectForKey:playerId];
    if (!playerTimeStamps) {
        return nil;
    }
    return playerTimeStamps;
}

+ (NSArray *)getTimeDeltasForPlayer:(NSString *)playerId {
    NSMutableArray *playerDeltas = [timeDeltas objectForKey:playerId];
    if (!playerDeltas) {
        return nil;
    }
    return playerDeltas;
}

+ (NSUInteger) eventsCountForPlayer:(NSString *)playerId {
    NSMutableArray *eventsForPlayer = [events objectForKey:playerId];
    if(!eventsForPlayer) {
        return 0;
    }
    return eventsForPlayer.count;
}

+ (MUXSDKDataEvent *) globalEventAtIndex:(NSUInteger)index {
    return [globalEvents objectAtIndex:index];
}

+ (NSUInteger) globalEventsCount {
    return globalEvents.count;
}

+ (NSArray<MUXSDKDataEvent *> *) snapshotOfGlobalEvents {
    return [NSArray arrayWithArray:globalEvents];
}

+ (NSArray<MUXSDKDataEvent *> *) snapshotOfEventsForPlayer:(NSString *)playerId {
    return [NSArray arrayWithArray:[events objectForKey:playerId]];
}

@end
