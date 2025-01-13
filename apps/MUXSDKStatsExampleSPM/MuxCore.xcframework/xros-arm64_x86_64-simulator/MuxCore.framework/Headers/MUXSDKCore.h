#ifndef MUXSDKCore_h
#define MUXSDKCore_h

#import "MUXSDKDataEvent.h"
#import "MUXSDKEventHandling.h"
#import "MUXSDKEventTyping.h"

#import <Foundation/Foundation.h>

@class MUXSDKErrorEvent;
@protocol MUXSDKErrorEventTranslating;

@interface MUXSDKCore : NSObject

+ (void)setClientHandler:(id<MUXSDKEventHandling>)handler;
+ (void)dispatchGlobalDataEvent:(MUXSDKDataEvent *)event;
+ (void)dispatchEvent:(id<MUXSDKEventTyping>)event forPlayer:(NSString *)playerId;
+ (void)destroyPlayer:(NSString *)playerId;
+ (void)setDeviceId:(NSString *)deviceId forPlayer:(NSString *)playerId;
+ (void)setSentryEnabled:(BOOL)enabled;
+ (void)setBeaconCollectionDomain:(NSString *)collectionDomain forPlayer:(NSString *)playerId;
+ (void)setBeaconDomain:(NSString *)domain forPlayer:(NSString *)playerId __attribute__((deprecated("Please migrate to setBeaconCollectionDomain:forPlayer")));;
+ (void)setErrorTranslator:(id<MUXSDKErrorEventTranslating>)customErrorTranslator;

@end

#endif
