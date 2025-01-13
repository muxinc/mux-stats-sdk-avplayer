#ifndef MUXSDKRequestBandwidthEvent_h
#define MUXSDKRequestBandwidthEvent_h

#import "MUXSDKPlaybackEvent.h"
#import <Foundation/Foundation.h>

extern NSString * _Nonnull const MUXSDKPlaybackEventRequestBandwidthEventErrorType;
extern NSString * _Nonnull const MUXSDKPlaybackEventRequestBandwidthEventCancelType;
extern NSString * _Nonnull const MUXSDKPlaybackEventRequestBandwidthEventCompleteType;

@interface MUXSDKRequestBandwidthEvent : MUXSDKPlaybackEvent
@property (nullable) NSString *type;
@end

#endif
