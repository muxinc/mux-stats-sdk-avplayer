//
//  MUXSDKStatsTests.m
//  MUXSDKStatsTests
//
//  Created by Matt Ward on 11/2/16.
//  Copyright © 2016 Mux, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "MUXSDKStats.h"
#import "MUXSDKCore+Mock.h"

@import AVKit;
@import AVFoundation;
@import MuxCore;

@interface MuxMockAVPlayerViewController : AVPlayerViewController
@end

@implementation MuxMockAVPlayerViewController
- (id)init {
    if (self = [super init]) {
        self.player = [[AVPlayer alloc] init];
    }
    return self;
}
@end

@interface MuxMockAVPlayerLayer : AVPlayerLayer
@end

@implementation MuxMockAVPlayerLayer
- (id)init {
    if (self = [super init]) {
        self.player = [[AVPlayer alloc] init];
    }
    return self;
}
@end

@interface MUXSDKStatsTests : XCTestCase
@end

@implementation MUXSDKStatsTests

- (void)setUp {
    [super setUp];
    [MUXSDKCore swizzleDispatchEvents];
    [MUXSDKCore resetCapturedEvents];
}

- (void)tearDown {
    [MUXSDKCore swizzleDispatchEvents];
    [MUXSDKCore resetCapturedEvents];
    [super tearDown];
}

- (void) assertEventType:(NSString *)expectedType forPlayer:(NSString *)name atIndex:(NSUInteger)index {
    id<MUXSDKEventTyping> event = [MUXSDKCore eventAtIndex:index forPlayer:name];
    NSString *actualType = [event getType];
    XCTAssertEqual(actualType, expectedType, @"Expected %@, got: %@", expectedType, actualType);
}

- (void)testVideoChangeForAVPlayerLayer{
    MuxMockAVPlayerLayer *controller = [[MuxMockAVPlayerLayer alloc] init];
    MUXSDKCustomerPlayerData *customerPlayerData = [[MUXSDKCustomerPlayerData alloc] initWithEnvironmentKey:@"ENV_KEY"];
    MUXSDKCustomerVideoData *customerVideoData = [[MUXSDKCustomerVideoData alloc] init];
    [customerVideoData setVideoTitle:@"01234"];
    NSString *playName = @"Player1";
    MUXSDKPlayerBinding *playerBinding = [MUXSDKStats monitorAVPlayerLayer:controller withPlayerName:playName playerData:customerPlayerData videoData:customerVideoData];
    XCTAssertNotNil(playerBinding, "expected monitorAVPlayerLayer to return a playerBinding");
    [customerVideoData setVideoTitle:@"56789"];
    [MUXSDKStats videoChangeForPlayer:playName withVideoData:customerVideoData];
    [MUXSDKStats destroyPlayer:playName];
    XCTAssertEqual(4, [MUXSDKCore eventsCountForPlayer:playName]);
    [self assertEventType:MUXSDKPlaybackEventViewInitEventType forPlayer:playName atIndex:0];
    [self assertEventType:MUXSDKDataEventType forPlayer:playName atIndex:1];
    [self assertEventType:MUXSDKPlaybackEventPlayerReadyEventType forPlayer:playName atIndex:2];
    [self assertEventType:MUXSDKPlaybackEventViewEndEventType forPlayer:playName atIndex:3];
}

- (void)testVideoChangeForAVPlayerViewController{
    MuxMockAVPlayerViewController *controller = [[MuxMockAVPlayerViewController alloc] init];
    MUXSDKCustomerPlayerData *customerPlayerData = [[MUXSDKCustomerPlayerData alloc] initWithEnvironmentKey:@"ENV_KEY"];
    MUXSDKCustomerVideoData *customerVideoData = [[MUXSDKCustomerVideoData alloc] init];
    [customerVideoData setVideoTitle:@"01234"];
    NSString *playName = @"Player2";
    MUXSDKPlayerBinding *playerBinding = [MUXSDKStats monitorAVPlayerViewController:controller withPlayerName:playName playerData:customerPlayerData videoData:customerVideoData];
    XCTAssertNotNil(playerBinding, "expected monitorAVPlayerViewController to return a playerBinding");
    [customerVideoData setVideoTitle:@"56789"];
    [MUXSDKStats videoChangeForPlayer:playName withVideoData:customerVideoData];
    XCTAssertEqual(4, [MUXSDKCore eventsCountForPlayer:playName]);
    [self assertEventType:MUXSDKPlaybackEventViewInitEventType forPlayer:playName atIndex:0];
    [self assertEventType:MUXSDKDataEventType forPlayer:playName atIndex:1];
    [self assertEventType:MUXSDKPlaybackEventPlayerReadyEventType forPlayer:playName atIndex:2];
    [self assertEventType:MUXSDKPlaybackEventViewEndEventType forPlayer:playName atIndex:3];
}

- (void)testupdateCustomerDataWithNulls{
    MuxMockAVPlayerLayer *controller = [[MuxMockAVPlayerLayer alloc] init];
    MUXSDKCustomerPlayerData *customerPlayerData = [[MUXSDKCustomerPlayerData alloc] initWithEnvironmentKey:@"ENV_KEY"];
    MUXSDKCustomerVideoData *customerVideoData = [[MUXSDKCustomerVideoData alloc] init];
    NSString *playName = @"Player3";
    [MUXSDKStats monitorAVPlayerLayer:controller withPlayerName:playName playerData:customerPlayerData videoData:customerVideoData];
    [MUXSDKStats updateCustomerDataForPlayer:playName withPlayerData:NULL withVideoData:NULL];
    [MUXSDKStats destroyPlayer:playName];
    XCTAssertEqual(3, [MUXSDKCore eventsCountForPlayer:playName]);
    [self assertEventType:MUXSDKPlaybackEventViewInitEventType forPlayer:playName atIndex:0];
    [self assertEventType:MUXSDKDataEventType forPlayer:playName atIndex:1];
    [self assertEventType:MUXSDKPlaybackEventPlayerReadyEventType forPlayer:playName atIndex:2];
}

- (void)testupdateCustomerDataWithPlayerDataAndNullVideoData{
    MuxMockAVPlayerLayer *controller = [[MuxMockAVPlayerLayer alloc] init];
    MUXSDKCustomerPlayerData *customerPlayerData = [[MUXSDKCustomerPlayerData alloc] initWithEnvironmentKey:@"ENV_KEY"];
    MUXSDKCustomerVideoData *customerVideoData = [[MUXSDKCustomerVideoData alloc] init];
    NSString *playName = @"Player4";
    [MUXSDKStats monitorAVPlayerLayer:controller withPlayerName:playName playerData:customerPlayerData videoData:customerVideoData];
    [customerPlayerData setPlayerVersion:@"playerVersionV1"];
    [MUXSDKStats updateCustomerDataForPlayer:playName withPlayerData:customerPlayerData withVideoData:NULL];
    [MUXSDKStats destroyPlayer:playName];
    XCTAssertEqual(4, [MUXSDKCore eventsCountForPlayer:playName]);
    [self assertEventType:MUXSDKPlaybackEventViewInitEventType forPlayer:playName atIndex:0];
    [self assertEventType:MUXSDKDataEventType forPlayer:playName atIndex:1];
    [self assertEventType:MUXSDKPlaybackEventPlayerReadyEventType forPlayer:playName atIndex:2];
    [self assertEventType:MUXSDKDataEventType forPlayer:playName atIndex:3];
}

- (void)testupdateCustomerDataWithNullPlayerDataAndVideoData{
    MuxMockAVPlayerLayer *controller = [[MuxMockAVPlayerLayer alloc] init];
    MUXSDKCustomerPlayerData *customerPlayerData = [[MUXSDKCustomerPlayerData alloc] initWithEnvironmentKey:@"ENV_KEY"];
    MUXSDKCustomerVideoData *customerVideoData = [[MUXSDKCustomerVideoData alloc] init];
    NSString *playName = @"Player5";
    [MUXSDKStats monitorAVPlayerLayer:controller withPlayerName:playName playerData:customerPlayerData videoData:customerVideoData];
    [customerVideoData setVideoTitle:@"Updated VideoTitle"];
    [MUXSDKStats updateCustomerDataForPlayer:playName withPlayerData:NULL withVideoData:customerVideoData];
    [MUXSDKStats destroyPlayer:playName];
    XCTAssertEqual(4, [MUXSDKCore eventsCountForPlayer:playName]);
    [self assertEventType:MUXSDKPlaybackEventViewInitEventType forPlayer:playName atIndex:0];
    [self assertEventType:MUXSDKDataEventType forPlayer:playName atIndex:1];
    [self assertEventType:MUXSDKPlaybackEventPlayerReadyEventType forPlayer:playName atIndex:2];
    [self assertEventType:MUXSDKDataEventType forPlayer:playName atIndex:3];
}


- (void)testProgramChangeForAVPlayerViewController{
    MuxMockAVPlayerViewController *controller = [[MuxMockAVPlayerViewController alloc] init];
    MUXSDKCustomerPlayerData *customerPlayerData = [[MUXSDKCustomerPlayerData alloc] initWithEnvironmentKey:@"ENV_KEY"];
    MUXSDKCustomerVideoData *customerVideoData = [[MUXSDKCustomerVideoData alloc] init];
    [customerVideoData setVideoTitle:@"01234"];
    NSString *playName = @"Player6";
    MUXSDKPlayerBinding *playerBinding = [MUXSDKStats monitorAVPlayerViewController:controller withPlayerName:playName playerData:customerPlayerData videoData:customerVideoData];
    XCTAssertNotNil(playerBinding, "expected monitorAVPlayerViewController to return a playerBinding");
    [customerVideoData setVideoTitle:@"56789"];
    [MUXSDKStats programChangeForPlayer:playName withVideoData:customerVideoData];
    XCTAssertEqual(6, [MUXSDKCore eventsCountForPlayer:playName]);
    [self assertEventType:MUXSDKPlaybackEventViewInitEventType forPlayer:playName atIndex:0];
    [self assertEventType:MUXSDKDataEventType forPlayer:playName atIndex:1];
    [self assertEventType:MUXSDKPlaybackEventPlayerReadyEventType forPlayer:playName atIndex:2];
    [self assertEventType:MUXSDKPlaybackEventViewEndEventType forPlayer:playName atIndex:3];
    [self assertEventType:MUXSDKPlaybackEventPlayEventType forPlayer:playName atIndex:4];
    [self assertEventType:MUXSDKPlaybackEventPlayingEventType forPlayer:playName atIndex:5];
}

@end
