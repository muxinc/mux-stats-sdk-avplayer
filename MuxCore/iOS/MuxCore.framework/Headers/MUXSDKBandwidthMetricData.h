#ifndef MUXSDKBandwidthMetricData_h
#define MUXSDKBandwidthMetricData_h

#import "MUXSDKQueryData.h"
#import <Foundation/Foundation.h>

@interface MUXSDKBandwidthMetricData : MUXSDKQueryData

@property (nullable) NSString *requestEventType;
@property (nullable) NSNumber *requestStart;
@property (nullable) NSNumber *requestResponseStart;
@property (nullable) NSNumber *requestResponseEnd;
@property (nullable) NSNumber *requestBytesLoaded;
@property (nullable) NSString *requestType;
@property (nullable) NSDictionary *requestResponseHeaders;
@property (nullable) NSString *requestHostName;
@property (nullable) NSNumber *requestMediaDuration;
@property (nullable) NSNumber *requestCurrentLevel;
@property (nullable) NSNumber *requestMediaStartTime;
@property (nullable) NSNumber *requestVideoWidth;
@property (nullable) NSNumber *requestVideoHeight;
@property (nullable) NSString *requestError;
@property (nullable) NSString *requestUrl;
@property (nullable) NSString *requestErrorText;
@property (nullable) NSNumber *requestErrorCode;
@property (nullable) NSNumber *requestLabeledBitrate;
@property (nullable) NSString *requestCancel;
@property (nullable) NSArray *requestRenditionLists;

@end

#endif
