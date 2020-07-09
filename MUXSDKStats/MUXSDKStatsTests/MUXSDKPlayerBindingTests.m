//
//  MUXSDKPlayerBindingTests.m
//  MUXSDKStatsTests
//
//  Created by Nidhi Kulkarni on 2/3/20.
//  Copyright © 2020 Mux, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "MUXSDKPlayerBindingManager.h"
#import "MUXSDKCustomerPlayerDataStore.h"
#import "MUXSDKCustomerVideoDataStore.h"
#import "MUXSDKCore+Mock.h"

@interface MUXSDKPlayerBindingTests : XCTestCase

@end

@implementation MUXSDKPlayerBindingTests

- (void) setUp {
    [MUXSDKCore swizzleDispatchEvents];
    [MUXSDKCore resetCapturedEvents];
}

- (void) tearDown {
    [MUXSDKCore swizzleDispatchEvents];
    [MUXSDKCore resetCapturedEvents];
}

- (MUXSDKAVPlayerViewControllerBinding *) setupViewControllerPlayerBinding:(NSString *)name {
    MUXSDKPlayerBindingManager *sut = [[MUXSDKPlayerBindingManager alloc] init];
    MUXSDKCustomerPlayerDataStore *playerDataStore = [[MUXSDKCustomerPlayerDataStore alloc] init];
    MUXSDKCustomerVideoDataStore *videoDataStore = [[MUXSDKCustomerVideoDataStore alloc] init];
    NSMutableDictionary *vcs = [[NSMutableDictionary alloc] init];
    
    sut.customerPlayerDataStore = playerDataStore;
    sut.customerVideoDataStore = videoDataStore;
    sut.viewControllers = vcs;
    
    // Set up player
    NSString *software = @"Software";
    NSURL *url = [[NSURL alloc] initWithString:@"https://foo.mp4"];
    AVPlayer *player = [AVPlayer playerWithURL:url];
    AVPlayerViewController *controller = [[AVPlayerViewController alloc] init];
    controller.player = player;
    
    // Set up customer metadata
    MUXSDKCustomerPlayerData *customerPlayerData = [[MUXSDKCustomerPlayerData alloc] initWithEnvironmentKey:@"A KEY"];
    MUXSDKCustomerVideoData *customerVideoData = [[MUXSDKCustomerVideoData alloc] init];
    [customerVideoData setVideoTitle:@"01234"];
    [playerDataStore setPlayerData:customerPlayerData forPlayerName:name];
    [videoDataStore setVideoData:customerVideoData forPlayerName:name];
    
    // Create Player Binding
    MUXSDKAVPlayerViewControllerBinding *binding = [[MUXSDKAVPlayerViewControllerBinding alloc] initWithName:name software:software andView:controller];
    [vcs setObject:binding forKey:name];
    
    [binding attachAVPlayer:player];
    [sut newViewForPlayer:name];
    return binding;
}

- (void)testPlayerBindingManagerStartsNewViews {
    NSString *name = @"Test";
    [self setupViewControllerPlayerBinding:name];
    
    XCTAssertEqual(3, [MUXSDKCore eventsCountForPlayer:name]);
    id<MUXSDKEventTyping> event0 = [MUXSDKCore eventAtIndex:0 forPlayer:name];
    id<MUXSDKEventTyping> event1 = [MUXSDKCore eventAtIndex:1 forPlayer:name];
    id<MUXSDKEventTyping> event2 = [MUXSDKCore eventAtIndex:2 forPlayer:name];
    
    XCTAssertEqual([event0 getType], MUXSDKPlaybackEventViewInitEventType);
    XCTAssertEqual([event1 getType], MUXSDKDataEventType);
    XCTAssertEqual([event2 getType], MUXSDKPlaybackEventPlayerReadyEventType);
}

- (void)testPlayerBindingAutomaticErrorTrackingEnabled {
    NSString *name = @"awesome-player";
    MUXSDKAVPlayerViewControllerBinding *binding = [self setupViewControllerPlayerBinding:name];

    [binding dispatchError];
    XCTAssertEqual(5, [MUXSDKCore eventsCountForPlayer:name]);
    id<MUXSDKEventTyping> event = [MUXSDKCore eventAtIndex:4 forPlayer:name];
    XCTAssertEqual([event getType], MUXSDKPlaybackEventErrorEventType);

}

- (void)testPlayerBindingAutomaticErrorTrackingDisabled {
    NSString *name = @"awesome-player";
    MUXSDKAVPlayerViewControllerBinding *binding = [self setupViewControllerPlayerBinding:name];
    [binding setAutomaticErrorTracking:false];

    [binding dispatchError];
    XCTAssertEqual(3, [MUXSDKCore eventsCountForPlayer:name]);
    id<MUXSDKEventTyping> event = [MUXSDKCore eventAtIndex:2 forPlayer:name];
    XCTAssertEqual([event getType], MUXSDKPlaybackEventPlayerReadyEventType);
}



@end
