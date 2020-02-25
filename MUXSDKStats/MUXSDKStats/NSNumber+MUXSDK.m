//
//  NSNumber+MUXSDK.m
//  MUXSDKStats
//
//  Created by Nidhi Kulkarni on 2/14/20.
//  Copyright © 2020 Mux, Inc. All rights reserved.
//

#import "NSNumber+MUXSDK.h"

@implementation NSNumber (MUXSDK)

- (BOOL) doubleValueIsEqual:(NSNumber *) n {
    return fabs([self doubleValue] - [n doubleValue]) < FLT_EPSILON;
}

@end
