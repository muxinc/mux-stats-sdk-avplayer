#import "MUXSDKConnection.h"
@import Network;
//#import <SystemConfiguration/SystemConfiguration.h>
//#import <sys/utsname.h>
//#include <ifaddrs.h>

@implementation MUXSDKConnection

+ (void)detectConnectionType {
    MUXSDKConnection *connection = [[MUXSDKConnection alloc] init];
    [connection startNetworkMonitoring];
}

#if defined(__IPHONE_12_0) || defined(__TVOS_12_0)

- (void)startNetworkMonitoring
{
    self.monitor = nw_path_monitor_create();
    nw_path_monitor_set_queue(self.monitor, dispatch_get_main_queue());
    nw_path_monitor_set_update_handler(self.monitor, ^(nw_path_t _Nonnull path) {
        nw_path_status_t status = nw_path_get_status(path);
        BOOL isWiFi = nw_path_uses_interface_type(path, nw_interface_type_wifi);
        BOOL isCellular = nw_path_uses_interface_type(path, nw_interface_type_cellular);
        BOOL isEthernet = nw_path_uses_interface_type(path, nw_interface_type_wired);
        BOOL isExpensive = nw_path_is_expensive(path);
        BOOL hasIPv4 = nw_path_has_ipv4(path);
        BOOL hasIPv6 = nw_path_has_ipv6(path);
        BOOL hasNewDNS = nw_path_has_dns(path);

        NSDictionary *userInfo = @{
                                    @"isWiFi" : @(isWiFi),
                                    @"isCellular" : @(isCellular),
                                    @"isEthernet" : @(isEthernet),
                                    @"status" : @(status),
                                    @"isExpensive" : @(isExpensive),
                                    @"hasIPv4" : @(hasIPv4),
                                    @"hasIPv6" : @(hasIPv6),
                                    @"hasNewDNS" : @(hasNewDNS)
                                 };

        dispatch_async(dispatch_get_main_queue(), ^{
            [NSNotificationCenter.defaultCenter postNotificationName:@"com.mux.network.status-change" object:nil userInfo:userInfo];
        });
    });

    nw_path_monitor_start(self.monitor);
}

- (void)stopNetworkMonitoring {
    if (@available(iOS 12.0, *)) {
        nw_path_monitor_cancel(self.monitor);
    } else {
        // Fallback on earlier versions
    }
}

#else

- (void)startNetworkMonitoring {}

- (void)stopNetworkMonitoring {}

#endif


@end
