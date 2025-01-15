#ifndef MUXSDKQueryData_h
#define MUXSDKQueryData_h

#import <Foundation/Foundation.h>

@interface MUXSDKQueryData : NSObject
- (void)update:(nonnull NSDictionary *)query;
- (void)updateIfNull:(nonnull NSDictionary *)query;
- (void)remove:(nonnull NSString *)key;
- (void)removeAll:(nonnull NSDictionary *)query;
- (nullable id)get:(nonnull NSString *)key;
- (nonnull NSDictionary *)toQuery;
- (void)setQuery: (nonnull NSDictionary *)query;

@end

#endif
