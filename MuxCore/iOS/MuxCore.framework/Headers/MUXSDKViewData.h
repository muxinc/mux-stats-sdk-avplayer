#ifndef MUXSDKViewData_h
#define MUXSDKViewData_h

#import "MUXSDKQueryData.h"
#import <Foundation/Foundation.h>

extern NSString *VIEW_SEQUENCE_NUMBER;
extern NSString *VIEW_ID;
extern NSString *VIEWER_TIME;

@interface MUXSDKViewData : MUXSDKQueryData

@property (nullable) NSNumber *viewAdBreakCount;
@property (nullable) NSNumber *viewAdCompleteCount;
@property (nullable) NSNumber *viewAdErrorCount;
@property (nullable) NSNumber *viewAdViewCount;
@property (nullable) NSNumber *viewAdWatchTime;
@property (nullable) NSNumber *viewEnd;
@property (nullable) NSString *viewId;
@property (nullable) NSNumber *viewMaxDownscalePercentage;
@property (nullable) NSNumber *viewMaxSeekTime;
@property (nullable) NSNumber *viewMaxUpscalePercentage;
@property (nullable) NSNumber *viewMidrollTimeToFirstAd;
@property (nullable) NSNumber *viewPercentageViewed;
@property (nullable) NSNumber *viewRebufferCount;
@property (nullable) NSNumber *viewRebufferDuration;
@property (nullable) NSNumber *viewRebufferFrequency;
@property (nullable) NSNumber *viewRebufferPercentage;
@property (nullable) NSNumber *viewSeekCount;
@property (nullable) NSNumber *viewSeekDuration;
@property (nullable) NSNumber *viewSequenceNumber;
@property (nullable) NSNumber *viewStart;
@property (nullable) NSNumber *viewTimeToFirstFrame;
@property (nullable) NSNumber *viewTimeToPreroll;
@property (nullable) NSNumber *viewTotalContentPlaybackTime;
@property (nullable) NSNumber *viewTotalDownscaling;
@property (nullable) NSNumber *viewTotalUpscaling;
@property (nullable) NSNumber *viewWaitingRebufferCount;
@property (nullable) NSNumber *viewWaitingRebufferDuration;
@property (nullable) NSNumber *viewWatchTime;
@property (nullable) NSNumber *viewerTime;

@end

#endif
