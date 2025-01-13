#ifndef MUXSDKEventTyping_h
#define MUXSDKEventTyping_h

#import <Foundation/Foundation.h>

@protocol MUXSDKEventTyping

- (NSString *)getType;
- (BOOL)isAd;
- (BOOL)isTrackable;
- (BOOL)isPlayback;
- (BOOL)isData;
- (BOOL)isError;
- (BOOL)isViewMetric;
- (BOOL)isDebug;
- (NSSet *) requiredProperties;
@end

#endif
