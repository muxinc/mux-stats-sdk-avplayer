#ifndef MUXSDKImaListener_h
#define MUXSDKImaListener_h

#if TARGET_OS_IOS
@import MuxCore;
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

#endif

#endif /* MUXSDKImaListener_h */
