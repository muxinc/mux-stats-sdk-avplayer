//
//  TestAppUITests.m
//  TestAppUITests
//
//  Created by Nidhi Kulkarni on 12/8/20.
//

#import <XCTest/XCTest.h>
#import "GCDWebServer.h"
#import "GCDWebServerDataResponse.h"

@interface TestAppUITests : XCTestCase

@end

@implementation TestAppUITests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.

    // In UI tests it is usually best to stop immediately when a failure occurs.
    self.continueAfterFailure = NO;

    // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void) getBeaconsWithCompletionHandler:(void (^)(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error))completionHandler {
    NSURL *url = [NSURL URLWithString:@"http://localhost:8080"];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    [[session dataTaskWithURL:url completionHandler:completionHandler] resume];
}

- (void)testPlayVideo {
    
    XCUIApplication *app = [[XCUIApplication alloc] init];
    [app setLaunchEnvironment:@{@"ENV_KEY": @"local", @"SHOULD_CHANGE_VIDEO": @"0"}];
    [app launch];
    XCTestExpectation *exp = [[XCTestExpectation alloc] initWithDescription:@"Just wait for 20 seconds."];
    XCTWaiterResult result = [XCTWaiter waitForExpectations:@[exp] timeout:20.0];
    if(result != XCTWaiterResultTimedOut) {
        XCTFail(@"Interrupted while playing video.");
    }
    
    exp = [[XCTestExpectation alloc] initWithDescription:@"Wait for beacons request to complete."];
    [self getBeaconsWithCompletionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        [exp fulfill];
        
        if (error) {
            XCTFail(@"Error getting beacons: %@", error);
        }
        NSError *parseError = nil;
        id beacons = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&parseError];
        if (parseError != nil) {
            XCTFail(@"Error parsing beacons JSON. %@", parseError);
        }
        else {
            NSLog(@"Beacons: %@", beacons);
            [self assertPlaySequence:beacons[@"beacons"]];
        }
    }];
    
    result = [XCTWaiter waitForExpectations:@[exp] timeout:5.0];
    if (result ==  XCTWaiterResultTimedOut) {
        XCTFail(@"Timed out while waiting to get beacons from local server.");
    }
}

- (void) assertPlaySequence:(NSArray *) beacons {
    NSArray *expectedSequence = @[@"playerready", @"viewstart", @"play", @"playing"];
    NSArray *actualSequence = [self parseEventsFromBeacons:beacons];
    NSMutableDictionary *eventIndices = [[NSMutableDictionary alloc] init];
    for (NSDictionary *event in actualSequence) {
        NSLog(event[@"e"]);
        eventIndices[event[@"e"]] = event[@"psqno"];
    }
    for (NSString *expected in expectedSequence) {
        XCTAssertTrue([[eventIndices allKeys] containsObject:expected], @"Did not contain expected event: %@", expected);
    }
    XCTAssertLessThan([eventIndices[@"playerready"] intValue], [eventIndices[@"viewstart"] intValue], @"%@ %@", eventIndices[@"playerready"], eventIndices[@"viewstart"]);
    XCTAssertLessThan([eventIndices[@"viewstart"] intValue], [eventIndices[@"play"]intValue], @"%@ %@", eventIndices[@"viewstart"], eventIndices[@"playing"]);
    XCTAssertLessThan([eventIndices[@"play"] intValue], [eventIndices[@"playing"] intValue], @"%@ %@", eventIndices[@"play"], eventIndices[@"playing"]);
    
}

- (NSArray *) parseEventsFromBeacons:(NSArray *) beacons {
    NSMutableArray *sequence = [[NSMutableArray alloc] init];
    for (NSDictionary *eventBatch in beacons) {
        NSArray *events = eventBatch[@"events"];
        for (NSDictionary *event in events) {
            [sequence addObject:event];
        }
    }
    NSLog(@"sequence: %@", sequence);
    return sequence;
}

@end
