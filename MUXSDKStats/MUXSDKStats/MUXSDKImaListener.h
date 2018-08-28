#ifndef MUXSDKImaListener_h
#define MUXSDKImaListener_h

@import GoogleInteractiveMediaAds;

@class MUXSDKPlayerBinding;

@interface MUXSDKImaListener : NSObject {
@private
    MUXSDKPlayerBinding *_playerBinding;
}

- (id)initWithPlayerBinding:(MUXSDKPlayerBinding *)binding;
- (void)dispatchEvent:(IMAAdEventType)eventType;
- (void)dispatchError:(NSString *)message;

@end

#endif /* MUXSDKImaListener_h */
