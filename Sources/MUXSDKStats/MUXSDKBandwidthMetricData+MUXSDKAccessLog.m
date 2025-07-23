#import "MUXSDKBandwidthMetricData+MUXSDKAccessLog.h"

#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>

@implementation MUXSDKBandwidthMetricData (MUXSDKAccessLog)

- (void)updateURLPropertiesAndRequestTypeWithRequestURI:(nullable NSString *)requestURI {
    self.requestUrl = requestURI;

    NSURLComponents *components = requestURI ? [NSURLComponents componentsWithString:requestURI] : nil;

    // maintains the historical behavior of setting the entire URI directly as fallback:
    self.requestHostName = components.host ?: requestURI;

    // This is not always going to work, as it's perfectly in-spec to set content type headers instead.
    // Also the access log tends to only report playlist requests anyway. See AVMetrics for useful data.
    NSString *pathExtension = components.path.pathExtension;
    if (@available(iOS 14.0, tvOS 14.0, *)) {
        UTType *inferredType = [UTType typeWithFilenameExtension:pathExtension];
        if ([inferredType conformsToType:UTTypeVideo]) {
            self.requestType = @"video";
        } else if ([inferredType conformsToType:UTTypeAudio]) {
            self.requestType = @"audio";
        } else if ([inferredType conformsToType:UTTypeAudiovisualContent]) {
            self.requestType = @"media";
        } else if ([inferredType conformsToType:UTTypePlaylist]) {
            self.requestType = @"manifest";
        }
    } else {
        if ([pathExtension isEqual:@"m3u8"] || [pathExtension isEqual:@"m3u"]) {
            self.requestType = @"manifest";
        } else if ([pathExtension isEqual:@"ts"] || [pathExtension isEqual:@"mp4"]) {
            self.requestType = @"media";
        }
    }
}

@end
