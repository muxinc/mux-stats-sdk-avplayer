#ifndef MUXSDKPlaybackEvent_h
#define MUXSDKPlaybackEvent_h

#import "MUXSDKBaseEvent.h"
#import "MUXSDKEventTyping.h"
#import "MUXSDKPlayerData.h"
#import "MUXSDKVideoData.h"
#import "MUXSDKViewData.h"
#import "MUXSDKBandwidthMetricData.h"

extern NSString * _Nonnull const MUXSDKPlaybackEventType;

@interface MUXSDKPlaybackEvent : MUXSDKBaseEvent <MUXSDKEventTyping>

@property (nonatomic, retain, nullable) MUXSDKPlayerData *playerData;
@property (nonatomic, retain, nullable) MUXSDKVideoData *videoData;
@property (nonatomic, retain, nullable) MUXSDKViewData *viewData;
@property (nonatomic, retain, nullable) MUXSDKBandwidthMetricData *bandwidthMetricData;

@end

#endif
