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

// Set this key to your environment key to have the tests generate data on your dashboard
static NSString *envKey = @"tr4q3qahs0gflm8b1c75h49ln";

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.

    // In UI tests it is usually best to stop immediately when a failure occurs.
    self.continueAfterFailure = NO;
    
    // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testPlayOnDemandVideo {
    XCUIApplication *app = [[XCUIApplication alloc] init];
    [app setLaunchEnvironment:@{@"ENV_KEY": envKey, @"TEST_SCENARIO": @"NORMAL_VIEW"}];
    [app launch];
    XCTestExpectation *exp = [[XCTestExpectation alloc] initWithDescription:@"Just wait for 20 seconds."];
    XCTWaiterResult result = [XCTWaiter waitForExpectations:@[exp] timeout:20.0];
    if(result != XCTWaiterResultTimedOut) {
        XCTFail(@"Interrupted while playing video.");
    }
}

- (void)testPlayLivestreamVideo {
    XCUIApplication *app = [[XCUIApplication alloc] init];
    [app setLaunchEnvironment:@{@"ENV_KEY": envKey, @"TEST_SCENARIO": @"LIVESTREAM"}];
    [app launch];
    XCTestExpectation *exp = [[XCTestExpectation alloc] initWithDescription:@"Just wait for 20 seconds."];
    XCTWaiterResult result = [XCTWaiter waitForExpectations:@[exp] timeout:20.0];
    if(result != XCTWaiterResultTimedOut) {
        XCTFail(@"Interrupted while playing video.");
    }
}

- (void)testPlayLowLatencyLivestreamVideo {
    XCUIApplication *app = [[XCUIApplication alloc] init];
    [app setLaunchEnvironment:@{@"ENV_KEY": envKey, @"TEST_SCENARIO": @"LOW_LATENCY_LIVESTREAM"}];
    [app launch];
    XCTestExpectation *exp = [[XCTestExpectation alloc] initWithDescription:@"Just wait for 20 seconds."];
    XCTWaiterResult result = [XCTWaiter waitForExpectations:@[exp] timeout:20.0];
    if(result != XCTWaiterResultTimedOut) {
        XCTFail(@"Interrupted while playing video.");
    }
}

- (void)testIMASDK {
    XCUIApplication *app = [[XCUIApplication alloc] init];
    [app setLaunchEnvironment:@{@"ENV_KEY": envKey, @"TEST_SCENARIO": @"IMA"}];
    [app launch];
    XCTestExpectation *exp = [[XCTestExpectation alloc] initWithDescription:@"Wait for launch (~5 sec) and preroll (10 sec)"];
    XCTWaiterResult result = [XCTWaiter waitForExpectations:@[exp] timeout:15.0];
    if(result != XCTWaiterResultTimedOut) {
        XCTFail(@"Interrupted while playing video.");
    }
        
    XCUIElement *element = app.otherElements[@"AVPlayerView"];
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

- (void)testAVQueuePlayer {
    XCUIApplication *app = [[XCUIApplication alloc] init];
    [app setLaunchEnvironment:@{@"ENV_KEY": envKey, @"TEST_SCENARIO": @"AV_QUEUE"}];
    [app launch];
    
    // Play the first video in the queue
    XCTestExpectation *exp = [[XCTestExpectation alloc] initWithDescription:@"Wait for 10 seconds, playing first video in queue."];
    XCTWaiterResult result = [XCTWaiter waitForExpectations:@[exp] timeout:10.0];
    if(result != XCTWaiterResultTimedOut) {
        XCTFail(@"Interrupted while playing first video.");
    }
    
    // Tap on AVPlayerView to get the controls section to display
    XCUIElement *element = app.otherElements[@"AVPlayerView"];
    [element tap];
    
    // Forward the video near the end
    XCUIElement *slider = app.sliders.firstMatch;
    XCUICoordinate *start = [slider coordinateWithNormalizedOffset:CGVectorMake(0, 0)];
    XCUICoordinate *finish = [slider coordinateWithNormalizedOffset:CGVectorMake(0.99, 0)];
    [start pressForDuration:1 thenDragToCoordinate:finish];
    
    // Play the second video in the queue
    exp = [[XCTestExpectation alloc] initWithDescription:@"Wait for 10 seconds, playing second video in queue."];
    result = [XCTWaiter waitForExpectations:@[exp] timeout:15.0];
    if(result != XCTWaiterResultTimedOut) {
        XCTFail(@"Interrupted while playing second video.");
    }
}

- (void)testUpdateCustomDimensions {
    XCUIApplication *app = [[XCUIApplication alloc] init];
    [app setLaunchEnvironment:@{@"ENV_KEY": envKey, @"TEST_SCENARIO": @"UPDATE_CUSTOM_DIMENSIONS"}];
    [app launch];
    XCTestExpectation *exp = [[XCTestExpectation alloc] initWithDescription:@"Just wait for 20 seconds."];
    XCTWaiterResult result = [XCTWaiter waitForExpectations:@[exp] timeout:20.0];
    if(result != XCTWaiterResultTimedOut) {
        XCTFail(@"Interrupted while playing video.");
    }
}

- (void)testChangeVideo {
    XCUIApplication *app = [[XCUIApplication alloc] init];
    [app setLaunchEnvironment:@{@"ENV_KEY": envKey, @"TEST_SCENARIO": @"CHANGE_VIDEO"}];
    [app launch];
    XCTestExpectation *exp = [[XCTestExpectation alloc] initWithDescription:@"Just wait for 20 seconds."];
    XCTWaiterResult result = [XCTWaiter waitForExpectations:@[exp] timeout:20.0];
    if(result != XCTWaiterResultTimedOut) {
        XCTFail(@"Interrupted while playing video.");
    }
}

- (void)testProgramChange {

    // This test should produce events on your dashboard for 3 programs.
    // Each program should have a viewStart, play, and playing events

    XCUIApplication *app = [[XCUIApplication alloc] init];
    [app setLaunchEnvironment:@{@"ENV_KEY": envKey, @"TEST_SCENARIO": @"PROGRAM_CHANGE"}];
    [app launch];
    XCTestExpectation *exp = [[XCTestExpectation alloc] initWithDescription:@"Just wait for 20 seconds."];
    XCTWaiterResult result = [XCTWaiter waitForExpectations:@[exp] timeout:90.0];
    if(result != XCTWaiterResultTimedOut) {
        XCTFail(@"Interrupted while playing video.");
    }
}

- (void)testAutomaticSeek {
    XCUIApplication *app = [[XCUIApplication alloc] init];
    [app setLaunchEnvironment:@{@"ENV_KEY": envKey, @"TEST_SCENARIO": @"AUTO_SEEK"}];
    [app launch];
    XCTestExpectation *exp = [[XCTestExpectation alloc] initWithDescription:@"Just wait for 20 seconds."];
    XCTWaiterResult result = [XCTWaiter waitForExpectations:@[exp] timeout:25.0];
    if(result != XCTWaiterResultTimedOut) {
        XCTFail(@"Interrupted while playing video.");
    }
}

- (void)testUISeek {
    XCUIApplication *app = [[XCUIApplication alloc] init];
    [app setLaunchEnvironment:@{@"ENV_KEY": envKey, @"TEST_SCENARIO": @"UI_SEEK"}];
    [app launch];
    XCTestExpectation *exp = [[XCTestExpectation alloc] initWithDescription:@"Just wait for 10 seconds."];
    XCTWaiterResult result = [XCTWaiter waitForExpectations:@[exp] timeout:10.0];
    if(result != XCTWaiterResultTimedOut) {
        XCTFail(@"Interrupted while playing video.");
    }
    XCUIElement *element = app.otherElements[@"AVPlayerView"];
    [element tap];
    
    // Seek
    XCUIElement *slider = app.sliders.firstMatch;
    XCUICoordinate *start = [slider coordinateWithNormalizedOffset:CGVectorMake(0, 0)];
    XCUICoordinate *finish = [slider coordinateWithNormalizedOffset:CGVectorMake(0.25, 0)];
    [start pressForDuration:1 thenDragToCoordinate:finish];
    
    exp = [[XCTestExpectation alloc] initWithDescription:@"Just wait for 20 seconds."];
    result = [XCTWaiter waitForExpectations:@[exp] timeout:20.0];
    if(result != XCTWaiterResultTimedOut) {
        XCTFail(@"Interrupted while playing video.");
    }
}
@end
