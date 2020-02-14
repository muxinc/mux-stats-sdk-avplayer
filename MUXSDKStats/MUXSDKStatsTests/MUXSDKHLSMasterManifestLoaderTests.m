//
//  MUXSDKHLSMasterManifestLoaderTests.m
//  MUXSDKStatsTests
//
//  Created by Nidhi Kulkarni on 2/13/20.
//  Copyright © 2020 Mux, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "MUXSDKHLSMasterManifestLoader.h"

@interface MUXSDKHLSMasterManifestLoaderTests : XCTestCase

@end

@implementation MUXSDKHLSMasterManifestLoaderTests
static NSString *BANDWIDTH = @"BANDWIDTH";
static NSString *FRAMERATE = @"FRAME-RATE";

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testParseWithoutFrameRate {
    NSBundle *bundle = [NSBundle bundleForClass:[MUXSDKHLSMasterManifestLoaderTests class]];
    NSString *path = [bundle pathForResource:@"master_manifest_without_frame_rate" ofType:@"m3u8"];
    NSData *data = [NSData dataWithContentsOfFile:path];

    MUXSDKHLSMasterManifestLoader *loader = [[MUXSDKHLSMasterManifestLoader alloc] init];
    NSArray *result = [loader parseMasterPlaylistFromData:data];
    
    NSArray *expectedResult = @[
        @{BANDWIDTH : @(14787)},
        @{BANDWIDTH : @(16405)},
        @{BANDWIDTH : @(17041)},
        @{BANDWIDTH : @(17732)},
        @{BANDWIDTH : @(19271)},
        @{BANDWIDTH : @(22931)},
        @{BANDWIDTH : @(23019)},
        @{BANDWIDTH : @(25029)},
        @{BANDWIDTH : @(27574)}
    ];
    for (int i = 0; i < expectedResult.count; i++) {
        NSDictionary *expected = expectedResult[i];
        NSDictionary *actual = result[i];
        XCTAssertTrue([expected isEqualToDictionary:actual]);
    }
}

- (void)testParseWithFrameRate {
    NSBundle *bundle = [NSBundle bundleForClass:[MUXSDKHLSMasterManifestLoaderTests class]];
    NSString *path = [bundle pathForResource:@"master_manifest_with_frame_rate" ofType:@"m3u8"];
    NSData *data = [NSData dataWithContentsOfFile:path];

    MUXSDKHLSMasterManifestLoader *loader = [[MUXSDKHLSMasterManifestLoader alloc] init];
    NSArray *result = [loader parseMasterPlaylistFromData:data];
    
    NSArray *expectedResult = @[
        @{BANDWIDTH : @(14787), FRAMERATE: @(24)},
        @{BANDWIDTH : @(16405), FRAMERATE: @(30)},
        @{BANDWIDTH : @(17041), FRAMERATE: @(29.97)},
        @{BANDWIDTH : @(17732), FRAMERATE: @(60)},
        @{BANDWIDTH : @(19271), FRAMERATE: @(24)},
        @{BANDWIDTH : @(22931), FRAMERATE: @(24)},
        @{BANDWIDTH : @(23019), FRAMERATE: @(24)},
        @{BANDWIDTH : @(25029), FRAMERATE: @(24)},
        @{BANDWIDTH : @(27574), FRAMERATE: @(24)}
    ];
    
    for (int i = 0; i < expectedResult.count; i++) {
        NSDictionary *expected = expectedResult[i];
        NSDictionary *actual = result[i];
        XCTAssertTrue([expected isEqualToDictionary:actual]);
    }
}

- (void)testParseMalformedManifest {
    NSBundle *bundle = [NSBundle bundleForClass:[MUXSDKHLSMasterManifestLoaderTests class]];
    NSString *path = [bundle pathForResource:@"master_manifest_malformed" ofType:@"m3u8"];
    NSData *data = [NSData dataWithContentsOfFile:path];

    MUXSDKHLSMasterManifestLoader *loader = [[MUXSDKHLSMasterManifestLoader alloc] init];
    NSArray *result = [loader parseMasterPlaylistFromData:data];
    XCTAssertEqual(result.count, 0);
}

- (void) testFrameRateFromEmptyPlaylist {
    MUXSDKHLSMasterManifestLoader *loader = [[MUXSDKHLSMasterManifestLoader alloc] init];
    NSNumber *result = [loader advertisedFrameRateFromPlaylist:@[] forBandwidth:@(12345)];
    XCTAssertNil(result);
}

- (void) testFrameRateFromNilPlaylist {
    MUXSDKHLSMasterManifestLoader *loader = [[MUXSDKHLSMasterManifestLoader alloc] init];
    NSNumber *result = [loader advertisedFrameRateFromPlaylist:nil forBandwidth:@(12345)];
    XCTAssertNil(result);
}

- (void) testFrameRateFromPlaylist {
    MUXSDKHLSMasterManifestLoader *loader = [[MUXSDKHLSMasterManifestLoader alloc] init];
    NSArray *masterPlaylist = @[
        @{BANDWIDTH : @(14787), FRAMERATE: @(24)},
        @{BANDWIDTH : @(16405), FRAMERATE: @(30)},
        @{BANDWIDTH : @(17041), FRAMERATE: @(29.97)},
        @{BANDWIDTH : @(17732), FRAMERATE: @(60)},
        @{BANDWIDTH : @(19271), FRAMERATE: @(24)},
        @{BANDWIDTH : @(22931), FRAMERATE: @(24)},
        @{BANDWIDTH : @(23019), FRAMERATE: @(24)},
        @{BANDWIDTH : @(25029), FRAMERATE: @(24)},
        @{BANDWIDTH : @(27574), FRAMERATE: @(24)}
    ];
    
    NSNumber *result = [loader advertisedFrameRateFromPlaylist:masterPlaylist forBandwidth:@(12345)];
    XCTAssertNil(result);
    
    result = [loader advertisedFrameRateFromPlaylist:masterPlaylist forBandwidth:@(17041)];
    XCTAssertEqualWithAccuracy([result doubleValue], 29.97, FLT_EPSILON);
    
    result = [loader advertisedFrameRateFromPlaylist:masterPlaylist forBandwidth:@(27574)];
    XCTAssertEqualWithAccuracy([result doubleValue], 24, FLT_EPSILON);
    
    result = [loader advertisedFrameRateFromPlaylist:masterPlaylist forBandwidth:@(17732.00)];
    XCTAssertEqualWithAccuracy([result doubleValue], 60, FLT_EPSILON);
}



@end
