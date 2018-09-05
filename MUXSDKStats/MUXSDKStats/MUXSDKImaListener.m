#import <Foundation/Foundation.h>
#import "MUXSDKImaListener.h"
#import "MUXSDKPlayerBinding.h"

@import MuxCore;

@implementation MUXSDKImaListener

- (id)initWithPlayerBinding:(MUXSDKPlayerBinding *)binding {
    self = [super init];
    if (self) {
        _playerBinding = binding;
    }
    return(self);
}

- (void) setupAdViewData:(MUXSDKPlaybackEvent *)event withAd:(IMAAd *)ad {
    MUXSDKViewData *viewData = [MUXSDKViewData new];
    if ([_playerBinding getCurrentPlayheadTimeMs] < 1000) {
        if (ad != nil) {
            viewData.viewPrerollAdId = ad.adId;
            viewData.viewPrerollCreativeId = ad.creativeID;
        }
    }
    event.viewData = viewData;
}

- (void)dispatchEvent:(IMAAdEvent *)event {
    MUXSDKPlaybackEvent *playbackEvent;
    switch(event.type) {
        case kIMAAdEvent_LOADED:
            playbackEvent = [MUXSDKAdResponseEvent new];
            [self setupAdViewData:playbackEvent withAd:event.ad];
            [_playerBinding dispatchAdEvent: playbackEvent];
            playbackEvent = [MUXSDKAdPlayEvent new];
            break;
        case kIMAAdEvent_STARTED:
            playbackEvent = [MUXSDKAdPlayingEvent new];
            break;
        case kIMAAdEvent_FIRST_QUARTILE:
            playbackEvent = [MUXSDKAdFirstQuartileEvent new];
            break;
        case kIMAAdEvent_MIDPOINT:
            playbackEvent = [MUXSDKAdMidpointEvent new];
            break;
        case kIMAAdEvent_THIRD_QUARTILE:
            playbackEvent = [MUXSDKAdThirdQuartileEvent new];
            break;
        case kIMAAdEvent_SKIPPED:
        case kIMAAdEvent_COMPLETE:
            playbackEvent = [MUXSDKAdEndedEvent new];
            break;
        case kIMAAdEvent_PAUSE:
            playbackEvent = [MUXSDKAdPauseEvent new];
            break;
        case kIMAAdEvent_RESUME:
            playbackEvent = [MUXSDKAdPlayingEvent new];
            break;
        default:
            break;
    }
    if (playbackEvent != nil) {
        [self setupAdViewData:playbackEvent withAd:event.ad];
        [_playerBinding dispatchAdEvent:playbackEvent];
    }
}

- (void)onContentPauseOrResume :(bool)isPause {
    MUXSDKPlaybackEvent *playbackEvent;
    if (isPause) {
        playbackEvent = [MUXSDKAdBreakStartEvent new];
        [self setupAdViewData:playbackEvent withAd:nil];
        [_playerBinding dispatchAdEvent: playbackEvent];
        playbackEvent = [MUXSDKAdRequestEvent new];
    } else {
        playbackEvent = [MUXSDKAdBreakEndEvent new];
    }
    if (playbackEvent != nil) {
        [self setupAdViewData:playbackEvent withAd:nil];
        [_playerBinding dispatchAdEvent:playbackEvent];
    }
}

- (void)dispatchError:(NSString *)message {
    MUXSDKPlaybackEvent *playbackEvent = [MUXSDKAdErrorEvent new];
    [self setupAdViewData:playbackEvent withAd:nil];
    [_playerBinding dispatchAdEvent:playbackEvent];
}

@end
