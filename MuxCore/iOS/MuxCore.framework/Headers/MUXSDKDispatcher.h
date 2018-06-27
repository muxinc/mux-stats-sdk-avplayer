#ifndef MUXSDKDispatcher_h
#define MUXSDKDispatcher_h

#import "MUXSDKEventHandling.h"
#import "MUXSDKEventTyping.h"

@import Foundation;

@protocol MUXSDKNetworkRequestsCompletion
- (void)onComplete: (bool)result;
@end

@interface MUXSDKDispatcher : NSObject<MUXSDKEventHandling> {
    @private
    long _failureCount;
    NSURL *_url;
    NSData *_eventsJson;
}

- (void)handle:(id<MUXSDKEventTyping>)event;
- (void)handleBatch:(NSString *)envKey osFamily:(NSString *)os withJson: (NSData *)json withCallback: (id<MUXSDKNetworkRequestsCompletion>) callback;
+ (void)handleException:(NSDictionary *)json pluginName:(NSString *)pluginName pluginVersion:(NSString *)pluginVerison;

@end

#endif
