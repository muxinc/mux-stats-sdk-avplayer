#import "MUXSDKBandwidthMetricData+MUXSDKAccessLog.h"

@implementation MUXSDKBandwidthMetricData (MUXSDKAccessLog)

- (void)updateURLPropertiesAndRequestTypeWithRequestURI:(nullable NSString *)requestURI {
    self.requestUrl = requestURI;

    NSURLComponents *components = requestURI ? [NSURLComponents componentsWithString:requestURI] : nil;

    // maintains the historical behavior of setting the entire URI directly as fallback:
    self.requestHostName = components.host ?: requestURI;

    // This is not always going to work, as it's perfectly in-spec to set content type headers instead.
    // Also the access log tends to only report playlist requests anyway. See AVMetrics for useful data.
    NSString *pathExtension = components.path.pathExtension;
    if (pathExtension) {
        static NSDictionary<NSString *, NSString *> *lookup;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            lookup = @{
                @"m3u8": @"manifest",
                @"m3u": @"manifest",

                @"ts": @"media",
                @"mp4": @"media",
                @"mov": @"media",

                @"aac": @"audio",
                @"ac3": @"audio",
                @"m4a": @"audio",
                @"mp3": @"audio",
            };
        });
        self.requestType = lookup[pathExtension];
    } else {
        self.requestType = nil;
    }
}

@end
