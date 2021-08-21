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
#import "MUXSDKPlayerBindingConstants.h"
#if __has_feature(modules)
@import MuxCore;
#else
#if TVOS
#import <MuxCore/MuxCoreTv.h>
#else
#import <MuxCore/MuxCore.h>
#endif
#endif

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
static const NSString *BANDWIDTH = @"BANDWIDTH";
static const NSString *FRAMERATE = @"FRAME-RATE";
static const NSString *X = @"X";
static const NSString *Y = @"Y";
static const NSString *Z = @"Z";

- (void) setUp {
    [super setUp];
    [MUXSDKCore swizzleDispatchEvents];
    [MUXSDKCore resetCapturedEvents];
}

- (void) tearDown {
    [super tearDown];
    [MUXSDKCore swizzleDispatchEvents];
    [MUXSDKCore resetCapturedEvents];
}

- (void) assertDispatchedGlobalEventTypes:(NSArray *) expectedEventTypes {
    NSInteger expectedCount = expectedEventTypes.count;
    NSInteger actualCount = [MUXSDKCore globalEventsCount];
    XCTAssertEqual(expectedCount, actualCount, @"expected: %ld events got: %ld events.", (long)expectedCount, (long)actualCount);
    for (int i = 0; i < expectedEventTypes.count; i++) {
        MUXSDKDataEvent *event = [MUXSDKCore globalEventAtIndex:i];
        NSString *expectedType = [expectedEventTypes objectAtIndex:i];
        NSString *actualType = [event getType];
        XCTAssertEqual(expectedType, actualType, @"index [%d] expected event type: %@ got event type: %@", i, expectedType, actualType);
    }
}

- (void) assertPlayer:(NSString *)name dispatchedPlaybackEvents:(NSDictionary *) expectedViewData {
    MUXSDKPlaybackEvent *playbackEvent;
    MUXSDKViewData *viewData;
    NSDictionary *expected;
    for (id key in expectedViewData) {
        expected = [expectedViewData objectForKey:key];
        playbackEvent = (MUXSDKPlaybackEvent * ) [MUXSDKCore eventAtIndex:[key intValue] forPlayer:name];
        viewData = [playbackEvent viewData];
        if ([expected isEqual:[NSNull null]]) {
            XCTAssertNil(viewData);
        } else {
            XCTAssertEqual([expected objectForKey:X], viewData.viewDeviceOrientationData.x);
            XCTAssertEqual([expected objectForKey:Y], viewData.viewDeviceOrientationData.y);
            XCTAssertEqual([expected objectForKey:Z], viewData.viewDeviceOrientationData.z);
        }
    }
}

- (void) assertPlayer:(NSString *)name dispatchedEventTypes:(NSArray *) expectedEventTypes {
    NSInteger expectedCount = expectedEventTypes.count;
    NSInteger actualCount = [MUXSDKCore eventsCountForPlayer:name];
    XCTAssertEqual(expectedCount, actualCount, @"expected: %ld events got: %ld events.", (long)expectedCount, (long)actualCount);
    for (int i = 0; i < expectedEventTypes.count; i++) {
        id<MUXSDKEventTyping> event = [MUXSDKCore eventAtIndex:i forPlayer:name];
        NSString *expectedType = [expectedEventTypes objectAtIndex:i];
        NSString *actualType = [event getType];
        XCTAssertEqual(expectedType, actualType, @"index [%d] expected event type: %@ got event type: %@", i, expectedType, actualType);
    }
}

- (void) assertPlayer:(NSString *)name dispatchedDataEvents:(NSDictionary *) expectedVideoData {
    MUXSDKDataEvent *dataEvent;
    MUXSDKVideoData *videoData;
    NSDictionary *expected;
    for (id key in expectedVideoData) {
        expected = [expectedVideoData objectForKey:key];
        dataEvent = (MUXSDKDataEvent * ) [MUXSDKCore eventAtIndex:[key intValue] forPlayer:name];
        videoData = [dataEvent videoData];
        if ([expected isEqual:[NSNull null]]) {
            XCTAssertNil(videoData);
        } else {
            XCTAssertEqualWithAccuracy([[expected objectForKey:BANDWIDTH] doubleValue], [videoData.videoSourceAdvertisedBitrate doubleValue], FLT_EPSILON);
        }
    }
}

- (void) assertPlayer:(NSString *)name dispatchedDataEventsAtIndex: (int) index withCustomerViewData:(NSDictionary *) expected {
    MUXSDKDataEvent *dataEvent;
    MUXSDKCustomerViewData *viewData;
    dataEvent = (MUXSDKDataEvent * ) [MUXSDKCore eventAtIndex:index forPlayer:name];
    viewData = [dataEvent customerViewData];
    XCTAssertTrue([[viewData toQuery] isEqualToDictionary:expected]);
}

- (void) assertPlayer:(NSString *)name dispatchedDataEventsAtIndex: (int) index withCustomerVideoData:(NSDictionary *) expected {
    MUXSDKDataEvent *dataEvent;
    MUXSDKCustomerVideoData *videoData;
    dataEvent = (MUXSDKDataEvent * ) [MUXSDKCore eventAtIndex:index forPlayer:name];
    videoData = [dataEvent customerVideoData];
    XCTAssertTrue([[videoData toQuery] isEqualToDictionary:expected]);
}

- (void) assertPlayer:(NSString *)name dispatchedDataEventsAtIndex: (int) index withVideoData:(NSDictionary *) expected {
    MUXSDKDataEvent *dataEvent;
    MUXSDKVideoData *videoData;
    dataEvent = (MUXSDKDataEvent * ) [MUXSDKCore eventAtIndex:index forPlayer:name];
    videoData = [dataEvent videoData];
    XCTAssertTrue([[videoData toQuery] isEqualToDictionary:expected]);
}

#pragma mark - Video Change tests

- (void)testVideoChangeForAVPlayerViewControllerWithCustomerViewData{
    MuxMockAVPlayerViewController *controller = [[MuxMockAVPlayerViewController alloc] init];
    MUXSDKCustomerPlayerData *customerPlayerData = [[MUXSDKCustomerPlayerData alloc] initWithEnvironmentKey:@"YOUR_COMPANY_NAME"];
    MUXSDKCustomerVideoData *customerVideoData = [[MUXSDKCustomerVideoData alloc] init];
    [customerVideoData setVideoTitle:@"01234"];
    MUXSDKCustomerViewData *customerViewData = [[MUXSDKCustomerViewData alloc] init];
    [customerViewData setViewSessionId:@"foo"];
    MUXSDKCustomerData *customerData = [[MUXSDKCustomerData alloc] initWithCustomerPlayerData:customerPlayerData
                                                                                    videoData:customerVideoData
                                                                                     viewData:customerViewData
                                                                                   viewerData:nil];

    NSString *playName = @"Player";
    MUXSDKPlayerBinding *playerBinding = [MUXSDKStats monitorAVPlayerViewController:controller withPlayerName:playName customerData:customerData];
    XCTAssertNotNil(playerBinding, "expected monitorAVPlayerViewController to return a playerBinding");
    [customerViewData setViewSessionId:@"bar"];
    [MUXSDKStats videoChangeForPlayer:playName withPlayerData:customerPlayerData withVideoData:nil viewData:customerViewData];
    NSArray *expectedEventTypes = @[MUXSDKPlaybackEventViewInitEventType,
                                    MUXSDKDataEventType,
                                    MUXSDKPlaybackEventPlayerReadyEventType,
                                    MUXSDKPlaybackEventViewEndEventType
    ];
    [self assertPlayer:playName dispatchedEventTypes:expectedEventTypes];
    [self assertPlayer:playName dispatchedDataEventsAtIndex:1 withCustomerViewData:@{@"xseid": @"bar"}];
    [MUXSDKStats destroyPlayer:playName];
}

- (void)testVideoChangeForAVPlayerViewController{
    MuxMockAVPlayerViewController *controller = [[MuxMockAVPlayerViewController alloc] init];
    MUXSDKCustomerPlayerData *customerPlayerData = [[MUXSDKCustomerPlayerData alloc] initWithEnvironmentKey:@"YOUR_COMPANY_NAME"];
    MUXSDKCustomerVideoData *customerVideoData = [[MUXSDKCustomerVideoData alloc] init];
    [customerVideoData setVideoTitle:@"01234"];
    MUXSDKCustomerData *customerData = [[MUXSDKCustomerData alloc] initWithCustomerPlayerData:customerPlayerData
                                                                                    videoData:customerVideoData
                                                                                     viewData:nil
                                                                                   viewerData:nil];

    NSString *playName = @"Player";
    MUXSDKPlayerBinding *playerBinding = [MUXSDKStats monitorAVPlayerViewController:controller withPlayerName:playName customerData:customerData];
    XCTAssertNotNil(playerBinding, "expected monitorAVPlayerViewController to return a playerBinding");
    [customerVideoData setVideoTitle:@"56789"];
    [MUXSDKStats videoChangeForPlayer:playName withVideoData:customerVideoData];
    NSArray *expectedEventTypes = @[MUXSDKPlaybackEventViewInitEventType,
                                    MUXSDKDataEventType,
                                    MUXSDKPlaybackEventPlayerReadyEventType,
                                    MUXSDKPlaybackEventViewEndEventType
    ];
    [self assertPlayer:playName dispatchedEventTypes:expectedEventTypes];
    [self assertPlayer:playName dispatchedDataEventsAtIndex:1 withCustomerVideoData:@{@"vtt": @"56789"}];
    [MUXSDKStats destroyPlayer:playName];
}

- (void)testManualVideoChangeForAVPlayerViewController{
    MuxMockAVPlayerViewController *controller = [[MuxMockAVPlayerViewController alloc] init];
    MUXSDKCustomerPlayerData *customerPlayerData = [[MUXSDKCustomerPlayerData alloc] initWithEnvironmentKey:@"YOUR_COMPANY_NAME"];
    MUXSDKCustomerVideoData *customerVideoData = [[MUXSDKCustomerVideoData alloc] init];
    [customerVideoData setVideoTitle:@"01234"];
    MUXSDKCustomerData *customerData = [[MUXSDKCustomerData alloc] initWithCustomerPlayerData:customerPlayerData
                                                                                    videoData:customerVideoData
                                                                                     viewData:nil
                                                                                   viewerData:nil];

    NSURL* firstVideoURL = [NSURL URLWithString:@"http://qthttp.apple.com.edgesuite.net/1010qwoeiuryfg/sl.m3u8"];
    AVPlayerItem *firstItem = [AVPlayerItem playerItemWithURL:firstVideoURL];
    [controller.player replaceCurrentItemWithPlayerItem:firstItem];
    NSString *playName = @"Player";
    MUXSDKPlayerBinding *playerBinding = [MUXSDKStats monitorAVPlayerViewController:controller withPlayerName:playName customerData:customerData];
    XCTAssertNotNil(playerBinding, "expected monitorAVPlayerViewController to return a playerBinding");
    
    NSArray *expectedEventTypes = @[MUXSDKPlaybackEventViewInitEventType,
                                    MUXSDKDataEventType,
                                    MUXSDKPlaybackEventPlayerReadyEventType
    ];
    [self assertPlayer:playName dispatchedEventTypes:expectedEventTypes];
    [self assertPlayer:playName dispatchedDataEventsAtIndex:1 withCustomerVideoData:@{@"vtt": @"01234"}];
    
    // Set the automatic video change to false and manually trigger videoChangeForPlayer:withVideoData
    // We expect this to be treated as a new view
    [playerBinding setAutomaticVideoChange:false];
    // Change video metadata
    MUXSDKCustomerVideoData *newCustomerVideoData = [[MUXSDKCustomerVideoData alloc] init];
    [newCustomerVideoData setVideoTitle:@"56789"];
    // It is required to call videoChangeForPlayer: immediately before telling the player which new source to play.
    [MUXSDKStats videoChangeForPlayer:playName withVideoData:newCustomerVideoData];
    NSURL* videoURL = [NSURL URLWithString:@"https://bitdash-a.akamaihd.net/content/sintel/hls/playlist.m3u8"];
    AVPlayerItem *item = [AVPlayerItem playerItemWithURL:videoURL];
    [controller.player replaceCurrentItemWithPlayerItem:item];

    expectedEventTypes = @[MUXSDKPlaybackEventViewInitEventType,
                           MUXSDKDataEventType,
                           MUXSDKPlaybackEventPlayerReadyEventType,
                           MUXSDKDataEventType, // this gets triggered by dispatchViewEnd
                           MUXSDKPlaybackEventViewEndEventType,
                           MUXSDKPlaybackEventViewInitEventType, // the new view
                           MUXSDKDataEventType
    ];
    [self assertPlayer:playName dispatchedEventTypes:expectedEventTypes];
    [self assertPlayer:playName dispatchedDataEventsAtIndex:3 withVideoData:@{@"vsour": firstVideoURL.absoluteString, @"vsoisli": @"false"}];
    [self assertPlayer:playName dispatchedDataEventsAtIndex:6 withCustomerVideoData:@{@"vtt": @"56789"}];

    // now replace the player item with the same source again
    // but do not manually call videochange. This should result in no viewend and no viewinit events
    AVPlayerItem *newItem = [AVPlayerItem playerItemWithURL:videoURL];
    [controller.player replaceCurrentItemWithPlayerItem:newItem];
    // call play in order to force emitting events
    [controller.player play];
    expectedEventTypes = @[MUXSDKPlaybackEventViewInitEventType,
                           MUXSDKDataEventType,
                           MUXSDKPlaybackEventPlayerReadyEventType,
                           MUXSDKDataEventType, // this gets triggered by dispatchViewEnd
                           MUXSDKPlaybackEventViewEndEventType,
                           MUXSDKPlaybackEventViewInitEventType, // the new view
                           MUXSDKDataEventType,
                           MUXSDKDataEventType, // from replacing the player item with the same source
                           MUXSDKPlaybackEventPlayEventType
    ];
    [self assertPlayer:playName dispatchedDataEventsAtIndex:7 withVideoData:@{@"vsour": videoURL.absoluteString, @"vsoisli": @"false"}];
    [self assertPlayer:playName dispatchedEventTypes:expectedEventTypes];
    [MUXSDKStats destroyPlayer:playName];
}

- (void)testVideoChangeForAVPlayerLayerWithCustomerViewData{
    MuxMockAVPlayerLayer *controller = [[MuxMockAVPlayerLayer alloc] init];
    MUXSDKCustomerPlayerData *customerPlayerData = [[MUXSDKCustomerPlayerData alloc] initWithEnvironmentKey:@"YOUR_COMPANY_NAME"];
    MUXSDKCustomerVideoData *customerVideoData = [[MUXSDKCustomerVideoData alloc] init];
    [customerVideoData setVideoTitle:@"01234"];
    MUXSDKCustomerViewData *customerViewData = [[MUXSDKCustomerViewData alloc] init];
    [customerViewData setViewSessionId:@"foo"];
    MUXSDKCustomerData *customerData = [[MUXSDKCustomerData alloc] initWithCustomerPlayerData:customerPlayerData
                                                                                    videoData:customerVideoData
                                                                                     viewData:customerViewData
                                                                                   viewerData:nil];

    NSString *playName = @"Player";
    MUXSDKPlayerBinding *playerBinding = [MUXSDKStats monitorAVPlayerLayer:controller withPlayerName:playName customerData:customerData];
    XCTAssertNotNil(playerBinding, "expected monitorAVPlayerLayer to return a playerBinding");
    [customerViewData setViewSessionId:@"bar"];
    [MUXSDKStats videoChangeForPlayer:playName withPlayerData:customerPlayerData withVideoData:nil viewData:customerViewData];
    NSArray *expectedEventTypes = @[MUXSDKPlaybackEventViewInitEventType,
                                    MUXSDKDataEventType,
                                    MUXSDKPlaybackEventPlayerReadyEventType,
                                    MUXSDKPlaybackEventViewEndEventType
    ];
    [self assertPlayer:playName dispatchedEventTypes:expectedEventTypes];
    [self assertPlayer:playName dispatchedDataEventsAtIndex:1 withCustomerViewData:@{@"xseid": @"bar"}];
    [MUXSDKStats destroyPlayer:playName];
}

- (void)testVideoChangeForAVPlayerLayer{
    MuxMockAVPlayerLayer *controller = [[MuxMockAVPlayerLayer alloc] init];
    MUXSDKCustomerPlayerData *customerPlayerData = [[MUXSDKCustomerPlayerData alloc] initWithEnvironmentKey:@"YOUR_COMPANY_NAME"];
    MUXSDKCustomerVideoData *customerVideoData = [[MUXSDKCustomerVideoData alloc] init];
    [customerVideoData setVideoTitle:@"01234"];
    MUXSDKCustomerData *customerData = [[MUXSDKCustomerData alloc] initWithCustomerPlayerData:customerPlayerData
                                                                                    videoData:customerVideoData
                                                                                     viewData:nil
                                                                                   viewerData:nil];

    NSString *playName = @"Player";
    MUXSDKPlayerBinding *playerBinding = [MUXSDKStats monitorAVPlayerLayer:controller withPlayerName:playName customerData:customerData];
    XCTAssertNotNil(playerBinding, "expected monitorAVPlayerLayer to return a playerBinding");
    [customerVideoData setVideoTitle:@"56789"];
    [MUXSDKStats videoChangeForPlayer:playName withVideoData:customerVideoData];
    NSArray *expectedEventTypes = @[MUXSDKPlaybackEventViewInitEventType,
                                    MUXSDKDataEventType,
                                    MUXSDKPlaybackEventPlayerReadyEventType,
                                    MUXSDKPlaybackEventViewEndEventType
    ];
    [self assertPlayer:playName dispatchedEventTypes:expectedEventTypes];
    [self assertPlayer:playName dispatchedDataEventsAtIndex:1 withCustomerVideoData:@{@"vtt": @"56789"}];
    [MUXSDKStats destroyPlayer:playName];
}

- (void)testManualVideoChangeForAVPlayerLayer{
    MuxMockAVPlayerLayer *controller = [[MuxMockAVPlayerLayer alloc] init];
    MUXSDKCustomerPlayerData *customerPlayerData = [[MUXSDKCustomerPlayerData alloc] initWithEnvironmentKey:@"YOUR_COMPANY_NAME"];
    MUXSDKCustomerVideoData *customerVideoData = [[MUXSDKCustomerVideoData alloc] init];
    [customerVideoData setVideoTitle:@"01234"];
    MUXSDKCustomerData *customerData = [[MUXSDKCustomerData alloc] initWithCustomerPlayerData:customerPlayerData
                                                                                    videoData:customerVideoData
                                                                                     viewData:nil
                                                                                   viewerData:nil];

    NSURL* firstVideoURL = [NSURL URLWithString:@"http://qthttp.apple.com.edgesuite.net/1010qwoeiuryfg/sl.m3u8"];
    AVPlayerItem *firstItem = [AVPlayerItem playerItemWithURL:firstVideoURL];
    [controller.player replaceCurrentItemWithPlayerItem:firstItem];
    NSString *playName = @"Player";
    MUXSDKPlayerBinding *playerBinding = [MUXSDKStats monitorAVPlayerLayer:controller withPlayerName:playName customerData:customerData];
    XCTAssertNotNil(playerBinding, "expected monitorAVPlayerLayer to return a playerBinding");
    
    NSArray *expectedEventTypes = @[MUXSDKPlaybackEventViewInitEventType,
                                    MUXSDKDataEventType,
                                    MUXSDKPlaybackEventPlayerReadyEventType
    ];
    [self assertPlayer:playName dispatchedEventTypes:expectedEventTypes];
    [self assertPlayer:playName dispatchedDataEventsAtIndex:1 withCustomerVideoData:@{@"vtt": @"01234"}];
    
    // Set the automatic video change to false and manually trigger videoChangeForPlayer:withVideoData
    // We expect this to be treated as a new view
    [playerBinding setAutomaticVideoChange:false];
    // Change video metadata
    MUXSDKCustomerVideoData *newCustomerVideoData = [[MUXSDKCustomerVideoData alloc] init];
    [newCustomerVideoData setVideoTitle:@"56789"];
    // It is required to call videoChangeForPlayer: immediately before telling the player which new source to play.
    [MUXSDKStats videoChangeForPlayer:playName withVideoData:newCustomerVideoData];
    NSURL* videoURL = [NSURL URLWithString:@"https://bitdash-a.akamaihd.net/content/sintel/hls/playlist.m3u8"];
    AVPlayerItem *item = [AVPlayerItem playerItemWithURL:videoURL];
    [controller.player replaceCurrentItemWithPlayerItem:item];

    expectedEventTypes = @[MUXSDKPlaybackEventViewInitEventType,
                           MUXSDKDataEventType,
                           MUXSDKPlaybackEventPlayerReadyEventType,
                           MUXSDKDataEventType, // this gets triggered by dispatchViewEnd
                           MUXSDKPlaybackEventViewEndEventType,
                           MUXSDKPlaybackEventViewInitEventType, // the new view
                           MUXSDKDataEventType
    ];
    [self assertPlayer:playName dispatchedEventTypes:expectedEventTypes];
    [self assertPlayer:playName dispatchedDataEventsAtIndex:3 withVideoData:@{@"vsour": firstVideoURL.absoluteString, @"vsoisli": @"false"}];
    [self assertPlayer:playName dispatchedDataEventsAtIndex:6 withCustomerVideoData:@{@"vtt": @"56789"}];
    
    // now replace the player item with the same source again
    // but do not manually call videochange. This should result in no viewend and no viewinit events
    AVPlayerItem *newItem = [AVPlayerItem playerItemWithURL:videoURL];
    [controller.player replaceCurrentItemWithPlayerItem:newItem];
    // call play in order to force emitting events
    [controller.player play];
    expectedEventTypes = @[MUXSDKPlaybackEventViewInitEventType,
                           MUXSDKDataEventType,
                           MUXSDKPlaybackEventPlayerReadyEventType,
                           MUXSDKDataEventType, // this gets triggered by dispatchViewEnd
                           MUXSDKPlaybackEventViewEndEventType,
                           MUXSDKPlaybackEventViewInitEventType, // the new view
                           MUXSDKDataEventType,
                           MUXSDKDataEventType, // from replacing the player item with the same source
                           MUXSDKPlaybackEventPlayEventType
    ];
    [self assertPlayer:playName dispatchedDataEventsAtIndex:7 withVideoData:@{@"vsour": videoURL.absoluteString, @"vsoisli": @"false"}];
    [self assertPlayer:playName dispatchedEventTypes:expectedEventTypes];
    [MUXSDKStats destroyPlayer:playName];
    [MUXSDKStats destroyPlayer:playName];
}

- (void)testProgramChangeForAVPlayerViewController{
    MuxMockAVPlayerViewController *controller = [[MuxMockAVPlayerViewController alloc] init];
    MUXSDKCustomerPlayerData *customerPlayerData = [[MUXSDKCustomerPlayerData alloc] initWithEnvironmentKey:@"ENV_KEY"];
    MUXSDKCustomerVideoData *customerVideoData = [[MUXSDKCustomerVideoData alloc] init];
    [customerVideoData setVideoTitle:@"01234"];
    MUXSDKCustomerData *customerData = [[MUXSDKCustomerData alloc] initWithCustomerPlayerData:customerPlayerData
                                                                                    videoData:customerVideoData
                                                                                     viewData:nil
                                                                                   viewerData:nil];

    NSString *playName = @"Player";
    MUXSDKPlayerBinding *playerBinding = [MUXSDKStats monitorAVPlayerViewController:controller withPlayerName:playName customerData:customerData];
    XCTAssertNotNil(playerBinding, "expected monitorAVPlayerViewController to return a playerBinding");
    [customerVideoData setVideoTitle:@"56789"];
    [MUXSDKStats programChangeForPlayer:playName withVideoData:customerVideoData];
    NSArray *expectedEventTypes = @[MUXSDKPlaybackEventViewInitEventType,
                                    MUXSDKDataEventType,
                                    MUXSDKPlaybackEventPlayerReadyEventType,
                                    MUXSDKPlaybackEventViewEndEventType,
                                    MUXSDKPlaybackEventPlayEventType,
                                    MUXSDKPlaybackEventPlayingEventType
    ];
    [self assertPlayer:playName dispatchedEventTypes:expectedEventTypes];
    [MUXSDKStats destroyPlayer:playName];
}

#pragma mark - CustomerData tests

- (void)testUpdateCustomerDataWithNulls{
    MuxMockAVPlayerLayer *controller = [[MuxMockAVPlayerLayer alloc] init];
    MUXSDKCustomerPlayerData *customerPlayerData = [[MUXSDKCustomerPlayerData alloc] initWithEnvironmentKey:@"YOUR_COMPANY_NAME"];
    MUXSDKCustomerVideoData *customerVideoData = [[MUXSDKCustomerVideoData alloc] init];
    MUXSDKCustomerViewData *customerViewData = [[MUXSDKCustomerViewData alloc] init];
    [customerViewData setViewSessionId:@"foo"];
    MUXSDKCustomerData *customerData = [[MUXSDKCustomerData alloc] initWithCustomerPlayerData:customerPlayerData
                                                                                    videoData:customerVideoData
                                                                                     viewData:customerViewData
                                                                                   viewerData:nil];
    NSString *playName = @"Player";
    [MUXSDKStats monitorAVPlayerLayer:controller withPlayerName:playName customerData:customerData];
     customerData = [[MUXSDKCustomerData alloc] initWithCustomerPlayerData:nil
                                                                 videoData:nil
                                                                  viewData:nil
                                                                viewerData:nil];
    [MUXSDKStats setCustomerData:customerData forPlayer:playName];
    NSArray *expectedEventTypes = @[MUXSDKPlaybackEventViewInitEventType,
                                    MUXSDKDataEventType,
                                    MUXSDKPlaybackEventPlayerReadyEventType
    ];
    [self assertPlayer:playName dispatchedEventTypes:expectedEventTypes];
    [self assertPlayer:playName dispatchedDataEventsAtIndex:1 withCustomerVideoData:@{}];
    [self assertPlayer:playName dispatchedDataEventsAtIndex:1 withCustomerViewData:@{@"xseid" : @"foo"}];
    [MUXSDKStats destroyPlayer:playName];
}

- (void)testUpdateCustomerDataWithPlayerDataViewDataAndNullVideoData{
    MuxMockAVPlayerLayer *controller = [[MuxMockAVPlayerLayer alloc] init];
    MUXSDKCustomerPlayerData *customerPlayerData = [[MUXSDKCustomerPlayerData alloc] initWithEnvironmentKey:@"YOUR_COMPANY_NAME"];
    MUXSDKCustomerVideoData *customerVideoData = [[MUXSDKCustomerVideoData alloc] init];
    [customerVideoData setVideoTitle:@"1234"];
    MUXSDKCustomerViewData *customerViewData = [[MUXSDKCustomerViewData alloc] init];
    [customerViewData setViewSessionId:@"foo"];
    MUXSDKCustomerData *customerData = [[MUXSDKCustomerData alloc] initWithCustomerPlayerData:customerPlayerData
                                                                                    videoData:customerVideoData
                                                                                     viewData:customerViewData
                                                                                   viewerData:nil];
    NSString *playName = @"Player";
    [MUXSDKStats monitorAVPlayerLayer:controller withPlayerName:playName customerData:customerData];
    [customerPlayerData setPlayerVersion:@"playerVersionV1"];
    [customerViewData setViewSessionId:@"baz"];
    customerData = [[MUXSDKCustomerData alloc] initWithCustomerPlayerData:customerPlayerData
                                                                videoData:nil
                                                                 viewData:customerViewData
                                                               viewerData:nil];
    [MUXSDKStats setCustomerData:customerData forPlayer:playName];
    NSArray *expectedEventTypes = @[MUXSDKPlaybackEventViewInitEventType,
                                    MUXSDKDataEventType,
                                    MUXSDKPlaybackEventPlayerReadyEventType,
                                    MUXSDKDataEventType
    ];
    [self assertPlayer:playName dispatchedEventTypes:expectedEventTypes];
//    [self assertPlayer:playName dispatchedDataEventsAtIndex:1 withCustomerVideoData:@{@"vtt": @"1234"}];
    [self assertPlayer:playName dispatchedDataEventsAtIndex:1 withCustomerViewData:@{@"xseid" : @"baz"}];
    [MUXSDKStats destroyPlayer:playName];
}

- (void)testupdateCustomerDataWithPlayerDataAndNullVideoData{
    MuxMockAVPlayerLayer *controller = [[MuxMockAVPlayerLayer alloc] init];
    MUXSDKCustomerPlayerData *customerPlayerData = [[MUXSDKCustomerPlayerData alloc] initWithEnvironmentKey:@"YOUR_COMPANY_NAME"];
    MUXSDKCustomerVideoData *customerVideoData = [[MUXSDKCustomerVideoData alloc] init];
    MUXSDKCustomerData *customerData = [[MUXSDKCustomerData alloc] initWithCustomerPlayerData:customerPlayerData
                                                                                    videoData:customerVideoData
                                                                                     viewData:nil
                                                                                   viewerData:nil];
    NSString *playName = @"Player";
    [MUXSDKStats monitorAVPlayerLayer:controller withPlayerName:playName customerData:customerData];
    [customerPlayerData setPlayerVersion:@"playerVersionV1"];
     customerData = [[MUXSDKCustomerData alloc] initWithCustomerPlayerData:customerPlayerData
                                                                 videoData:nil
                                                                  viewData:nil
                                                                viewerData:nil];

    [MUXSDKStats setCustomerData:customerData forPlayer:playName];
    NSArray *expectedEventTypes = @[MUXSDKPlaybackEventViewInitEventType,
                                    MUXSDKDataEventType,
                                    MUXSDKPlaybackEventPlayerReadyEventType,
                                    MUXSDKDataEventType
    ];
    [self assertPlayer:playName dispatchedEventTypes:expectedEventTypes];
    [MUXSDKStats destroyPlayer:playName];
}

- (void)testUpdateCustomerDataWithNullPlayerDataAndVideoData{
    MuxMockAVPlayerLayer *controller = [[MuxMockAVPlayerLayer alloc] init];
    MUXSDKCustomerPlayerData *customerPlayerData = [[MUXSDKCustomerPlayerData alloc] initWithEnvironmentKey:@"YOUR_COMPANY_NAME"];
    MUXSDKCustomerVideoData *customerVideoData = [[MUXSDKCustomerVideoData alloc] init];
    MUXSDKCustomerData *customerData = [[MUXSDKCustomerData alloc] initWithCustomerPlayerData:customerPlayerData
                                                                                    videoData:customerVideoData
                                                                                     viewData:nil
                                                                                   viewerData:nil];

    NSString *playName = @"Player";
    [MUXSDKStats monitorAVPlayerLayer:controller withPlayerName:playName customerData:customerData];
    [customerVideoData setVideoTitle:@"Updated VideoTitle"];
    customerData = [[MUXSDKCustomerData alloc] initWithCustomerPlayerData:nil
                                                                videoData:customerVideoData
                                                                 viewData:nil
                                                               viewerData:nil];

    [MUXSDKStats setCustomerData:customerData forPlayer:playName];
    NSArray *expectedEventTypes = @[MUXSDKPlaybackEventViewInitEventType,
                                    MUXSDKDataEventType,
                                    MUXSDKPlaybackEventPlayerReadyEventType,
                                    MUXSDKDataEventType
    ];
    [self assertPlayer:playName dispatchedEventTypes:expectedEventTypes];
    [MUXSDKStats destroyPlayer:playName];
}

- (void)testUpdateCustomerDataViewerData {
    NSString *playName = @"Player";
    NSString *applicationName1 = @"appName1";
    NSString *applicationName2 = @"appName2";

    MuxMockAVPlayerLayer *controller = [[MuxMockAVPlayerLayer alloc] init];
    MUXSDKCustomerViewerData *customerViewerData = [[MUXSDKCustomerViewerData alloc] init];
    [customerViewerData setViewerApplicationName:applicationName1];

    MUXSDKCustomerData *customerData = [[MUXSDKCustomerData alloc] initWithCustomerPlayerData:nil
                                                                                    videoData:nil
                                                                                     viewData:nil
                                                                                   viewerData:customerViewerData];
    [MUXSDKStats monitorAVPlayerLayer:controller withPlayerName:playName customerData:customerData];

    // Sending CustomerData with nil viewerData should not emit an event
    customerData = [[MUXSDKCustomerData alloc] initWithCustomerPlayerData:nil
                                                                videoData:nil
                                                                 viewData:nil
                                                               viewerData:nil];
    [MUXSDKStats setCustomerData:customerData forPlayer:playName];

    [customerViewerData setViewerApplicationName:applicationName2];
    customerData = [[MUXSDKCustomerData alloc] initWithCustomerPlayerData:nil
                                                                videoData:nil
                                                                 viewData:nil
                                                               viewerData:customerViewerData];
    [MUXSDKStats setCustomerData:customerData forPlayer:playName];

    NSArray *expectedEventTypes = @[MUXSDKDataEventType,
                                    MUXSDKDataEventType
    ];
    [self assertDispatchedGlobalEventTypes:expectedEventTypes];
    XCTAssertEqual([[MUXSDKCore globalEventAtIndex:0] viewerData].viewerApplicationName, applicationName1);
    XCTAssertEqual([[MUXSDKCore globalEventAtIndex:1] viewerData].viewerApplicationName, applicationName2);
    [MUXSDKStats destroyPlayer:playName];
}


- (void)testDestroyPlayer {
    MuxMockAVPlayerViewController *controller = [[MuxMockAVPlayerViewController alloc] init];
    MUXSDKCustomerPlayerData *customerPlayerData = [[MUXSDKCustomerPlayerData alloc] initWithEnvironmentKey:@"ENV_KEY"];
    MUXSDKCustomerVideoData *customerVideoData = [[MUXSDKCustomerVideoData alloc] init];
    MUXSDKCustomerData *customerData = [[MUXSDKCustomerData alloc] initWithCustomerPlayerData:customerPlayerData
                                                                                    videoData:customerVideoData
                                                                                     viewData:nil
                                                                                   viewerData:nil];
    [customerVideoData setVideoTitle:@"01234"];
    NSString *playName = @"Player";
    [MUXSDKStats monitorAVPlayerViewController:controller withPlayerName:playName customerData:customerData];
    [MUXSDKStats destroyPlayer:playName];
    NSArray *expectedEventTypes = @[MUXSDKPlaybackEventViewInitEventType,
                                    MUXSDKDataEventType,
                                    MUXSDKPlaybackEventPlayerReadyEventType,
                                    MUXSDKPlaybackEventViewEndEventType
    ];
    [self assertPlayer:playName dispatchedEventTypes:expectedEventTypes];
}

#pragma mark - Orientation & Rendition tests

- (void) testOrientationChangeEvent {
    MuxMockAVPlayerLayer *controller = [[MuxMockAVPlayerLayer alloc] init];
    MUXSDKCustomerPlayerData *customerPlayerData = [[MUXSDKCustomerPlayerData alloc] initWithEnvironmentKey:@"YOUR_COMPANY_NAME"];
    MUXSDKCustomerVideoData *customerVideoData = [[MUXSDKCustomerVideoData alloc] init];
    MUXSDKCustomerData *customerData = [[MUXSDKCustomerData alloc] initWithCustomerPlayerData:customerPlayerData
                                                                                    videoData:customerVideoData
                                                                                     viewData:nil
                                                                                   viewerData:nil];

    NSString *playName = @"Player";
    [MUXSDKStats monitorAVPlayerLayer:controller withPlayerName:playName customerData:customerData];
    
    [MUXSDKStats orientationChangeForPlayer:playName withOrientation:MUXSDKViewOrientationPortrait];
    [MUXSDKStats orientationChangeForPlayer:playName withOrientation:MUXSDKViewOrientationLandscape];
    
    NSArray *expectedEventTypes = @[MUXSDKPlaybackEventViewInitEventType,
                                    MUXSDKDataEventType,
                                    MUXSDKPlaybackEventPlayerReadyEventType,
                                    MUXSDKPlaybackEventOrientationChangeEventType,
                                    MUXSDKPlaybackEventOrientationChangeEventType
    ];
    [self assertPlayer:playName dispatchedEventTypes:expectedEventTypes];
    
    id<MUXSDKEventTyping> portraitEvent = [MUXSDKCore eventAtIndex:3 forPlayer:playName];
    MUXSDKViewData *viewData = [((MUXSDKOrientationChangeEvent *) portraitEvent) viewData];
    XCTAssertNotNil(viewData);
    XCTAssertEqual(@(0.0), viewData.viewDeviceOrientationData.x);
    XCTAssertEqual(@(0.0), viewData.viewDeviceOrientationData.y);
    XCTAssertEqual(@(90.0), viewData.viewDeviceOrientationData.z);
    
    id<MUXSDKEventTyping> landscapeEvent = [MUXSDKCore eventAtIndex:4 forPlayer:playName];
    viewData = [((MUXSDKOrientationChangeEvent *) landscapeEvent) viewData];
    XCTAssertNotNil(viewData);
    XCTAssertEqual(@(0.0), viewData.viewDeviceOrientationData.x);
    XCTAssertEqual(@(0.0), viewData.viewDeviceOrientationData.y);
    XCTAssertEqual(@(0.0), viewData.viewDeviceOrientationData.z);
    [MUXSDKStats destroyPlayer:playName];
}

- (void) testRenditionChangeEvent {
    MuxMockAVPlayerLayer *controller = [[MuxMockAVPlayerLayer alloc] init];
    MUXSDKCustomerPlayerData *customerPlayerData = [[MUXSDKCustomerPlayerData alloc] initWithEnvironmentKey:@"YOUR_COMPANY_NAME"];
    MUXSDKCustomerVideoData *customerVideoData = [[MUXSDKCustomerVideoData alloc] init];
    MUXSDKCustomerData *customerData = [[MUXSDKCustomerData alloc] initWithCustomerPlayerData:customerPlayerData
                                                                                    videoData:customerVideoData
                                                                                     viewData:nil
                                                                                   viewerData:nil];

    NSString *playName = @"Player";
    [MUXSDKStats monitorAVPlayerLayer:controller withPlayerName:playName customerData:customerData];
    
    NSDictionary *renditionInfo = @{
        RenditionChangeNotificationInfoAdvertisedBitrate: @(258157)
    };
    [[NSNotificationCenter defaultCenter] postNotificationName:RenditionChangeNotification object:renditionInfo];
    
    NSDictionary *renditionInfoWithoutFrameRate = @{
        RenditionChangeNotificationInfoAdvertisedBitrate: @(558157)
    };
    [[NSNotificationCenter defaultCenter] postNotificationName:RenditionChangeNotification object:renditionInfoWithoutFrameRate];

    NSArray *expectedEventTypes = @[MUXSDKPlaybackEventViewInitEventType,
                                    MUXSDKDataEventType,
                                    MUXSDKPlaybackEventPlayerReadyEventType,
                                    MUXSDKDataEventType,
                                    MUXSDKPlaybackEventRenditionChangeEventType,
                                    MUXSDKDataEventType,
                                    MUXSDKPlaybackEventRenditionChangeEventType

    ];
    [self assertPlayer:playName dispatchedEventTypes:expectedEventTypes];
    
    id<MUXSDKEventTyping> event = [MUXSDKCore eventAtIndex:3 forPlayer:playName];
    MUXSDKVideoData *videoData = [((MUXSDKDataEvent *) event) videoData];
    XCTAssertNotNil(videoData);
    XCTAssertEqualWithAccuracy(258157, [videoData.videoSourceAdvertisedBitrate doubleValue], FLT_EPSILON);
    
    event = [MUXSDKCore eventAtIndex:5 forPlayer:playName];
    videoData = [((MUXSDKDataEvent *) event) videoData];
    XCTAssertNotNil(videoData);
    XCTAssertEqualWithAccuracy(558157, [videoData.videoSourceAdvertisedBitrate doubleValue], FLT_EPSILON);
    XCTAssertNil(videoData.videoSourceAdvertisedFrameRate);
    
    [MUXSDKStats destroyPlayer:playName];
}

- (void) testRenditionChangeEventsWithSameBitrate {
    MuxMockAVPlayerLayer *controller = [[MuxMockAVPlayerLayer alloc] init];
    MUXSDKCustomerPlayerData *customerPlayerData = [[MUXSDKCustomerPlayerData alloc] initWithEnvironmentKey:@"YOUR_COMPANY_NAME"];
    MUXSDKCustomerVideoData *customerVideoData = [[MUXSDKCustomerVideoData alloc] init];
    MUXSDKCustomerData *customerData = [[MUXSDKCustomerData alloc] initWithCustomerPlayerData:customerPlayerData
                                                                                    videoData:customerVideoData
                                                                                     viewData:nil
                                                                                   viewerData:nil];

    NSString *playName = @"Player";
    [MUXSDKStats monitorAVPlayerLayer:controller withPlayerName:playName customerData:customerData];
    
    NSDictionary *renditionInfo = @{
        RenditionChangeNotificationInfoAdvertisedBitrate: @(258157)
    };
    [[NSNotificationCenter defaultCenter] postNotificationName:RenditionChangeNotification object:renditionInfo];
    
    NSDictionary *renditionInfoWithoutFrameRate = @{
        RenditionChangeNotificationInfoAdvertisedBitrate: @(258157)
    };
    [[NSNotificationCenter defaultCenter] postNotificationName:RenditionChangeNotification object:renditionInfoWithoutFrameRate];

    NSArray *expectedEventTypes = @[MUXSDKPlaybackEventViewInitEventType,
                                    MUXSDKDataEventType,
                                    MUXSDKPlaybackEventPlayerReadyEventType,
                                    MUXSDKDataEventType,
                                    MUXSDKPlaybackEventRenditionChangeEventType,

    ];
    [self assertPlayer:playName dispatchedEventTypes:expectedEventTypes];
    
    id<MUXSDKEventTyping> event = [MUXSDKCore eventAtIndex:3 forPlayer:playName];
    MUXSDKVideoData *videoData = [((MUXSDKDataEvent *) event) videoData];
    XCTAssertNotNil(videoData);
    XCTAssertEqualWithAccuracy(258157, [videoData.videoSourceAdvertisedBitrate doubleValue], FLT_EPSILON);
    
    [MUXSDKStats destroyPlayer:playName];
}

- (void) testOrientationAndRenditionChangeEventSequence {
    MuxMockAVPlayerLayer *controller = [[MuxMockAVPlayerLayer alloc] init];
    MUXSDKCustomerPlayerData *customerPlayerData = [[MUXSDKCustomerPlayerData alloc] initWithEnvironmentKey:@"YOUR_COMPANY_NAME"];
    MUXSDKCustomerVideoData *customerVideoData = [[MUXSDKCustomerVideoData alloc] init];
    MUXSDKCustomerData *customerData = [[MUXSDKCustomerData alloc] initWithCustomerPlayerData:customerPlayerData
                                                                                    videoData:customerVideoData
                                                                                     viewData:nil
                                                                                   viewerData:nil];

    NSString *playName = @"Player";
    [MUXSDKStats monitorAVPlayerLayer:controller withPlayerName:playName customerData:customerData];

    [MUXSDKStats orientationChangeForPlayer:playName withOrientation:MUXSDKViewOrientationPortrait];

    [[NSNotificationCenter defaultCenter] postNotificationName:RenditionChangeNotification object:@{
        RenditionChangeNotificationInfoAdvertisedBitrate: @(258157)
    }];

    [[NSNotificationCenter defaultCenter] postNotificationName:RenditionChangeNotification object:@{
        RenditionChangeNotificationInfoAdvertisedBitrate: @(1927853)
    }];

    [MUXSDKStats orientationChangeForPlayer:playName withOrientation:MUXSDKViewOrientationLandscape];

    [[NSNotificationCenter defaultCenter] postNotificationName:RenditionChangeNotification object:@{
        RenditionChangeNotificationInfoAdvertisedBitrate: @(258157)
    }];

    // Assert sequence of playback & data events is correct

    NSArray *expectedEventTypes = @[MUXSDKPlaybackEventViewInitEventType,
                                    MUXSDKDataEventType,
                                    MUXSDKPlaybackEventPlayerReadyEventType,
                                    MUXSDKPlaybackEventOrientationChangeEventType,
                                    MUXSDKDataEventType,
                                    MUXSDKPlaybackEventRenditionChangeEventType,
                                    MUXSDKDataEventType,
                                    MUXSDKPlaybackEventRenditionChangeEventType,
                                    MUXSDKPlaybackEventOrientationChangeEventType,
                                    MUXSDKDataEventType,
                                    MUXSDKPlaybackEventRenditionChangeEventType
    ];
    [self assertPlayer:playName dispatchedEventTypes:expectedEventTypes];

    [self assertPlayer:playName dispatchedDataEvents:@{
        @(1): [NSNull null],
        @(4): @{BANDWIDTH: @(258157)},
        @(6): @{BANDWIDTH: @(1927853)},
        @(9): @{BANDWIDTH: @(258157)},
    }];

    [self assertPlayer:playName dispatchedPlaybackEvents:@{
        @(0): [NSNull null],
        @(2): [NSNull null],
        @(3): @{X: @(0.0), Y: @(0.0), Z: @(90.0)},
        @(5): [NSNull null],
        @(7): [NSNull null],
        @(8): @{X: @(0.0), Y: @(0.0), Z: @(0.0)},
        @(10): [NSNull null],
    }];

    [MUXSDKStats destroyPlayer:playName];
}

- (void) testDispatchError {
    MuxMockAVPlayerLayer *controller = [[MuxMockAVPlayerLayer alloc] init];
    MUXSDKCustomerPlayerData *customerPlayerData = [[MUXSDKCustomerPlayerData alloc] initWithEnvironmentKey:@"YOUR_COMPANY_NAME"];
    MUXSDKCustomerVideoData *customerVideoData = [[MUXSDKCustomerVideoData alloc] init];
    MUXSDKCustomerData *customerData = [[MUXSDKCustomerData alloc] initWithCustomerPlayerData:customerPlayerData
                                                                                    videoData:customerVideoData
                                                                                     viewData:nil
                                                                                   viewerData:nil];

    NSString *playName = @"Player";
    [MUXSDKStats monitorAVPlayerLayer:controller withPlayerName:playName customerData:customerData];

    [MUXSDKStats dispatchError:@"12345" withMessage:@"Something aint right" forPlayer:playName];

    NSArray *expectedEventTypes = @[MUXSDKPlaybackEventViewInitEventType,
                                    MUXSDKDataEventType,
                                    MUXSDKPlaybackEventPlayerReadyEventType,
                                    MUXSDKPlaybackEventErrorEventType,
    ];
    [self assertPlayer:playName dispatchedEventTypes:expectedEventTypes];

    [MUXSDKStats destroyPlayer:playName];
}
@end
