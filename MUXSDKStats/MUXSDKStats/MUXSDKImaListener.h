#ifndef MUXSDKImaListener_h
#define MUXSDKImaListener_h

@import GoogleInteractiveMediaAds;

@class MUXSDKPlayerBinding;

@interface MUXSDKImaListener : NSObject {
@private
    MUXSDKPlayerBinding *_playerBinding;
}

- (id)initWithPlayerBinding:(MUXSDKPlayerBinding *)binding;
- (void)dispatchEvent:(IMAAdEvent *)event;
- (void)dispatchError:(NSString *)message;
- (void)onContentPauseOrResume :(bool)isPause;

@end

#endif /* MUXSDKImaListener_h */
