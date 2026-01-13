//
//  MUXSDKPlayerBindingTests.m
//  MUXSDKStatsTests
//
//  Created by Nidhi Kulkarni on 2/3/20.
//  Copyright © 2020 Mux, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "MUXSDKPlayerBinding+ViewState.h"
#import "MUXSDKPlayerBindingManager.h"
#import "MUXSDKCustomerPlayerDataStore.h"
#import "MUXSDKCustomerVideoDataStore.h"
#import "Utils/MUXSDKCore+Mock.h"

#define MUXSDKUniquePlayerName() [NSString stringWithFormat:@"Player for %s (%@)", __PRETTY_FUNCTION__, NSUUID.UUID.UUIDString]

@interface MUXSDKPlayerBindingTests : XCTestCase

@end

@implementation MUXSDKPlayerBindingTests

- (void) setUp {
    self.continueAfterFailure = NO;
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
    NSURL *url = [[NSURL alloc] initWithString:@"https://foo.mp4"];
    AVPlayer *player = [AVPlayer playerWithURL:url];
    AVPlayerViewController *controller = [[AVPlayerViewController alloc] init];
    controller.player = player;
    
    // Set up customer metadata
    MUXSDKCustomerPlayerData *customerPlayerData = [[MUXSDKCustomerPlayerData alloc] initWithEnvironmentKey:@"A KEY"];
    customerPlayerData.playerSoftwareName = softwareName;
    customerPlayerData.playerSoftwareVersion = softwareVersion;
    MUXSDKCustomerVideoData *customerVideoData = [[MUXSDKCustomerVideoData alloc] init];
    [customerVideoData setVideoTitle:@"01234"];

    MUXSDKCustomerData *customerData = [MUXSDKCustomerData new];
    customerData.customerPlayerData = customerPlayerData;
    customerData.customerVideoData = customerVideoData;

    // Create Player Binding
    __kindof MUXSDKPlayerBinding *binding = [MUXSDKStats monitorAVPlayerViewController:controller
                                                                        withPlayerName:name
                                                                          customerData:customerData
                                                                automaticErrorTracking:YES
                                                                beaconCollectionDomain:nil];
    XCTAssert([binding isKindOfClass:MUXSDKAVPlayerViewControllerBinding.class]);
    XCTAssertEqual(binding.state, MUXSDKPlayerStateReady);
    return binding;
}

- (MUXSDKFixedPlayerSizeBinding *) setupAVPlayerBinding:(NSString *)name
                                    softwareName:(NSString *)softwareName
                                 softwareVersion:(NSString *)softwareVersion
                                 fixedPlayerSize:(CGSize)fixedPlayerSize {
    // Set up player
    NSURL *url = [[NSURL alloc] initWithString:@"https://foo.mp4"];
    AVPlayer *player = [AVPlayer playerWithURL:url];

    // Set up customer metadata
    MUXSDKCustomerPlayerData *customerPlayerData = [[MUXSDKCustomerPlayerData alloc] initWithEnvironmentKey:@"A KEY"];
    customerPlayerData.playerSoftwareName = softwareName;
    customerPlayerData.playerSoftwareVersion = softwareVersion;
    MUXSDKCustomerVideoData *customerVideoData = [[MUXSDKCustomerVideoData alloc] init];
    [customerVideoData setVideoTitle:@"01234"];

    MUXSDKCustomerData *customerData = [MUXSDKCustomerData new];
    customerData.customerPlayerData = customerPlayerData;
    customerData.customerVideoData = customerVideoData;

    // Create Player Binding
    __kindof MUXSDKPlayerBinding *binding = [MUXSDKStats monitorAVPlayer:player
                                                          withPlayerName:name
                                                         fixedPlayerSize:fixedPlayerSize
                                                            customerData:customerData
                                                  automaticErrorTracking:YES
                                                  beaconCollectionDomain:nil];
    XCTAssert([binding isKindOfClass:MUXSDKFixedPlayerSizeBinding.class]);
    XCTAssertEqual(binding.state, MUXSDKPlayerStateReady);
    return binding;
}

- (void)testPlayerBindingStateUnknownAtInitialization {
    MUXSDKPlayerBinding *binding = [[MUXSDKPlayerBinding alloc] initWithName:MUXSDKUniquePlayerName()
                                                                 andSoftware:@"TestSoftware"];
    XCTAssertEqual(binding.state, MUXSDKPlayerStateUnknown);
}

- (void)testPlayerBindingManagerStartsNewViews {
    NSString *name = MUXSDKUniquePlayerName();
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
    NSString *name = MUXSDKUniquePlayerName();
    MUXSDKAVPlayerViewControllerBinding *binding = [self setupViewControllerPlayerBinding:name
                                                                             softwareName:@"TestSoftware"
                                                                          softwareVersion:@"0.1.0"];

    [binding dispatchError];
    XCTAssertEqual(binding.state, MUXSDKPlayerStateError);
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

- (void)testAVPlayerViewControllerBindingErrorMetadata {
    NSString *name = MUXSDKUniquePlayerName();
    MUXSDKAVPlayerViewControllerBinding *binding = [self setupViewControllerPlayerBinding:name
                                                                             softwareName:@"TestSoftware"
                                                                          softwareVersion:@"0.1.0"];

    [binding dispatchError:@"1" withMessage:@"message" withErrorContext:@"context"];
    
    XCTAssertEqual(5, [MUXSDKCore eventsCountForPlayer:name]);
    id<MUXSDKEventTyping> event = [MUXSDKCore eventAtIndex:4 forPlayer:name];
    XCTAssertEqual([event getType], MUXSDKPlaybackEventErrorEventType);

    MUXSDKPlaybackEvent *playbackEvent = (MUXSDKPlaybackEvent *)event;
    XCTAssertEqual(
                   playbackEvent.playerData.playerErrorCode,
                   @"1"
                   );
    XCTAssertEqual(
                   playbackEvent.playerData.playerErrorMessage,
                   @"message"
                   );
    XCTAssertEqual(
                   playbackEvent.playerData.playerErrorContext,
                   @"context"
                   );
}

- (void)testAVPlayerViewControllerBindingErrorSeverity {
    NSString *name = MUXSDKUniquePlayerName();
    MUXSDKAVPlayerViewControllerBinding *binding = [self setupViewControllerPlayerBinding:name
                                                                             softwareName:@"TestSoftware"
                                                                          softwareVersion:@"0.1.0"];
    [binding dispatchError:@"1"
               withMessage:@"message"
                  severity:MUXSDKErrorSeverityWarning
              errorContext:@"context"];

    XCTAssertEqual(5, [MUXSDKCore eventsCountForPlayer:name]);
    id<MUXSDKEventTyping> event = [MUXSDKCore eventAtIndex:4 forPlayer:name];
    XCTAssertEqual([event getType], MUXSDKPlaybackEventErrorEventType);

    MUXSDKErrorEvent *errorEvent = (MUXSDKErrorEvent *)event;
    XCTAssertEqual(
                   errorEvent.playerData.playerErrorCode,
                   @"1"
                   );
    XCTAssertEqual(
                   errorEvent.playerData.playerErrorMessage,
                   @"message"
                   );
    XCTAssertEqual(
                   errorEvent.playerData.playerErrorContext,
                   @"context"
                   );
    XCTAssertEqual(
                   errorEvent.severity,
                   MUXSDKErrorSeverityWarning
                   );
}

- (void)testAVPlayerViewControllerBindingErrorBusinessException {
    NSString *name = MUXSDKUniquePlayerName();
    MUXSDKAVPlayerViewControllerBinding *binding = [self setupViewControllerPlayerBinding:name
                                                                             softwareName:@"TestSoftware"
                                                                          softwareVersion:@"0.1.0"];
    [binding dispatchError:@"1"
               withMessage:@"message"
                  severity:MUXSDKErrorSeverityWarning
       isBusinessException:YES
              errorContext:@"context"];

    XCTAssertEqual(5, [MUXSDKCore eventsCountForPlayer:name]);
    id<MUXSDKEventTyping> event = [MUXSDKCore eventAtIndex:4 forPlayer:name];
    XCTAssertEqual([event getType], MUXSDKPlaybackEventErrorEventType);

    MUXSDKErrorEvent *errorEvent = (MUXSDKErrorEvent *)event;
    XCTAssertEqual(
                   errorEvent.playerData.playerErrorCode,
                   @"1"
                   );
    XCTAssertEqual(
                   errorEvent.playerData.playerErrorMessage,
                   @"message"
                   );
    XCTAssertEqual(
                   errorEvent.playerData.playerErrorContext,
                   @"context"
                   );
    XCTAssertEqual(
                   errorEvent.severity,
                   MUXSDKErrorSeverityWarning
                   );
    XCTAssertTrue(
                  errorEvent.isBusinessException
                  );
}

- (void)testAVPlayerViewControllerBindingAutomaticErrorTrackingDisabled {
    NSString *name = MUXSDKUniquePlayerName();
    MUXSDKAVPlayerViewControllerBinding *binding = [self setupViewControllerPlayerBinding:name
                                                                             softwareName:@"TestSoftware"
                                                                          softwareVersion:@"0.1.0"];
    [binding setAutomaticErrorTracking:false];

    [binding dispatchError];
    XCTAssertNotEqual(binding.state, MUXSDKPlayerStateError);
    XCTAssertEqual(3, [MUXSDKCore eventsCountForPlayer:name]);
    id<MUXSDKEventTyping> event = [MUXSDKCore eventAtIndex:2 forPlayer:name];
    XCTAssertEqual([event getType], MUXSDKPlaybackEventPlayerReadyEventType);

    MUXSDKPlaybackEvent *playbackEvent = (MUXSDKPlaybackEvent *)event;
    XCTAssertEqualObjects(
                   playbackEvent.playerData.playerSoftwareName,
                   @"TestSoftware"
                   );

    XCTAssertEqualObjects(
                   playbackEvent.playerData.playerSoftwareVersion,
                   @"0.1.0"
                   );
}

- (void)testAVPlayerBindingAutomaticErrorTrackingEnabled {
    NSString *name = MUXSDKUniquePlayerName();
    MUXSDKFixedPlayerSizeBinding *binding = [self setupAVPlayerBinding:name
                                                   softwareName:@"TestSoftware"
                                                softwareVersion:@"0.1.0"
                                                fixedPlayerSize:CGSizeMake(100.0, 100.0)];
    XCTAssertEqual(binding.state, MUXSDKPlayerStateReady);
    [binding dispatchPlay];
    XCTAssertEqual(binding.state, MUXSDKPlayerStatePlay);
    [binding dispatchPlaying];
    XCTAssertEqual(binding.state, MUXSDKPlayerStatePlaying);

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

            XCTAssertEqualObjects(
                           playbackEvent.playerData.playerSoftwareName,
                           @"TestSoftware"
                           );

            XCTAssertEqualObjects(
                           playbackEvent.playerData.playerSoftwareVersion,
                           @"0.1.0"
                           );
        }
    }

    id<MUXSDKEventTyping> event = [MUXSDKCore eventAtIndex:2 forPlayer:name];
    XCTAssertEqual([event getType], MUXSDKPlaybackEventPlayerReadyEventType);
}

- (void)testAVPlayerBindingAutomaticErrorTrackingDisabled {
    NSString *name = MUXSDKUniquePlayerName();
    MUXSDKFixedPlayerSizeBinding *binding = [self setupAVPlayerBinding:name
                                                   softwareName:@"TestSoftware"
                                                softwareVersion:@"0.1.0"
                                                fixedPlayerSize:CGSizeMake(100.0, 100.0)];
    [binding setAutomaticErrorTracking:false];

    XCTAssertEqual(binding.state, MUXSDKPlayerStateReady);
    [binding dispatchPlay];
    XCTAssertEqual(binding.state, MUXSDKPlayerStatePlay);
    [binding dispatchPlaying];
    XCTAssertEqual(binding.state, MUXSDKPlayerStatePlaying);

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

            XCTAssertEqualObjects(
                           playbackEvent.playerData.playerSoftwareName,
                           @"TestSoftware"
                           );

            XCTAssertEqualObjects(
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
