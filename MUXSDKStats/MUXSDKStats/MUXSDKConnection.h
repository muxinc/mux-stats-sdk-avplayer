//
//  MUXSDKConnection.h
//  MUXSDKStats
//
//  Created by Dylan Jhaveri on 10/5/20.
//  Copyright © 2020 Mux, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MUXSDKConnection : NSObject

/*!
 @method      detectConnectionType
 @abstract    Detects connection type
 @discussion  The SDK will use this method to detect connection type of the device
 */
+ (void)detectConnectionType;

@end

NS_ASSUME_NONNULL_END
