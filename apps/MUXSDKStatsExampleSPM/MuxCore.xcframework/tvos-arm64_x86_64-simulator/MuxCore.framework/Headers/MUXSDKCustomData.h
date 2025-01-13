#ifndef MUXSDKCustomData_h
#define MUXSDKCustomData_h

#import "MUXSDKQueryData.h"
#import <Foundation/Foundation.h>
#import "MUXSDKUpsertable.h"

@interface MUXSDKCustomData : MUXSDKQueryData<MUXSDKUpsertable>

@property (nullable) NSString *customData1;
@property (nullable) NSString *customData2;
@property (nullable) NSString *customData3;
@property (nullable) NSString *customData4;
@property (nullable) NSString *customData5;
@property (nullable) NSString *customData6;
@property (nullable) NSString *customData7;
@property (nullable) NSString *customData8;
@property (nullable) NSString *customData9;
@property (nullable) NSString *customData10;

@end
#endif
