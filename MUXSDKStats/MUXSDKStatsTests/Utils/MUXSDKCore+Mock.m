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
}

+ (id<MUXSDKEventTyping>) eventAtIndex:(NSUInteger) index forPlayer:(NSString *)playerId {
    NSMutableArray *eventsForPlayer = [events objectForKey:playerId];
    if(!eventsForPlayer) {
        return nil;
    }
    return [eventsForPlayer objectAtIndex:index];
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

+ (NSArray *) capturedEventsForPlayer: (NSString *)player {
    return [[events objectForKey:player] copy];
}

@end
