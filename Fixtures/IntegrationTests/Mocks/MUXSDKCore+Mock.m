//
//  MUXSDKCore+Mock.m
//
//  Created by Fabrizio Persichetti on 05/15/2025.
//  Copyright © 2025 Mux, Inc. All rights reserved.
//

#import "MUXSDKCore+Mock.h"
#include <objc/runtime.h>


@implementation MUXSDKCore (Mock)

static NSMutableDictionary *events;
static NSMutableDictionary<NSString *, NSMutableArray<NSNumber *> *> *playheadTimeDeltas;
static NSMutableDictionary<NSString *, NSMutableArray<NSNumber *> *> *playheadTimeStamps;
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
    if (!playheadTimeDeltas) {
        playheadTimeDeltas = [NSMutableDictionary new];
    }
    
    if (!playheadTimeStamps) {
        playheadTimeStamps = [NSMutableDictionary new];
    }

    if (![playheadTimeDeltas objectForKey:playerId]) {
        [playheadTimeDeltas setObject:[[NSMutableArray alloc] init] forKey:playerId];
    }
    
    if (![playheadTimeStamps objectForKey:playerId]) {
        [playheadTimeStamps setObject:[[NSMutableArray alloc] init] forKey:playerId];
    }
    
    MUXSDKTimeUpdateEvent *timeEvent = (MUXSDKTimeUpdateEvent *)event;
    NSNumber *timestamp = timeEvent.playerData.playerPlayheadTime;
    
    NSMutableArray *timeStampsForPlayer = [playheadTimeStamps objectForKey:playerId];
    NSMutableArray *playerTimeDeltas = [playheadTimeDeltas objectForKey:playerId];

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

+ (NSArray *) getPlayheadTimeStampsForPlayer:(NSString *)playerId {
    NSMutableArray *playerTimeStamps = [playheadTimeStamps objectForKey:playerId];
    if (!playerTimeStamps) {
        return nil;
    }
    return playerTimeStamps;
}

+ (NSArray *) getPlayheadTimeDeltasForPlayer:(NSString *)playerId {
    NSMutableArray *playerDeltas = [playheadTimeDeltas objectForKey:playerId];
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
