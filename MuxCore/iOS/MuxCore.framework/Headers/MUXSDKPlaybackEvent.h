#ifndef MUXSDKPlaybackEvent_h
#define MUXSDKPlaybackEvent_h

#import "MUXSDKBaseEvent.h"
#import "MUXSDKEventTyping.h"
#import "MUXSDKPlayerData.h"
#import "MUXSDKVideoData.h"
#import "MUXSDKViewData.h"

extern NSString *const MUXSDKPlaybackEventType;

@interface MUXSDKPlaybackEvent : MUXSDKBaseEvent <MUXSDKEventTyping>

@property (nonatomic, retain) MUXSDKPlayerData *playerData;
@property (nonatomic, retain) MUXSDKVideoData *videoData;
@property (nonatomic, retain) MUXSDKViewData *viewData;

@end

#endif
