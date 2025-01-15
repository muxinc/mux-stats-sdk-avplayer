#ifndef MUXSDKEnvironmentData_h
#define MUXSDKEnvironmentData_h

#import "MUXSDKQueryData.h"
#import <Foundation/Foundation.h>

@interface MUXSDKEnvironmentData : MUXSDKQueryData

@property (nullable) NSString *muxApiVersion;
@property (nullable) NSString *muxEmbedVersion;
@property (nullable) NSString *muxViewerId;
@property (nullable) NSNumber *sessionExpires;
@property (nullable) NSString *sessionId;
@property (nullable) NSNumber *sessionStart;
@property (nullable) NSString *muxEmbed;
@end

#endif
