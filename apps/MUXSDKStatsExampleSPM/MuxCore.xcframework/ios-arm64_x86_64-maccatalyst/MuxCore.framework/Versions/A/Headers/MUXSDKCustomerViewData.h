#ifndef MUXSDKCustomerViewData_h
#define MUXSDKCustomerViewData_h

#import "MUXSDKQueryData.h"
#import <Foundation/Foundation.h>
#import "MUXSDKUpsertable.h"

@interface MUXSDKCustomerViewData : MUXSDKQueryData<MUXSDKUpsertable>

@property (nullable) NSString *viewSessionId;
@property (nullable) NSString *viewDrmType;

@end

#endif
