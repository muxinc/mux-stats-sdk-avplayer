
#ifndef MUXSDKSessionDataEvent_h
#define MUXSDKSessionDataEvent_h

#import "MUXSDKBaseEvent.h"
#import "MUXSDKEventTyping.h"
#import "MUXSDKVideoData.h"
#import "MUXSDKViewData.h"
#import "MUXSDKCustomerVideoData.h"
#import "MUXSDKCustomerPlayerData.h"
#import "MUXSDKCustomerViewData.h"
#import "MUXSDKCustomData.h"

extern NSString * _Nonnull const MUXSDKSessionDataEventType;

@interface MUXSDKSessionDataEvent : MUXSDKBaseEvent <MUXSDKEventTyping>

@property (nonatomic, retain) NSDictionary * _Nullable sessionData;
@property (nonatomic, retain) MUXSDKViewData * _Nullable viewData;
@property (nonatomic, retain) MUXSDKVideoData * _Nullable videoData;
@property (nonatomic, retain) MUXSDKCustomerVideoData * _Nullable customerVideoData;
@property (nonatomic, retain) MUXSDKCustomerPlayerData * _Nullable customerPlayerData;
@property (nonatomic, retain) MUXSDKCustomerViewData * _Nullable customerViewData;
@property (nonatomic, retain) MUXSDKCustomData * _Nullable customData;

@end

#endif
