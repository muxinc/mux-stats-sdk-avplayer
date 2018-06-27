#ifndef MUXSDKVideoData_h
#define MUXSDKVideoData_h

#import "MUXSDKQueryData.h"
#import <Foundation/Foundation.h>

@interface MUXSDKVideoData : MUXSDKQueryData

@property (nullable) NSString *videoPosterUrl;
@property (nullable) NSString *videoSourceDomain;
@property (nullable) NSNumber *videoSourceDuration;
@property (nullable) NSNumber *videoSourceHeight;
@property (nullable) NSString *videoSourceHostName;
@property (nullable) NSString *videoSourceIsLive;
@property (nullable) NSString *videoSourceMimeType;
@property (nullable) NSString *videoSourceUrl;
@property (nullable) NSNumber *videoSourceWidth;

@end

#endif
