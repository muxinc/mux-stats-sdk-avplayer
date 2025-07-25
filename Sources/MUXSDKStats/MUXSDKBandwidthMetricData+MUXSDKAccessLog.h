#import <MuxCore/MuxCore.h>

NS_HEADER_AUDIT_BEGIN(nullability, sendability)

@interface MUXSDKBandwidthMetricData (MUXSDKAccessLog)

/// Using a URI from an access or error log, update `requestUrl`, `requestHostName`, and with a best
/// effort attempt, `requestType`.
- (void)updateURLPropertiesAndRequestTypeWithRequestURI:(nullable NSString *)requestURI;

@end

NS_HEADER_AUDIT_END(nullability, sendability)
