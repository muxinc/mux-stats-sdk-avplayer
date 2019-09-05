#import <Foundation/Foundation.h>
#import "MUXSDKImaListenerStub.h"
#import "MUXSDKPlayerBinding.h"

@implementation MUXSDKImaListener

- (id)initWithPlayerBinding:(MUXSDKPlayerBinding *)binding {
    self = [super init];
    if (self) {
        _playerBinding = binding;
    }
    return(self);
}

- (void) setupAdViewData:(NSString *)event withAd:(NSString *)ad {
}

- (void)dispatchEvent:(NSString *)event {
}

- (void)onContentPauseOrResume :(bool)isPause {
}

- (void)dispatchError:(NSString *)message {
}

@end
