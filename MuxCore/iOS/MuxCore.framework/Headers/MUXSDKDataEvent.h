#ifndef MUXSDKDataEvent_h
#define MUXSDKDataEvent_h

#import "MUXSDKBaseEvent.h"
#import "MUXSDKEventTyping.h"
#import "MUXSDKViewerData.h"
#import "MUXSDKEnvironmentData.h"
#import "MUXSDKVideoData.h"
#import "MUXSDKCustomerVideoData.h"
#import "MUXSDKCustomerPlayerData.h"

extern NSString *const MUXSDKDataEventType;

@interface MUXSDKDataEvent : MUXSDKBaseEvent <MUXSDKEventTyping>

@property (nonatomic, retain) MUXSDKViewerData *viewerData;
@property (nonatomic, retain) MUXSDKEnvironmentData *environmentData;
@property (nonatomic, retain) MUXSDKVideoData *videoData;
@property (nonatomic, retain) MUXSDKCustomerVideoData *customerVideoData;
@property (nonatomic, retain) MUXSDKCustomerPlayerData *customerPlayerData;
@property BOOL videoChange;

@end

#endif
