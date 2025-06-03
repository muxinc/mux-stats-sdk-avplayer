//
//  MUXSDKCore+Mock.m
//
//  Created by Fabrizio Persichetti on 05/15/2025.
//  Copyright © 2025 Mux, Inc. All rights reserved.
//

#import "MUXSDKCore+Mock.h"
#include <objc/runtime.h>


@implementation MUXSDKCore (Mock)

static NSMutableDictionary<NSString *, NSMutableArray<MUXSDKDataEvent *> *> *events;
static NSMutableDictionary<NSString *, NSMutableArray<NSNumber *> *> *playheadTimeDeltas;
static NSMutableDictionary<NSString *, NSMutableArray<NSNumber *> *> *playheadTimeStamps;
static NSMutableArray<MUXSDKDataEvent *> *globalEvents;

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self resetCapturedEvents];
    });
}

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
    @synchronized (events) {
        events = [NSMutableDictionary new];
    }
    @synchronized (globalEvents) {
        globalEvents = [NSMutableArray new];
    }
    @synchronized (playheadTimeDeltas) {
        playheadTimeDeltas = [NSMutableDictionary new];
    }
    @synchronized (playheadTimeStamps) {
        playheadTimeStamps = [NSMutableDictionary new];
    }
}

+ (void)resetCapturedEventsForPlayer:(NSString *)playerId {
    @synchronized (events) {
        [events[playerId] removeAllObjects];
    }
}

+ (void) mock_dispatchGlobalDataEvent:(MUXSDKDataEvent *)event {
    @synchronized (globalEvents) {
        [globalEvents addObject:event];
    }
}

+ (void) mock_dispatchEvent:(id<MUXSDKEventTyping>)event forPlayer:(NSString *)playerId {
    @synchronized (events) {
        NSMutableArray *eventsForPlayer = events[playerId];
        if (!eventsForPlayer) {
            eventsForPlayer = [NSMutableArray new];
            [events setObject:eventsForPlayer forKey:playerId];
        }
        [eventsForPlayer addObject:event];
    }

    if ([(id)event isKindOfClass:[MUXSDKTimeUpdateEvent class]]) {
        [self trackTimeForEvent:(MUXSDKTimeUpdateEvent *)event playerId:playerId];
    }
}

+ (void) trackTimeForEvent:(MUXSDKTimeUpdateEvent *)event playerId:(NSString *)playerId {
    @synchronized (playheadTimeDeltas) {
        @synchronized (playheadTimeStamps) {
            NSMutableArray<NSNumber *> *playerTimeDeltas = playheadTimeDeltas[playerId];
            if (!playerTimeDeltas) {
                playerTimeDeltas = [NSMutableArray new];
                playheadTimeDeltas[playerId] = playerTimeDeltas;
            }

            NSMutableArray<NSNumber *> *timeStampsForPlayer = playheadTimeStamps[playerId];
            if (!timeStampsForPlayer) {
                timeStampsForPlayer = [NSMutableArray new];
                playheadTimeStamps[playerId] = timeStampsForPlayer;
            }

            NSNumber *timestamp = event.playerData.playerPlayheadTime;

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
    }
}

+ (id<MUXSDKEventTyping>) eventAtIndex:(NSUInteger) index forPlayer:(NSString *)playerId {
    @synchronized (events) {
        return events[playerId][index];
    }
}

+ (NSArray<MUXSDKBaseEvent *> *) getEventsForPlayer: (NSString *)playerId {
    @synchronized (events) {
        return [events[playerId] copy];
    }
}

+ (NSArray<NSNumber *> *) getPlayheadTimeStampsForPlayer:(NSString *)playerId {
    @synchronized (playheadTimeStamps) {
        return [playheadTimeStamps[playerId] copy] ?: @[];
    }
}

+ (NSArray<NSNumber *> *) getPlayheadTimeDeltasForPlayer:(NSString *)playerId {
    @synchronized (playheadTimeDeltas) {
        return [playheadTimeDeltas[playerId] copy] ?: @[];
    }
}

+ (NSUInteger) eventsCountForPlayer:(NSString *)playerId {
    @synchronized (events) {
        return [events[playerId] count];
    }
}

+ (MUXSDKDataEvent *) globalEventAtIndex:(NSUInteger)index {
    @synchronized (globalEvents) {
        return globalEvents[index];
    }
}

+ (NSUInteger) globalEventsCount {
    @synchronized (globalEvents) {
        return globalEvents.count;
    }
}

+ (NSArray<MUXSDKDataEvent *> *) snapshotOfGlobalEvents {
    @synchronized (globalEvents) {
        return globalEvents.copy;
    }
}

+ (NSArray<MUXSDKDataEvent *> *) snapshotOfEventsForPlayer:(NSString *)playerId {
    @synchronized (events) {
        return [events[playerId] copy] ?: @[];
    }
}

@end
