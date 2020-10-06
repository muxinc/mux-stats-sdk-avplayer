#import "MUXSDKConnection.h"
#import <SystemConfiguration/SystemConfiguration.h>
//#import <sys/utsname.h>
//#include <ifaddrs.h>

/*
    Right now this class has 1 significant shortcoming and it is that on
    a wired ethernet TVOS app it will detect "wifi" as the connection type

    If we can bump the target iOS version for this SDK all the way up to iOS12
    then we can use NWPathMonitor.
 */
@implementation MUXSDKConnection

+ (void)detectConnectionType {
    MUXSDKConnection *connection = [[MUXSDKConnection alloc] init];
    [connection detectConnectionAsync];
}

//
// 2020-10-05 dylanjhaveri
// this will detect the connection type asynchronously, off the main queue
// it's important to do this off the main queue because this check can hang
// after it's done, it will fire a notification to NSNotificationCenter
//
- (void)detectConnectionAsync {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString *type = [self getConnectionType];
        NSDictionary *userInfo = @{@"type" : type};
        [NSNotificationCenter.defaultCenter postNotificationName:@"com.mux.connection-type-detected" object:nil userInfo:userInfo];
    });
}

- (NSString *) getConnectionType {
    SCNetworkReachabilityRef reachability = SCNetworkReachabilityCreateWithName(NULL, "8.8.8.8");
    SCNetworkReachabilityFlags flags;
    BOOL success = SCNetworkReachabilityGetFlags(reachability, &flags);
    CFRelease(reachability);
    if (!success) {
        return NULL;
    }
    BOOL isReachable = ((flags & kSCNetworkReachabilityFlagsReachable) != 0);
    BOOL needsConnection = ((flags & kSCNetworkReachabilityFlagsConnectionRequired) != 0);
    BOOL isNetworkReachable = (isReachable && !needsConnection);

    if (!isNetworkReachable) {
        return NULL;
    } else if ((flags & kSCNetworkReachabilityFlagsIsWWAN) != 0) {
        return @"cellular";
    } else {
        return @"wifi";
    }
}


@end
