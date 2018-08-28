#import <Foundation/Foundation.h>
#import "MUXSDKImaListener.h"
#import "MUXSDKPlayerBinding.h"

#import "MUXSDKAdBreakEndEvent.h"
#import "MUXSDKAdBreakStartEvent.h"
#import "MUXSDKAdEndedEvent.h"
#import "MUXSDKAdErrorEvent.h"
#import "MUXSDKAdFirstQuartileEvent.h"
#import "MUXSDKAdMidpointEvent.h"
#import "MUXSDKAdPauseEvent.h"
#import "MUXSDKAdPlayEvent.h"
#import "MUXSDKAdPlayingEvent.h"
#import "MUXSDKAdThirdQuartileEvent.h"
#import "MUXSDKAdRequestEvent.h"
#import "MUXSDKAdResponseEvent.h"

@implementation MUXSDKImaListener

- (id)initWithPlayerBinding:(MUXSDKPlayerBinding *)binding {
    self = [super init];
    if (self) {
        _playerBinding = binding;
    }
    return(self);
}

- (void)dispatchEvent:(IMAAdEventType)eventType {
    switch(eventType) {
        case kIMAAdEvent_AD_BREAK_READY:
            [_playerBinding dispatchAdEvent:[MUXSDKAdResponseEvent new]];
            break;
        case kIMAAdEvent_AD_BREAK_ENDED:
            [_playerBinding dispatchAdEvent:[MUXSDKAdBreakEndEvent new]];
            break;
        case kIMAAdEvent_AD_BREAK_STARTED:
            [_playerBinding dispatchAdEvent:[MUXSDKAdBreakStartEvent new]];
            [_playerBinding dispatchAdEvent:[MUXSDKAdRequestEvent new]];
            break;
        case kIMAAdEvent_ALL_ADS_COMPLETED:
            break;
        case kIMAAdEvent_CLICKED:
            break;
        case kIMAAdEvent_COMPLETE:
            [_playerBinding dispatchAdEvent:[MUXSDKAdEndedEvent new]];
            break;
        case kIMAAdEvent_CUEPOINTS_CHANGED:
            break;
        case kIMAAdEvent_FIRST_QUARTILE:
            [_playerBinding dispatchAdEvent:[MUXSDKAdFirstQuartileEvent new]];
            break;
        case kIMAAdEvent_LOADED:
            break;
        case kIMAAdEvent_LOG:
            break;
        case kIMAAdEvent_MIDPOINT:
            [_playerBinding dispatchAdEvent:[MUXSDKAdMidpointEvent new]];
            break;
        case kIMAAdEvent_PAUSE:
            [_playerBinding dispatchAdEvent:[MUXSDKAdPauseEvent new]];
            break;
        case kIMAAdEvent_RESUME:
            [_playerBinding dispatchAdEvent:[MUXSDKAdPlayingEvent new]];
            break;
        case kIMAAdEvent_SKIPPED:
            break;
        case kIMAAdEvent_STARTED:
            [_playerBinding dispatchAdEvent:[MUXSDKAdPlayingEvent new]];
            break;
        case kIMAAdEvent_STREAM_LOADED:
            break;
        case kIMAAdEvent_STREAM_STARTED:
            [_playerBinding dispatchAdEvent:[MUXSDKAdPlayEvent new]];
            break;
        case kIMAAdEvent_TAPPED:
            break;
        case kIMAAdEvent_THIRD_QUARTILE:
            [_playerBinding dispatchAdEvent:[MUXSDKAdThirdQuartileEvent new]];
            break;
        default:
            break;
    }
}

- (void)dispatchError:(NSString *)message {
    [_playerBinding dispatchAdEvent:[MUXSDKAdErrorEvent new]];
}

@end
