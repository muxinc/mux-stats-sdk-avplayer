//
//  MUXSDKPlaceholderViewerData.m
//  
//
//  Created by AJ Barinov on 10/31/23.
//

#import <UIKit/UIDevice.h>

#import "MUXSDKPlaceholderViewerData.h"

#import <sys/utsname.h>

@implementation MUXSDKPlaceholderViewerData

- (nonnull instancetype)init {
    self = [super init];

    if (self) {
        _bundle = [NSBundle mainBundle];
        _device = [UIDevice currentDevice];
    }

    return self;
}

- (nullable NSString *)viewerApplicationName {
    return [_bundle bundleIdentifier];
}

- (nullable NSString *)viewerApplicationVersion {
    NSString *bundleShortVersion = [_bundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    NSString *bundleVersion = [_bundle objectForInfoDictionaryKey:@"CFBundleVersion"];
    if (bundleShortVersion && bundleVersion) {
        NSString *fullVersion = [NSString stringWithFormat:@"%@ (%@)", bundleShortVersion, bundleVersion];
        return fullVersion;
    } else if (bundleShortVersion) {
        return bundleShortVersion;
    } else if (bundleVersion) {
        return bundleVersion;
    } else {
        return nil;
    }
}

- (nonnull NSString *)viewerDeviceModel {
    struct utsname systemInfo;
    uname(&systemInfo);
    NSString *systemDeviceModel = [NSString stringWithCString:systemInfo.machine
                                                     encoding:NSUTF8StringEncoding];
    return systemDeviceModel;
}

- (nonnull NSString *)viewerDeviceCategory {
    NSString *systemDeviceCategory = @"unknown";

    switch ([_device userInterfaceIdiom]) {
        case UIUserInterfaceIdiomTV:
            systemDeviceCategory = @"tv";
            break;
        case UIUserInterfaceIdiomPad:
            systemDeviceCategory = @"tablet";
            break;
        case UIUserInterfaceIdiomPhone:
            systemDeviceCategory = @"phone";
            break;
        case UIUserInterfaceIdiomCarPlay:
            systemDeviceCategory = @"car";
            break;
        default:
            break;
    }

    return systemDeviceCategory;
}

- (nonnull NSString *)viewerOsFamily {
    NSString *systemOsFamily = @"unknown";

    switch ([_device userInterfaceIdiom]) {
        case UIUserInterfaceIdiomTV:
            systemOsFamily = @"tvOS";
            break;
        case UIUserInterfaceIdiomPad:
            // FIXME: This should be iPadOS, keeping iOS for
            // consistency across versions
            systemOsFamily = @"iOS";
            break;
        case UIUserInterfaceIdiomPhone:
            systemOsFamily = @"iOS";
            break;
        case UIUserInterfaceIdiomCarPlay:
            systemOsFamily = @"CarPlay";
            break;
        default:
            break;
    }

    return systemOsFamily;
}

- (nonnull NSString *)viewerOsVersion {
    return [_device systemVersion];
}

- (nonnull NSString *)viewerDeviceManufacturer {
    return @"Apple";
}

@end
