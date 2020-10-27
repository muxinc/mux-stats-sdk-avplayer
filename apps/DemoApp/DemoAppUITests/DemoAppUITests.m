//
//  DemoAppUITests.m
//  DemoAppUITests
//
//  Created by Nidhi Kulkarni on 10/27/20.
//  Copyright © 2020 Mux, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>

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

- (void)testExample {
    // UI tests must launch the application that they test.
    XCUIApplication *app = [[XCUIApplication alloc] init];
    [app launch];
    XCTestExpectation *exp = [[XCTestExpectation alloc] initWithDescription:@"Just wait for 10 seconds."];
    XCTWaiterResult result = [XCTWaiter waitForExpectations:@[exp] timeout:10.0];
    // Use recording to get started writing UI tests.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
}

@end
