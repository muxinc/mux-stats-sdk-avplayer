#ifndef MUXSDKCustomerViewerData_h
#define MUXSDKCustomerViewerData_h

#import <Foundation/Foundation.h>

@interface MUXSDKCustomerViewerData : NSObject

@property (nullable) NSString* viewerApplicationName;
@property (nullable) NSString* viewerOsVersion;
@property (nullable) NSString* viewerOsFamily;
@property (nullable) NSString* viewerDeviceModel;
@property (nullable) NSString* viewerDeviceManufacturer;
@property (nullable) NSString* viewerDeviceCategory;

@end

#endif
