#ifndef MUXSDKCore_h
#define MUXSDKCore_h

#import "MUXSDKDataEvent.h"
#import "MUXSDKEventHandling.h"
#import "MUXSDKEventTyping.h"

#import <Foundation/Foundation.h>

@interface MUXSDKCore : NSObject

+ (void)setClientHandler:(id<MUXSDKEventHandling>)handler;
+ (void)dispatchGlobalDataEvent:(MUXSDKDataEvent *)event;
+ (void)dispatchEvent:(id<MUXSDKEventTyping>)event forPlayer:(NSString *)playerId;
+ (void)destoryPlayer:(NSString *)playerId;

@end

#endif
