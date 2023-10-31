//
//  MUXSDKPlaceholderViewerData.h
//  
//
//  Created by AJ Barinov on 10/31/23.
//

#import <Foundation/Foundation.h>

@class NSBundle;
@class UIDevice;

NS_ASSUME_NONNULL_BEGIN

@interface MUXSDKPlaceholderViewerData : NSObject

@property (nonatomic, strong, readonly) NSBundle *bundle;

@property (nonatomic, strong, readonly) UIDevice *device;

- (nullable NSString *)viewerApplicationName;
- (nullable NSString *)viewerApplicationVersion;
- (nonnull NSString *)viewerDeviceModel;
- (nonnull NSString *)viewerDeviceCategory;
- (nonnull NSString *)viewerOsFamily;
- (nonnull NSString *)viewerOsVersion;
- (nonnull NSString *)viewerDeviceManufacturer;

@end

NS_ASSUME_NONNULL_END
