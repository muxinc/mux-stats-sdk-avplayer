#ifndef MUXSDKCustomerPlayerData_h
#define MUXSDKCustomerPlayerData_h

#import "MUXSDKQueryData.h"
#import <Foundation/Foundation.h>
#import "MUXSDKUpsertable.h"

@interface MUXSDKCustomerPlayerData : MUXSDKQueryData<MUXSDKUpsertable>

- (nullable instancetype)initWithPropertyKey:(nonnull NSString *)propertyKey;
- (nullable instancetype)initWithEnvironmentKey:(nonnull NSString *)envKey;

@property (nullable) NSString *adConfigVariant;
@property (nullable) NSString *experimentName;
@property (nullable) NSString *pageType;
@property (nullable) NSNumber *playerInitTime;
@property (nullable) NSString *playerName;
@property (nullable) NSString *playerVersion;
@property (nullable) NSString *playerSoftwareName;
@property (nullable) NSString *playerSoftwareVersion;
@property (nullable) NSString *propertyKey;
@property (nullable) NSString *environmentKey;
@property (nullable) NSString *subPropertyId;
@property (nullable) NSString *viewerUserId;
@property BOOL playerAutoplayOn;

@end

#endif
