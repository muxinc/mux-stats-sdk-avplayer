#ifndef MUXSDKCustomerVideoData_h
#define MUXSDKCustomerVideoData_h

#import "MUXSDKQueryData.h"
#import <Foundation/Foundation.h>

extern NSString *VIDEO_ID;

@interface MUXSDKCustomerVideoData : MUXSDKQueryData

@property (nullable) NSString *videoCdn;
@property (nullable) NSString *videoContentType;
@property (nullable) NSNumber *videoDuration;
@property (nullable) NSString *videoEncodingVariant;
@property (nullable) NSString *videoId;
@property (nullable) NSNumber *videoIsLive;
@property (nullable) NSString *videoLanguageCode;
@property (nullable) NSString *videoProducer;
@property (nullable) NSString *videoSeries;
@property (nullable) NSString *videoStreamType;
@property (nullable) NSString *videoTitle;
@property (nullable) NSString *videoVariantId;
@property (nullable) NSString *videoVariantName;

@end

#endif
