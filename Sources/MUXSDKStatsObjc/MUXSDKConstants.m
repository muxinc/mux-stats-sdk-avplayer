//
//  MUXSDKConstants.m
//  MUXSDKStats
//

#if __has_feature(modules)
@import Foundation;
#else
#import <Foundation/Foundation.h>
#endif

#import "MUXSDKConstants.h"

NSString * const MUXSDKRenditionChangeNotification = @"RenditionChangeNotification";

NSString * const MUXSDKRenditionChangeNotificationInfoAdvertisedBitrate = @"RenditionChangeNotificationInfoAdvertisedBitrate";

NSString * const MUXSDKPluginName = @"apple-mux";

NSString * const MUXSDKPluginVersion = @"4.0.0";

NSString * const MUXSessionDataPrefix = @"io.litix.data.";

NSString * const MUXSDKPlayerSoftwareAVPlayerViewController = @"AVPlayerViewController";

NSString * const MUXSDKPlayerSoftwareAVPlayerLayer = @"AVPlayerLayer";

NSString * const MUXSDKPlayerSoftwareAVPlayer = @"AVPlayer";

NSString * const MUXSDKDeviceIDUserDefaultsKey = @"MUX_DEVICE_ID";
