//
//  MUXSDKStats+PropertyGetters.h
//  MUXSDKStats
//
//  Declares a project-level class extension that allows tests to get values under test out of the SDK
//
//  Created by Emily Dixon on 10/17/22.
//  Copyright © 2022 Mux, Inc. All rights reserved.
//

#ifndef MUXSDKStats_PropertyGetters_h
#define MUXSDKStats_PropertyGetters_h

#import "MUXSDKStats/MUXSDKStats.h"

@interface MUXSDKStats()

// Expose buildViewerData for tests
+ (MUXSDKViewerData *)buildViewerData;

@end

#endif /* MUXSDKStats_PropertyGetters_h */
