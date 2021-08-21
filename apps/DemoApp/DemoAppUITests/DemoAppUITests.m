//
//  DemoAppUITests.m
//  DemoAppUITests
//
//  Created by Nidhi Kulkarni on 10/27/20.
//  Copyright © 2020 Mux, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>

NSString *const kAdTagURLStringPostRoll = @"https://pubads.g.doubleclick.net/gampad/ads?sz=640x480&iu=/124319096/external/ad_rule_samples&ciu_szs=300x250&ad_rule=1&impl=s&gdfp_req=1&env=vp&output=vmap&unviewed_position_start=1&cust_params=deployment%3Ddevsite%26sample_ar%3Dpostonly&cmsid=496&vid=short_onecue&correlator=";

@interface DemoAppUITests : XCTestCase

@end

@implementation DemoAppUITests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.

    // In UI tests it is usually best to stop immediately when a failure occurs.
    self.continueAfterFailure = NO;
    
    // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testPlayVideo {
    XCUIApplication *app = [[XCUIApplication alloc] init];
    [app setLaunchEnvironment:@{@"ENV_KEY": @"tr4q3qahs0gflm8b1c75h49ln", @"TEST_SCENARIO": @"NORMAL_VIEW"}];
    [app launch];
    XCTestExpectation *exp = [[XCTestExpectation alloc] initWithDescription:@"Just wait for 20 seconds."];
    XCTWaiterResult result = [XCTWaiter waitForExpectations:@[exp] timeout:20.0];
    if(result != XCTWaiterResultTimedOut) {
        XCTFail(@"Interrupted while playing video.");
    }
}

- (void)testIMASDK {
    XCUIApplication *app = [[XCUIApplication alloc] init];
    [app setLaunchEnvironment:@{@"ENV_KEY": @"tr4q3qahs0gflm8b1c75h49ln", @"TEST_SCENARIO": @"IMA"}];
    [app launch];
    XCTestExpectation *exp = [[XCTestExpectation alloc] initWithDescription:@"Wait for launch (~5 sec) and preroll (10 sec)"];
    XCTWaiterResult result = [XCTWaiter waitForExpectations:@[exp] timeout:15.0];
    if(result != XCTWaiterResultTimedOut) {
        XCTFail(@"Interrupted while playing video.");
    }
        
    XCUIElement *element = [[[app.windows childrenMatchingType:XCUIElementTypeOther].element childrenMatchingType:XCUIElementTypeOther].element childrenMatchingType:XCUIElementTypeOther].element;
    [element tap];
    
    XCUIElement *skipForwardButton = app/*@START_MENU_TOKEN@*/.buttons[@"Skip Forward"]/*[[".buttons[@\"Skip 15 seconds forward\"]",".buttons[@\"Skip Forward\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/;
    [skipForwardButton tap];
    exp = [[XCTestExpectation alloc] initWithDescription:@"Wait for midroll (30 sec)"];
    result = [XCTWaiter waitForExpectations:@[exp] timeout:30.0];
    if(result != XCTWaiterResultTimedOut) {
        XCTFail(@"Interrupted while playing video.");
    }
    exp = [[XCTestExpectation alloc] initWithDescription:@"Wait for (10 sec)"];
    result = [XCTWaiter waitForExpectations:@[exp] timeout:10.0];
    if(result != XCTWaiterResultTimedOut) {
        XCTFail(@"Interrupted while playing video.");
    }
}

- (void)testUpdateCustomDimensions {
    XCUIApplication *app = [[XCUIApplication alloc] init];
    [app setLaunchEnvironment:@{@"ENV_KEY": @"tr4q3qahs0gflm8b1c75h49ln", @"TEST_SCENARIO": @"UPDATE_CUSTOM_DIMENSIONS"}];
    [app launch];
    XCTestExpectation *exp = [[XCTestExpectation alloc] initWithDescription:@"Just wait for 20 seconds."];
    XCTWaiterResult result = [XCTWaiter waitForExpectations:@[exp] timeout:20.0];
    if(result != XCTWaiterResultTimedOut) {
        XCTFail(@"Interrupted while playing video.");
    }
}

@end
