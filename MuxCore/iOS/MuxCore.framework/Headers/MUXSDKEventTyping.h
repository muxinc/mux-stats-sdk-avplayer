#ifndef MUXSDKEventTyping_h
#define MUXSDKEventTyping_h

#import <Foundation/Foundation.h>

@protocol MUXSDKEventTyping

- (NSString *)getType;
- (BOOL)isTrackable;
- (BOOL)isPlayback;
- (BOOL)isData;
- (BOOL)isError;
- (BOOL)isViewMetric;
- (BOOL)isDebug;

@end

#endif
