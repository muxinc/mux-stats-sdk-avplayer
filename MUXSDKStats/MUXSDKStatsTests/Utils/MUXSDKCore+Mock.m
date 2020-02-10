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

+ (void) swizzleDispatchEvents {
    static dispatch_once_t once_token;
    dispatch_once(&once_token,  ^{
        [MUXSDKCore _swizzle];
    });
}

+ (void) _swizzle {
    SEL dispatchEventsSelector = @selector(dispatchEvent:forPlayer:);
    SEL dispatchEventsMockSelector = @selector(mock_dispatchEvent:forPlayer:);
    Method originalMethod = class_getClassMethod(self, dispatchEventsSelector);
    Method extendedMethod = class_getClassMethod(self, dispatchEventsMockSelector);
    method_exchangeImplementations(originalMethod, extendedMethod);
}

+ (void) resetCapturedEvents {
    events = [[NSMutableDictionary alloc] init];
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

@end
