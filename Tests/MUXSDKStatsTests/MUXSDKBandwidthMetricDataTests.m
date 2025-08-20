#import <XCTest/XCTest.h>
#import "MUXSDKBandwidthMetricData+MUXSDKAccessLog.h"

@interface MUXSDKBandwidthMetricDataTests : XCTestCase

@end

@implementation MUXSDKBandwidthMetricDataTests

- (void)testNilURI {
    MUXSDKBandwidthMetricData *metricData = [MUXSDKBandwidthMetricData new];
    [metricData updateURLPropertiesAndRequestTypeWithRequestURI:nil];

    XCTAssertNil(metricData.requestUrl);
    XCTAssertNil(metricData.requestHostName);
    XCTAssertNil(metricData.requestType);
}

- (void)testMissingExtension {
    NSString *uri = @"https://example.com/no_extension";

    MUXSDKBandwidthMetricData *metricData = [MUXSDKBandwidthMetricData new];
    [metricData updateURLPropertiesAndRequestTypeWithRequestURI:uri];

    XCTAssertEqualObjects(metricData.requestUrl, uri);
    XCTAssertEqualObjects(metricData.requestHostName, @"example.com");
    XCTAssertNil(metricData.requestType);
}

- (void)testInvalidBeginningOfURI {
    NSString *uri = @"https:/example.com/playlist.m3u8";

    MUXSDKBandwidthMetricData *metricData = [MUXSDKBandwidthMetricData new];
    [metricData updateURLPropertiesAndRequestTypeWithRequestURI:uri];

    XCTAssertEqualObjects(metricData.requestUrl, uri);
    XCTAssertEqualObjects(metricData.requestHostName, uri);
    XCTAssertEqualObjects(metricData.requestType, @"manifest");
}

- (void)testNonsenseURI {
    NSString *uri = @"video title";

    MUXSDKBandwidthMetricData *metricData = [MUXSDKBandwidthMetricData new];
    [metricData updateURLPropertiesAndRequestTypeWithRequestURI:uri];

    XCTAssertEqualObjects(metricData.requestUrl, uri);
    XCTAssertEqualObjects(metricData.requestHostName, uri);
    XCTAssertNil(metricData.requestType);
}

- (void)testNoHostname {
    NSString *uri = @"/playlist.m3u8";

    MUXSDKBandwidthMetricData *metricData = [MUXSDKBandwidthMetricData new];
    [metricData updateURLPropertiesAndRequestTypeWithRequestURI:uri];

    XCTAssertEqualObjects(metricData.requestUrl, uri);
    XCTAssertEqualObjects(metricData.requestHostName, uri);
    XCTAssertEqualObjects(metricData.requestType, @"manifest");
}

- (void)testCommonExtensions API_AVAILABLE(ios(14), tvos(14)) {
    [@{
        @"manifest": @[
            @"m3u8",
            @"m3u",
        ],
        @"media": @[
            @"mp4",
            @"ts",
            @"mov",
        ],
        @"audio": @[
            @"aac",
            @"ac3",
            @"m4a",
            @"mp3",
        ],
    } enumerateKeysAndObjectsUsingBlock:^(NSString *requestType, NSArray<NSString *> *commonExtensions, BOOL * _Nonnull stop) {
        for (NSString *extension in commonExtensions) {
            NSString *uri = [@"https://example.com/file." stringByAppendingString:extension];

            MUXSDKBandwidthMetricData *metricData = [MUXSDKBandwidthMetricData new];
            [metricData updateURLPropertiesAndRequestTypeWithRequestURI:uri];

            XCTAssertEqualObjects(metricData.requestUrl, uri);
            XCTAssertEqualObjects(metricData.requestHostName, @"example.com");
            XCTAssertEqualObjects(metricData.requestType, requestType);
        }
    }];
}

@end
