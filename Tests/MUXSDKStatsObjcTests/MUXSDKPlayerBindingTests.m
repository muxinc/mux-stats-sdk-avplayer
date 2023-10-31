//
//  MUXSDKPlayerBindingTests.m
//  MUXSDKStatsTests
//
//  Created by Nidhi Kulkarni on 2/3/20.
//  Copyright © 2020 Mux, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
@import AVFoundation;
@import AVKit;
@import MuxCore;
@import MUXSDKStats;
@import MUXSDKStats.Internal;

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

- (MUXSDKAVPlayerViewControllerBinding *) setupViewControllerPlayerBinding:(NSString *)name
                                                              softwareName:(NSString *)softwareName
                                                           softwareVersion:(NSString *)softwareVersion {
    MUXSDKPlayerBindingManager *sut = [[MUXSDKPlayerBindingManager alloc] init];
    MUXSDKCustomerPlayerDataStore *playerDataStore = [[MUXSDKCustomerPlayerDataStore alloc] init];
    MUXSDKCustomerVideoDataStore *videoDataStore = [[MUXSDKCustomerVideoDataStore alloc] init];
    NSMutableDictionary *vcs = [[NSMutableDictionary alloc] init];
    
    sut.customerPlayerDataStore = playerDataStore;
    sut.customerVideoDataStore = videoDataStore;
    sut.playerBindings = vcs;

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
    MUXSDKAVPlayerViewControllerBinding *binding = [[MUXSDKAVPlayerViewControllerBinding alloc] initWithPlayerName:name
                                                                                                      softwareName:softwareName
                                                                                                   softwareVersion:softwareVersion
                                                                                              playerViewController:controller];

    [vcs setObject:binding forKey:name];

    [binding attachAVPlayer:player];
    [sut dispatchNewViewForPlayerName:name];
    return binding;
}

- (MUXSDKAVPlayerBinding *) setupAVPlayerBinding:(NSString *)name
                                    softwareName:(NSString *)softwareName
                                 softwareVersion:(NSString *)softwareVersion
                                 fixedPlayerSize:(CGSize)fixedPlayerSize {
    MUXSDKPlayerBindingManager *sut = [[MUXSDKPlayerBindingManager alloc] init];
    MUXSDKCustomerPlayerDataStore *playerDataStore = [[MUXSDKCustomerPlayerDataStore alloc] init];
    MUXSDKCustomerVideoDataStore *videoDataStore = [[MUXSDKCustomerVideoDataStore alloc] init];
    NSMutableDictionary *vcs = [[NSMutableDictionary alloc] init];

    sut.customerPlayerDataStore = playerDataStore;
    sut.customerVideoDataStore = videoDataStore;
    sut.playerBindings = vcs;

    // Set up player
    NSURL *url = [[NSURL alloc] initWithString:@"https://foo.mp4"];
    AVPlayer *player = [AVPlayer playerWithURL:url];

    // Set up customer metadata
    MUXSDKCustomerPlayerData *customerPlayerData = [[MUXSDKCustomerPlayerData alloc] initWithEnvironmentKey:@"A KEY"];
    MUXSDKCustomerVideoData *customerVideoData = [[MUXSDKCustomerVideoData alloc] init];
    [customerVideoData setVideoTitle:@"01234"];
    [playerDataStore setPlayerData:customerPlayerData forPlayerName:name];
    [videoDataStore setVideoData:customerVideoData forPlayerName:name];

    // Create Player Binding
    MUXSDKAVPlayerBinding *binding = [[MUXSDKAVPlayerBinding alloc] initWithPlayerName:name
                                                                          softwareName:softwareName
                                                                       softwareVersion:softwareVersion
                                                                       fixedPlayerSize:fixedPlayerSize];
    [vcs setObject:binding forKey:name];

    [binding attachAVPlayer:player];
    [sut dispatchNewViewForPlayerName:name];
    return binding;
}

- (void)testPlayerBindingManagerStartsNewViews {
    NSString *name = @"Test";
    [self setupViewControllerPlayerBinding:name
                              softwareName:@"TestSoftware"
                           softwareVersion:@"0.1.0"];

    XCTAssertEqual(3, [MUXSDKCore eventsCountForPlayer:name]);
    id<MUXSDKEventTyping> event0 = [MUXSDKCore eventAtIndex:0 forPlayer:name];
    id<MUXSDKEventTyping> event1 = [MUXSDKCore eventAtIndex:1 forPlayer:name];
    id<MUXSDKEventTyping> event2 = [MUXSDKCore eventAtIndex:2 forPlayer:name];
    
    XCTAssertEqual([event0 getType], MUXSDKPlaybackEventViewInitEventType);
    XCTAssertEqual([event1 getType], MUXSDKDataEventType);
    XCTAssertEqual([event2 getType], MUXSDKPlaybackEventPlayerReadyEventType);
}

- (void)testAVPlayerViewControllerBindingAutomaticErrorTrackingEnabled {
    NSString *name = @"awesome-player";
    MUXSDKAVPlayerViewControllerBinding *binding = [self setupViewControllerPlayerBinding:name
                                                                             softwareName:@"TestSoftware"
                                                                          softwareVersion:@"0.1.0"];

    [binding dispatchError];
    XCTAssertEqual(5, [MUXSDKCore eventsCountForPlayer:name]);
    id<MUXSDKEventTyping> event = [MUXSDKCore eventAtIndex:4 forPlayer:name];
    XCTAssertEqual([event getType], MUXSDKPlaybackEventErrorEventType);

    MUXSDKPlaybackEvent *playbackEvent = (MUXSDKPlaybackEvent *)event;
    XCTAssertEqual(
                   playbackEvent.playerData.playerSoftwareName,
                   @"TestSoftware"
                   );

    XCTAssertEqual(
                   playbackEvent.playerData.playerSoftwareVersion,
                   @"0.1.0"
                   );
}

- (void)testAVPlayerViewControllerBindingAutomaticErrorTrackingDisabled {
    NSString *name = @"awesome-player";
    MUXSDKAVPlayerViewControllerBinding *binding = [self setupViewControllerPlayerBinding:name
                                                                             softwareName:@"TestSoftware"
                                                                          softwareVersion:@"0.1.0"];
    [binding setAutomaticErrorTracking:false];

    [binding dispatchError];
    XCTAssertEqual(3, [MUXSDKCore eventsCountForPlayer:name]);
    id<MUXSDKEventTyping> event = [MUXSDKCore eventAtIndex:2 forPlayer:name];
    XCTAssertEqual([event getType], MUXSDKPlaybackEventPlayerReadyEventType);

    MUXSDKPlaybackEvent *playbackEvent = (MUXSDKPlaybackEvent *)event;
    XCTAssertEqual(
                   playbackEvent.playerData.playerSoftwareName,
                   @"TestSoftware"
                   );

    XCTAssertEqual(
                   playbackEvent.playerData.playerSoftwareVersion,
                   @"0.1.0"
                   );
}

- (void)testAVPlayerBindingAutomaticErrorTrackingEnabled {
    NSString *name = @"awesome-player";
    MUXSDKAVPlayerBinding *binding = [self setupAVPlayerBinding:name
                                                   softwareName:@"TestSoftware"
                                                softwareVersion:@"0.1.0"
                                                fixedPlayerSize:CGSizeMake(100.0, 100.0)];

    [binding dispatchViewInit];
    [binding dispatchPlayerReady];
    [binding dispatchPlay];
    [binding dispatchPlaying];

    NSUInteger count = [MUXSDKCore eventsCountForPlayer:name];

    for (NSInteger index = 0; index < count; index++) {
        id<MUXSDKEventTyping> event = [MUXSDKCore eventAtIndex:index
                                                     forPlayer:name];
        if (event.isPlayback) {
            MUXSDKPlaybackEvent *playbackEvent = (MUXSDKPlaybackEvent *)event;

            XCTAssertEqualWithAccuracy(
                           playbackEvent.playerData.playerHeight.floatValue,
                           100.0,
                           0.01
                           );
            XCTAssertEqualWithAccuracy(
                           playbackEvent.playerData.playerWidth.floatValue,
                           100.0,
                            0.01
                           );

            XCTAssertEqual(
                           playbackEvent.playerData.playerSoftwareName,
                           @"TestSoftware"
                           );

            XCTAssertEqual(
                           playbackEvent.playerData.playerSoftwareVersion,
                           @"0.1.0"
                           );
        }

    }

    id<MUXSDKEventTyping> event = [MUXSDKCore eventAtIndex:2 forPlayer:name];
    XCTAssertEqual([event getType], MUXSDKPlaybackEventPlayerReadyEventType);

}

- (void)testAVPlayerBindingAutomaticErrorTrackingDisabled {
    NSString *name = @"awesome-player";
    MUXSDKAVPlayerBinding *binding = [self setupAVPlayerBinding:name
                                                   softwareName:@"TestSoftware"
                                                softwareVersion:@"0.1.0"
                                                fixedPlayerSize:CGSizeMake(100.0, 100.0)];
    [binding setAutomaticErrorTracking:false];

    [binding dispatchViewInit];
    [binding dispatchPlayerReady];
    [binding dispatchPlay];
    [binding dispatchPlaying];

    NSUInteger count = [MUXSDKCore eventsCountForPlayer:name];

    for (NSInteger index = 0; index < count; index++) {
        id<MUXSDKEventTyping> event = [MUXSDKCore eventAtIndex:index
                                                     forPlayer:name];
        if (event.isPlayback) {
            MUXSDKPlaybackEvent *playbackEvent = (MUXSDKPlaybackEvent *)event;

            XCTAssertEqualWithAccuracy(
                           playbackEvent.playerData.playerHeight.floatValue,
                           100.0,
                           0.01
                           );
            XCTAssertEqualWithAccuracy(
                           playbackEvent.playerData.playerWidth.floatValue,
                           100.0,
                            0.01
                           );

            XCTAssertEqual(
                           playbackEvent.playerData.playerSoftwareName,
                           @"TestSoftware"
                           );

            XCTAssertEqual(
                           playbackEvent.playerData.playerSoftwareVersion,
                           @"0.1.0"
                           );

        }

    }

    id<MUXSDKEventTyping> event = [MUXSDKCore eventAtIndex:2 
                                                 forPlayer:name];
    XCTAssertEqual([event getType], MUXSDKPlaybackEventPlayerReadyEventType);
}

@end
