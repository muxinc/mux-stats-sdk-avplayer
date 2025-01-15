#ifndef MUXSDKDataEvent_h
#define MUXSDKDataEvent_h

#import "MUXSDKBaseEvent.h"
#import "MUXSDKEventTyping.h"
#import "MUXSDKViewerData.h"
#import "MUXSDKEnvironmentData.h"
#import "MUXSDKVideoData.h"
#import "MUXSDKCustomerVideoData.h"
#import "MUXSDKCustomerPlayerData.h"
#import "MUXSDKCustomerViewData.h"
#import "MUXSDKCustomData.h"

extern NSString * _Nonnull const MUXSDKDataEventType;

@interface MUXSDKDataEvent : MUXSDKBaseEvent <MUXSDKEventTyping>

@property (nonatomic, retain) MUXSDKViewerData * _Nullable viewerData;
@property (nonatomic, retain) MUXSDKEnvironmentData * _Nullable environmentData;
@property (nonatomic, retain) MUXSDKVideoData * _Nullable videoData;
@property (nonatomic, retain) MUXSDKCustomerVideoData * _Nullable customerVideoData;
@property (nonatomic, retain) MUXSDKCustomerPlayerData * _Nullable customerPlayerData;
@property (nonatomic, retain) MUXSDKCustomerViewData * _Nullable customerViewData;
@property BOOL videoChange;
@property (nonatomic, retain) MUXSDKCustomData * _Nullable customData;

@end

#endif
