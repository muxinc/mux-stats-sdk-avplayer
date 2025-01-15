//
//  MUXSDKViewDeviceOrientationData.h
//  MuxCore
//
//  Created by Nidhi Kulkarni on 2/11/20.
//  Copyright © 2020 Mux. All rights reserved.
//

#ifndef MUXSDKViewDeviceOrientationData_h
#define MUXSDKViewDeviceOrientationData_h

#import <Foundation/Foundation.h>
#import "MUXSDKQueryData.h"

@interface MUXSDKViewDeviceOrientationData : MUXSDKQueryData

@property (nonatomic, readonly) NSNumber * x;
@property (nonatomic, readonly) NSNumber * y;
@property (nonatomic, readonly) NSNumber * z;

- (id) initWithX:(NSNumber *) x y:(NSNumber *) y z:(NSNumber *) z;
- (id) initWithZ:(NSNumber *) z;

@end

#endif
