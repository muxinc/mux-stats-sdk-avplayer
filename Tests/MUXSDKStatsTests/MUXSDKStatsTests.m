//
//  MUXSDKStatsTests.m
//  MUXSDKStatsTests
//
//  Created by Matt Ward on 11/2/16.
//  Copyright © 2016 Mux, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <MuxCore/MuxCore.h>

#import "MUXSDKStats/MUXSDKStats.h"
#import "MUXSDKStats+Internal.h"
#import "Utils/MUXSDKCore+Mock.h"
#import "MUXSDKPlayerBindingConstants.h"

#define MUXUniquePlayerName() [NSString stringWithFormat:@"Player for %s (%@)", __PRETTY_FUNCTION__, NSUUID.UUID.UUIDString]

NSString *const MUXTestVODURLString = @"https://stream.mux.com/a4nOgmxGWg6gULfcBbAa00gXyfcwPnAFldF8RdsNyk8M.m3u8";

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
static NSString *BANDWIDTH = @"BANDWIDTH";
static NSString *FRAMERATE = @"FRAME-RATE";
static NSString *X = @"X";
static NSString *Y = @"Y";
static NSString *Z = @"Z";

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
    NSArray<MUXSDKDataEvent *> *globalEvents = [MUXSDKCore snapshotOfGlobalEvents];
    NSArray<NSString *> *globalEventTypes = [globalEvents valueForKeyPath:NSStringFromSelector(@selector(getType))];
    XCTAssertEqualObjects(globalEventTypes, expectedEventTypes);
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
            XCTAssertEqualObjects([expected objectForKey:X], viewData.viewDeviceOrientationData.x);
            XCTAssertEqualObjects([expected objectForKey:Y], viewData.viewDeviceOrientationData.y);
            XCTAssertEqualObjects([expected objectForKey:Z], viewData.viewDeviceOrientationData.z);
        }
    }
}

- (void) assertPlayer:(NSString *)name dispatchedEventTypes:(NSArray *) expectedEventTypes {
    NSArray<id<MUXSDKEventTyping>> *events = [MUXSDKCore snapshotOfEventsForPlayer:name];
    NSArray<NSString *> *eventTypes = [events valueForKeyPath:NSStringFromSelector(@selector(getType))];
    XCTAssertEqualObjects(eventTypes, expectedEventTypes);
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

- (void) assertPlayer:(NSString *)name dispatchedDataEventsAtIndex: (int) index withCustomData:(NSDictionary *) expected {
    MUXSDKDataEvent *dataEvent;
    MUXSDKCustomData *customData;
    dataEvent = (MUXSDKDataEvent * ) [MUXSDKCore eventAtIndex:index forPlayer:name];
    customData = [dataEvent customData];
    if (expected != nil) {
        XCTAssertTrue([[customData toQuery] isEqualToDictionary:expected]);
    } else{
        XCTAssertNil(customData);
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

- (void)testVideoChangeForAVPlayerViewControllerWithCustomData{
    MuxMockAVPlayerViewController *controller = [[MuxMockAVPlayerViewController alloc] init];
    MUXSDKCustomerPlayerData *customerPlayerData = [[MUXSDKCustomerPlayerData alloc] initWithEnvironmentKey:@"YOUR_COMPANY_NAME"];
    MUXSDKCustomerVideoData *customerVideoData = [[MUXSDKCustomerVideoData alloc] init];
    [customerVideoData setVideoTitle:@"01234"];
    MUXSDKCustomData *customData = [[MUXSDKCustomData alloc] init];
    [customData setCustomData1:@"foo"];
    MUXSDKCustomerData *customerData = [[MUXSDKCustomerData alloc] initWithCustomerPlayerData:customerPlayerData
                                                                                    videoData:customerVideoData
                                                                                     viewData:nil
                                                                                   customData:customData];

    NSString *playName = MUXUniquePlayerName();
    MUXSDKPlayerBinding *playerBinding = [MUXSDKStats monitorAVPlayerViewController:controller withPlayerName:playName customerData:customerData];
    XCTAssertNotNil(playerBinding, "expected monitorAVPlayerViewController to return a playerBinding");
    [customData setCustomData1:@"bar"];
    [MUXSDKStats videoChangeForPlayer:playName withCustomerData:customerData];
    NSArray *expectedEventTypes = @[MUXSDKPlaybackEventViewInitEventType,
                                    MUXSDKDataEventType,
                                    MUXSDKPlaybackEventPlayerReadyEventType,
                                    MUXSDKPlaybackEventViewEndEventType
    ];
    [self assertPlayer:playName dispatchedEventTypes:expectedEventTypes];
    [self assertPlayer:playName dispatchedDataEventsAtIndex:1 withCustomData:@{@"c1": @"bar"}];
    [MUXSDKStats destroyPlayer:playName];
}

- (void)testVideoChangeForAVPlayerViewControllerWithCustomerViewData{
    MuxMockAVPlayerViewController *controller = [[MuxMockAVPlayerViewController alloc] init];
    MUXSDKCustomerPlayerData *customerPlayerData = [[MUXSDKCustomerPlayerData alloc] initWithEnvironmentKey:@"YOUR_COMPANY_NAME"];
    MUXSDKCustomerVideoData *customerVideoData = [[MUXSDKCustomerVideoData alloc] init];
    [customerVideoData setVideoTitle:@"01234"];
    MUXSDKCustomerViewData *customerViewData = [[MUXSDKCustomerViewData alloc] init];
    [customerViewData setViewSessionId:@"foo"];
    MUXSDKCustomerData *customerData = [[MUXSDKCustomerData alloc] initWithCustomerPlayerData:customerPlayerData
                                                                                    videoData:customerVideoData
                                                                                     viewData:customerViewData];

    NSString *playName = MUXUniquePlayerName();
    MUXSDKPlayerBinding *playerBinding = [MUXSDKStats monitorAVPlayerViewController:controller withPlayerName:playName customerData:customerData];
    XCTAssertNotNil(playerBinding, "expected monitorAVPlayerViewController to return a playerBinding");
    [customerViewData setViewSessionId:@"bar"];
    [MUXSDKStats videoChangeForPlayer:playName withCustomerData:customerData];
    NSArray *expectedEventTypes = @[MUXSDKPlaybackEventViewInitEventType,
                                    MUXSDKDataEventType,
                                    MUXSDKPlaybackEventPlayerReadyEventType,
                                    MUXSDKPlaybackEventViewEndEventType
    ];
    [MUXSDKStats destroyPlayer:playName];
    [self assertPlayer:playName dispatchedEventTypes:expectedEventTypes];
    [self assertPlayer:playName dispatchedDataEventsAtIndex:1 withCustomerViewData:@{@"xseid": @"bar"}];
}

- (void)testVideoChangeForAVPlayerViewController{
    MuxMockAVPlayerViewController *controller = [[MuxMockAVPlayerViewController alloc] init];
    MUXSDKCustomerPlayerData *customerPlayerData = [[MUXSDKCustomerPlayerData alloc] initWithEnvironmentKey:@"YOUR_COMPANY_NAME"];
    MUXSDKCustomerVideoData *customerVideoData = [[MUXSDKCustomerVideoData alloc] init];
    [customerVideoData setVideoTitle:@"01234"];
    MUXSDKCustomerData *customerData = [[MUXSDKCustomerData alloc] initWithCustomerPlayerData:customerPlayerData
                                                                                    videoData:customerVideoData
                                                                                     viewData:nil];

    NSString *playName = MUXUniquePlayerName();
    MUXSDKPlayerBinding *playerBinding = [MUXSDKStats monitorAVPlayerViewController:controller withPlayerName:playName customerData:customerData];
    XCTAssertNotNil(playerBinding, "expected monitorAVPlayerViewController to return a playerBinding");
    [customerVideoData setVideoTitle:@"56789"];
    [MUXSDKStats videoChangeForPlayer:playName withCustomerData:customerData];
    NSArray *expectedEventTypes = @[MUXSDKPlaybackEventViewInitEventType,
                                    MUXSDKDataEventType,
                                    MUXSDKPlaybackEventPlayerReadyEventType,
                                    MUXSDKPlaybackEventViewEndEventType
    ];
    [MUXSDKStats destroyPlayer:playName];
    [self assertPlayer:playName dispatchedEventTypes:expectedEventTypes];
    [self assertPlayer:playName dispatchedDataEventsAtIndex:1 withCustomerVideoData:@{@"vtt": @"56789"}];
}

- (void)testManualVideoChangeForAVPlayerViewController{
    MuxMockAVPlayerViewController *controller = [[MuxMockAVPlayerViewController alloc] init];
    MUXSDKCustomerPlayerData *customerPlayerData = [[MUXSDKCustomerPlayerData alloc] initWithEnvironmentKey:@"YOUR_COMPANY_NAME"];
    MUXSDKCustomerVideoData *customerVideoData = [[MUXSDKCustomerVideoData alloc] init];
    [customerVideoData setVideoTitle:@"01234"];
    MUXSDKCustomerData *customerData = [[MUXSDKCustomerData alloc] initWithCustomerPlayerData:customerPlayerData
                                                                                    videoData:customerVideoData
                                                                                     viewData:nil];

    NSURL* firstVideoURL = [NSURL URLWithString:@"http://qthttp.apple.com.edgesuite.net/1010qwoeiuryfg/sl.m3u8"];
    AVPlayerItem *firstItem = [AVPlayerItem playerItemWithURL:firstVideoURL];
    [controller.player replaceCurrentItemWithPlayerItem:firstItem];
    NSString *playName = MUXUniquePlayerName();
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
    MUXSDKCustomerData *newCustomerData = [[MUXSDKCustomerData alloc] init];
    newCustomerData.customerVideoData = newCustomerVideoData;
    // It is required to call videoChangeForPlayer: immediately before telling the player which new source to play.
    [MUXSDKStats videoChangeForPlayer:playName withCustomerData:newCustomerData];
    NSURL* videoURL = [NSURL URLWithString:MUXTestVODURLString];
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

- (void)testVideoChangeForAVPlayerLayerWithCustomerViewData API_UNAVAILABLE(visionos) {
    XCTSkipIf(TARGET_OS_VISION);

    MuxMockAVPlayerLayer *controller = [[MuxMockAVPlayerLayer alloc] init];
    MUXSDKCustomerPlayerData *customerPlayerData = [[MUXSDKCustomerPlayerData alloc] initWithEnvironmentKey:@"YOUR_COMPANY_NAME"];
    MUXSDKCustomerVideoData *customerVideoData = [[MUXSDKCustomerVideoData alloc] init];
    [customerVideoData setVideoTitle:@"01234"];
    MUXSDKCustomerViewData *customerViewData = [[MUXSDKCustomerViewData alloc] init];
    [customerViewData setViewSessionId:@"foo"];
    MUXSDKCustomerViewerData *customerViewerData = [MUXSDKCustomerViewerData new];
    customerViewerData.viewerPlan = @"a plan";
    MUXSDKCustomerData *customerData = [[MUXSDKCustomerData alloc] initWithCustomerPlayerData:customerPlayerData
                                                                                    videoData:customerVideoData
                                                                                     viewData:customerViewData
                                                                                   customData:nil
                                                                                   viewerData:customerViewerData];

    NSString *playName = MUXUniquePlayerName();
    MUXSDKPlayerBinding *playerBinding = [MUXSDKStats monitorAVPlayerLayer:controller withPlayerName:playName customerData:customerData];
    XCTAssertNotNil(playerBinding, "expected monitorAVPlayerLayer to return a playerBinding");
    [customerViewData setViewSessionId:@"bar"];

    MUXSDKCustomerData *updatedCustomerData = [MUXSDKCustomerData new];
    MUXSDKCustomerViewerData *updatedCustomerViewerData = [MUXSDKCustomerViewerData new];
    updatedCustomerViewerData.viewerPlanCategory = @"some category";
    updatedCustomerData.customerViewerData = updatedCustomerViewerData;
    [MUXSDKStats videoChangeForPlayer:playName withCustomerData:updatedCustomerData];

    NSArray *expectedEventTypes = @[MUXSDKPlaybackEventViewInitEventType,
                                    MUXSDKDataEventType,
                                    MUXSDKPlaybackEventPlayerReadyEventType,
                                    MUXSDKPlaybackEventViewEndEventType
    ];
    [MUXSDKStats destroyPlayer:playName];
    [self assertPlayer:playName dispatchedEventTypes:expectedEventTypes];
    [self assertPlayer:playName dispatchedDataEventsAtIndex:1 withCustomerViewData:@{@"xseid": @"bar"}];
    XCTAssertEqualObjects([[MUXSDKCore globalEventAtIndex:0].customerViewerData toQuery], (@{
        @"upz": @"a plan",
    }));
    XCTAssertEqualObjects([[MUXSDKCore globalEventAtIndex:1].customerViewerData toQuery], (@{
        @"upzcg": @"some category",
    }));
}

- (void)testVideoChangeForAVPlayerLayer API_UNAVAILABLE(visionos) {
    XCTSkipIf(TARGET_OS_VISION);

    MuxMockAVPlayerLayer *controller = [[MuxMockAVPlayerLayer alloc] init];
    MUXSDKCustomerPlayerData *customerPlayerData = [[MUXSDKCustomerPlayerData alloc] initWithEnvironmentKey:@"YOUR_COMPANY_NAME"];
    MUXSDKCustomerVideoData *customerVideoData = [[MUXSDKCustomerVideoData alloc] init];
    [customerVideoData setVideoTitle:@"01234"];
    MUXSDKCustomerData *customerData = [[MUXSDKCustomerData alloc] initWithCustomerPlayerData:customerPlayerData
                                                                                    videoData:customerVideoData
                                                                                     viewData:nil];

    NSString *playName = MUXUniquePlayerName();
    MUXSDKPlayerBinding *playerBinding = [MUXSDKStats monitorAVPlayerLayer:controller withPlayerName:playName customerData:customerData];
    XCTAssertNotNil(playerBinding, "expected monitorAVPlayerLayer to return a playerBinding");
    [customerVideoData setVideoTitle:@"56789"];
    [MUXSDKStats videoChangeForPlayer:playName withCustomerData:customerData];
    NSArray *expectedEventTypes = @[MUXSDKPlaybackEventViewInitEventType,
                                    MUXSDKDataEventType,
                                    MUXSDKPlaybackEventPlayerReadyEventType,
                                    MUXSDKPlaybackEventViewEndEventType
    ];
    [MUXSDKStats destroyPlayer:playName];
    [self assertPlayer:playName dispatchedEventTypes:expectedEventTypes];
    [self assertPlayer:playName dispatchedDataEventsAtIndex:1 withCustomerVideoData:@{@"vtt": @"56789"}];
}

- (void)testManualVideoChangeForAVPlayerLayer API_UNAVAILABLE(visionos) {
    XCTSkipIf(TARGET_OS_VISION);

    MuxMockAVPlayerLayer *controller = [[MuxMockAVPlayerLayer alloc] init];
    MUXSDKCustomerPlayerData *customerPlayerData = [[MUXSDKCustomerPlayerData alloc] initWithEnvironmentKey:@"YOUR_COMPANY_NAME"];
    MUXSDKCustomerVideoData *customerVideoData = [[MUXSDKCustomerVideoData alloc] init];
    [customerVideoData setVideoTitle:@"01234"];
    MUXSDKCustomerData *customerData = [[MUXSDKCustomerData alloc] initWithCustomerPlayerData:customerPlayerData
                                                                                    videoData:customerVideoData
                                                                                     viewData:nil];

    NSURL* firstVideoURL = [NSURL URLWithString:@"http://qthttp.apple.com.edgesuite.net/1010qwoeiuryfg/sl.m3u8"];
    AVPlayerItem *firstItem = [AVPlayerItem playerItemWithURL:firstVideoURL];
    [controller.player replaceCurrentItemWithPlayerItem:firstItem];
    NSString *playName = MUXUniquePlayerName();
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
    customerData.customerVideoData = newCustomerVideoData;
    // It is required to call videoChangeForPlayer: immediately before telling the player which new source to play.
    [MUXSDKStats videoChangeForPlayer:playName withCustomerData:customerData];
    NSURL* videoURL = [NSURL URLWithString:MUXTestVODURLString];
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
                           MUXSDKPlaybackEventPlayEventType,
                           MUXSDKPlaybackEventViewEndEventType,
    ];
    [MUXSDKStats destroyPlayer:playName];
    [MUXSDKStats destroyPlayer:playName];
    [self assertPlayer:playName dispatchedDataEventsAtIndex:7 withVideoData:@{@"vsour": videoURL.absoluteString, @"vsoisli": @"false"}];
    [self assertPlayer:playName dispatchedEventTypes:expectedEventTypes];
}

- (void)testProgramChangeForAVPlayerViewController{
    MuxMockAVPlayerViewController *controller = [[MuxMockAVPlayerViewController alloc] init];
    MUXSDKCustomerPlayerData *customerPlayerData = [[MUXSDKCustomerPlayerData alloc] initWithEnvironmentKey:@"ENV_KEY"];
    MUXSDKCustomerVideoData *customerVideoData = [[MUXSDKCustomerVideoData alloc] init];
    [customerVideoData setVideoTitle:@"01234"];
    MUXSDKCustomerData *customerData = [[MUXSDKCustomerData alloc] initWithCustomerPlayerData:customerPlayerData
                                                                                    videoData:customerVideoData
                                                                                     viewData:nil];

    NSString *playName = MUXUniquePlayerName();
    MUXSDKPlayerBinding *playerBinding = [MUXSDKStats monitorAVPlayerViewController:controller withPlayerName:playName customerData:customerData];
    XCTAssertNotNil(playerBinding, "expected monitorAVPlayerViewController to return a playerBinding");
    [customerVideoData setVideoTitle:@"56789"];
    [MUXSDKStats programChangeForPlayer:playName withCustomerData:customerData];
    NSArray *expectedEventTypes = @[MUXSDKPlaybackEventViewInitEventType,
                                    MUXSDKDataEventType,
                                    MUXSDKPlaybackEventPlayerReadyEventType,
                                    MUXSDKPlaybackEventViewEndEventType,
                                    MUXSDKPlaybackEventPlayEventType,
                                    MUXSDKPlaybackEventPlayingEventType,
                                    MUXSDKPlaybackEventViewEndEventType,
    ];
    [MUXSDKStats destroyPlayer:playName];
    [self assertPlayer:playName dispatchedEventTypes:expectedEventTypes];
}

- (void)testClearsCustomerMetadataOnDestroy API_UNAVAILABLE(visionos) {
    XCTSkipIf(TARGET_OS_VISION);

    MuxMockAVPlayerLayer *controller = [[MuxMockAVPlayerLayer alloc] init];
    MUXSDKCustomerPlayerData *customerPlayerData = [[MUXSDKCustomerPlayerData alloc] initWithEnvironmentKey:@"YOUR_COMPANY_NAME"];
    MUXSDKCustomerVideoData *customerVideoData = [[MUXSDKCustomerVideoData alloc] init];
    [customerVideoData setVideoId:@"my-video-id"];
    MUXSDKCustomData *customData = [[MUXSDKCustomData alloc] init];
    [customData setCustomData1:@"foo"];
    MUXSDKCustomerData *customerData = [[MUXSDKCustomerData alloc] initWithCustomerPlayerData:customerPlayerData
                                                                                    videoData:customerVideoData
                                                                                     viewData:nil
                                                                                   customData:customData];
    NSString *playName = MUXUniquePlayerName();
    [MUXSDKStats monitorAVPlayerLayer:controller withPlayerName:playName customerData:customerData];
    customerData = [[MUXSDKCustomerData alloc] initWithCustomerPlayerData:nil videoData:nil viewData:nil];
    [MUXSDKStats setCustomerData:customerData forPlayer:playName];
    NSArray *expectedEventTypes = @[MUXSDKPlaybackEventViewInitEventType,
                                    MUXSDKDataEventType,
                                    MUXSDKPlaybackEventPlayerReadyEventType
    ];
    [self assertPlayer:playName dispatchedEventTypes:expectedEventTypes];
    [self assertPlayer:playName dispatchedDataEventsAtIndex:1 withCustomerVideoData:@{@"vid": @"my-video-id"}];
    [self assertPlayer:playName dispatchedDataEventsAtIndex:1 withCustomData:@{@"c1" : @"foo"}];
    
    [MUXSDKStats destroyPlayer:playName];
    MUXSDKCustomerVideoData *updatedVideoData = [[MUXSDKCustomerVideoData alloc] init];
    [updatedVideoData setVideoId:@"my-video-id-2"];
    MUXSDKCustomerData *updatedCustomerData = [[MUXSDKCustomerData alloc] initWithCustomerPlayerData:customerPlayerData
                                                                                    videoData:updatedVideoData
                                                                                     viewData:nil
                                                                                   customData:nil];
    [MUXSDKStats monitorAVPlayerLayer:controller withPlayerName:playName customerData:updatedCustomerData];
    expectedEventTypes = @[MUXSDKPlaybackEventViewInitEventType,
                           MUXSDKDataEventType,
                           MUXSDKPlaybackEventPlayerReadyEventType,
                           MUXSDKPlaybackEventViewEndEventType,
                           MUXSDKPlaybackEventViewInitEventType,
                           MUXSDKDataEventType,
                           MUXSDKPlaybackEventPlayerReadyEventType,
                           MUXSDKPlaybackEventViewEndEventType
    ];
    [MUXSDKStats destroyPlayer:playName];
    [self assertPlayer:playName dispatchedEventTypes:expectedEventTypes];
    [self assertPlayer:playName dispatchedDataEventsAtIndex:5 withCustomerVideoData:@{@"vid": @"my-video-id-2"}];
    [self assertPlayer:playName dispatchedDataEventsAtIndex:5 withCustomData:nil];
}

- (void)testUpdateCustomerDataWithCustomData API_UNAVAILABLE(visionos) {
    XCTSkipIf(TARGET_OS_VISION);

    MuxMockAVPlayerLayer *controller = [[MuxMockAVPlayerLayer alloc] init];
    MUXSDKCustomerPlayerData *customerPlayerData = [[MUXSDKCustomerPlayerData alloc] initWithEnvironmentKey:@"YOUR_COMPANY_NAME"];
    MUXSDKCustomerVideoData *customerVideoData = [[MUXSDKCustomerVideoData alloc] init];
    MUXSDKCustomData *customData = [[MUXSDKCustomData alloc] init];
    [customData setCustomData1:@"foo"];
    MUXSDKCustomerData *customerData = [[MUXSDKCustomerData alloc] initWithCustomerPlayerData:customerPlayerData
                                                                                    videoData:customerVideoData
                                                                                     viewData:nil
                                                                                   customData:customData];
    NSString *playName = MUXUniquePlayerName();
    [MUXSDKStats monitorAVPlayerLayer:controller withPlayerName:playName customerData:customerData];
    customerData = [[MUXSDKCustomerData alloc] initWithCustomerPlayerData:nil videoData:nil viewData:nil];
    [MUXSDKStats setCustomerData:customerData forPlayer:playName];
    NSArray *expectedEventTypes = @[MUXSDKPlaybackEventViewInitEventType,
                                    MUXSDKDataEventType,
                                    MUXSDKPlaybackEventPlayerReadyEventType,
                                    MUXSDKPlaybackEventViewEndEventType,
    ];
    [MUXSDKStats destroyPlayer:playName];
    [self assertPlayer:playName dispatchedEventTypes:expectedEventTypes];
    [self assertPlayer:playName dispatchedDataEventsAtIndex:1 withCustomerVideoData:@{}];
    [self assertPlayer:playName dispatchedDataEventsAtIndex:1 withCustomData:@{@"c1" : @"foo"}];
}

- (void)testupdateCustomerDataWithNulls API_UNAVAILABLE(visionos) {
    XCTSkipIf(TARGET_OS_VISION);

    MuxMockAVPlayerLayer *controller = [[MuxMockAVPlayerLayer alloc] init];
    MUXSDKCustomerPlayerData *customerPlayerData = [[MUXSDKCustomerPlayerData alloc] initWithEnvironmentKey:@"YOUR_COMPANY_NAME"];
    MUXSDKCustomerVideoData *customerVideoData = [[MUXSDKCustomerVideoData alloc] init];
    MUXSDKCustomerViewData *customerViewData = [[MUXSDKCustomerViewData alloc] init];
    [customerViewData setViewSessionId:@"foo"];
    MUXSDKCustomerData *customerData = [[MUXSDKCustomerData alloc] initWithCustomerPlayerData:customerPlayerData
                                                                                    videoData:customerVideoData
                                                                                     viewData:customerViewData];
    NSString *playName = MUXUniquePlayerName();
    [MUXSDKStats monitorAVPlayerLayer:controller withPlayerName:playName customerData:customerData];
    customerData = [[MUXSDKCustomerData alloc] initWithCustomerPlayerData:nil videoData:nil viewData:nil];
    [MUXSDKStats setCustomerData:customerData forPlayer:playName];
    NSArray *expectedEventTypes = @[MUXSDKPlaybackEventViewInitEventType,
                                    MUXSDKDataEventType,
                                    MUXSDKPlaybackEventPlayerReadyEventType,
                                    MUXSDKPlaybackEventViewEndEventType,
    ];
    [MUXSDKStats destroyPlayer:playName];
    [self assertPlayer:playName dispatchedEventTypes:expectedEventTypes];
    [self assertPlayer:playName dispatchedDataEventsAtIndex:1 withCustomerVideoData:@{}];
    [self assertPlayer:playName dispatchedDataEventsAtIndex:1 withCustomerViewData:@{@"xseid" : @"foo"}];
}

- (void)testUpdateCustomerDataWithPlayerDataViewDataAndNullVideoData API_UNAVAILABLE(visionos) {
    XCTSkipIf(TARGET_OS_VISION);

    MuxMockAVPlayerLayer *controller = [[MuxMockAVPlayerLayer alloc] init];
    MUXSDKCustomerPlayerData *customerPlayerData = [[MUXSDKCustomerPlayerData alloc] initWithEnvironmentKey:@"YOUR_COMPANY_NAME"];
    MUXSDKCustomerVideoData *customerVideoData = [[MUXSDKCustomerVideoData alloc] init];
    [customerVideoData setVideoTitle:@"1234"];
    MUXSDKCustomerViewData *customerViewData = [[MUXSDKCustomerViewData alloc] init];
    [customerViewData setViewSessionId:@"foo"];
    MUXSDKCustomerData *customerData = [[MUXSDKCustomerData alloc] initWithCustomerPlayerData:customerPlayerData
                                                                                    videoData:customerVideoData
                                                                                     viewData:customerViewData];
    NSString *playName = MUXUniquePlayerName();
    [MUXSDKStats monitorAVPlayerLayer:controller withPlayerName:playName customerData:customerData];
    [customerPlayerData setPlayerVersion:@"playerVersionV1"];
    [customerViewData setViewSessionId:@"baz"];
    customerData = [[MUXSDKCustomerData alloc] initWithCustomerPlayerData:customerPlayerData videoData:nil viewData:customerViewData];
    [MUXSDKStats setCustomerData:customerData forPlayer:playName];
    NSArray *expectedEventTypes = @[MUXSDKPlaybackEventViewInitEventType,
                                    MUXSDKDataEventType,
                                    MUXSDKPlaybackEventPlayerReadyEventType,
                                    MUXSDKDataEventType,
                                    MUXSDKPlaybackEventViewEndEventType,
    ];
    [MUXSDKStats destroyPlayer:playName];
    [self assertPlayer:playName dispatchedEventTypes:expectedEventTypes];
//    [self assertPlayer:playName dispatchedDataEventsAtIndex:1 withCustomerVideoData:@{@"vtt": @"1234"}];
    [self assertPlayer:playName dispatchedDataEventsAtIndex:1 withCustomerViewData:@{@"xseid" : @"baz"}];
}

- (void)testupdateCustomerDataWithPlayerDataAndNullVideoData API_UNAVAILABLE(visionos) {
    XCTSkipIf(TARGET_OS_VISION);

    MuxMockAVPlayerLayer *controller = [[MuxMockAVPlayerLayer alloc] init];
    MUXSDKCustomerPlayerData *customerPlayerData = [[MUXSDKCustomerPlayerData alloc] initWithEnvironmentKey:@"YOUR_COMPANY_NAME"];
    MUXSDKCustomerVideoData *customerVideoData = [[MUXSDKCustomerVideoData alloc] init];
    MUXSDKCustomerData *customerData = [[MUXSDKCustomerData alloc] initWithCustomerPlayerData:customerPlayerData
                                                                                    videoData:customerVideoData
                                                                                     viewData:nil];
    NSString *playName = MUXUniquePlayerName();
    [MUXSDKStats monitorAVPlayerLayer:controller withPlayerName:playName customerData:customerData];
    [customerPlayerData setPlayerVersion:@"playerVersionV1"];
    customerData = [[MUXSDKCustomerData alloc] initWithCustomerPlayerData:customerPlayerData videoData:nil viewData:nil];
    [MUXSDKStats setCustomerData:customerData forPlayer:playName];
    NSArray *expectedEventTypes = @[MUXSDKPlaybackEventViewInitEventType,
                                    MUXSDKDataEventType,
                                    MUXSDKPlaybackEventPlayerReadyEventType,
                                    MUXSDKDataEventType,
                                    MUXSDKPlaybackEventViewEndEventType,
    ];
    [MUXSDKStats destroyPlayer:playName];
    [self assertPlayer:playName dispatchedEventTypes:expectedEventTypes];
}

- (void)testUpdateCustomerDataWithNullPlayerDataAndVideoData API_UNAVAILABLE(visionos) {
    XCTSkipIf(TARGET_OS_VISION);

    MuxMockAVPlayerLayer *controller = [[MuxMockAVPlayerLayer alloc] init];
    MUXSDKCustomerPlayerData *customerPlayerData = [[MUXSDKCustomerPlayerData alloc] initWithEnvironmentKey:@"YOUR_COMPANY_NAME"];
    MUXSDKCustomerVideoData *customerVideoData = [[MUXSDKCustomerVideoData alloc] init];
    MUXSDKCustomerData *customerData = [[MUXSDKCustomerData alloc] initWithCustomerPlayerData:customerPlayerData
                                                                                    videoData:customerVideoData
                                                                                     viewData:nil];

    NSString *playName = MUXUniquePlayerName();
    [MUXSDKStats monitorAVPlayerLayer:controller withPlayerName:playName customerData:customerData];
    [customerVideoData setVideoTitle:@"Updated VideoTitle"];
    customerData = [[MUXSDKCustomerData alloc] initWithCustomerPlayerData:nil
                                                                videoData:customerVideoData
                                                                 viewData:nil];
    [MUXSDKStats setCustomerData:customerData forPlayer:playName];
    NSArray *expectedEventTypes = @[MUXSDKPlaybackEventViewInitEventType,
                                    MUXSDKDataEventType,
                                    MUXSDKPlaybackEventPlayerReadyEventType,
                                    MUXSDKDataEventType,
                                    MUXSDKPlaybackEventViewEndEventType,
    ];
    [MUXSDKStats destroyPlayer:playName];
    [self assertPlayer:playName dispatchedEventTypes:expectedEventTypes];
}

- (void)testDestroyPlayer {
    MuxMockAVPlayerViewController *controller = [[MuxMockAVPlayerViewController alloc] init];
    MUXSDKCustomerPlayerData *customerPlayerData = [[MUXSDKCustomerPlayerData alloc] initWithEnvironmentKey:@"ENV_KEY"];
    MUXSDKCustomerVideoData *customerVideoData = [[MUXSDKCustomerVideoData alloc] init];
    MUXSDKCustomerData *customerData = [[MUXSDKCustomerData alloc] initWithCustomerPlayerData:customerPlayerData
                                                                                    videoData:customerVideoData
                                                                                     viewData:nil];
    [customerVideoData setVideoTitle:@"01234"];
    NSString *playName = MUXUniquePlayerName();
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

- (void) testOrientationChangeEvent API_UNAVAILABLE(visionos) {
    XCTSkipIf(TARGET_OS_VISION);

    MuxMockAVPlayerLayer *controller = [[MuxMockAVPlayerLayer alloc] init];
    MUXSDKCustomerPlayerData *customerPlayerData = [[MUXSDKCustomerPlayerData alloc] initWithEnvironmentKey:@"YOUR_COMPANY_NAME"];
    MUXSDKCustomerVideoData *customerVideoData = [[MUXSDKCustomerVideoData alloc] init];
    MUXSDKCustomerData *customerData = [[MUXSDKCustomerData alloc] initWithCustomerPlayerData:customerPlayerData
                                                                                    videoData:customerVideoData
                                                                                     viewData:nil];

    NSString *playName = MUXUniquePlayerName();
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
    XCTAssertEqualObjects(@(0.0), viewData.viewDeviceOrientationData.x);
    XCTAssertEqualObjects(@(0.0), viewData.viewDeviceOrientationData.y);
    XCTAssertEqualObjects(@(90.0), viewData.viewDeviceOrientationData.z);
    
    id<MUXSDKEventTyping> landscapeEvent = [MUXSDKCore eventAtIndex:4 forPlayer:playName];
    viewData = [((MUXSDKOrientationChangeEvent *) landscapeEvent) viewData];
    XCTAssertNotNil(viewData);
    XCTAssertEqualObjects(@(0.0), viewData.viewDeviceOrientationData.x);
    XCTAssertEqualObjects(@(0.0), viewData.viewDeviceOrientationData.y);
    XCTAssertEqualObjects(@(0.0), viewData.viewDeviceOrientationData.z);
    [MUXSDKStats destroyPlayer:playName];
}

- (void) testPlaybackModeChange {
    XCTSkipIf(TARGET_OS_VISION);
    
    MuxMockAVPlayerViewController *controller = [[MuxMockAVPlayerViewController alloc] init];
    MUXSDKCustomerPlayerData *customerPlayerData = [[MUXSDKCustomerPlayerData alloc] initWithEnvironmentKey:@"YOUR_COMPANY_NAME"];
    MUXSDKCustomerVideoData *customerVideoData = [[MUXSDKCustomerVideoData alloc] init];
    MUXSDKCustomerData *customerData = [[MUXSDKCustomerData alloc] initWithCustomerPlayerData:customerPlayerData
                                                                                    videoData:customerVideoData
                                                                                     viewData:nil];

    NSString *playName = MUXUniquePlayerName();
    [MUXSDKStats monitorAVPlayerViewController:controller withPlayerName:playName customerData:customerData];

    NSError *serialzationError = nil;
    NSData *encodedJSON = [NSJSONSerialization
                           dataWithJSONObject: @{@"encodedJSONItemStr": @"encodedJSONStringValue",@"encodedJSONItemNumber": @10000}
                           options: (NSJSONWritingOptions)0
                           error: &serialzationError];
    
    if (serialzationError) {
        XCTFail(@"Couldn't serialize the test data. Aborting test");
    }
    
    // no data
    [MUXSDKStats playbackModeChangeForPlayer:playName withPlaybackMode:MUXSDKPlaybackModeInline];
    // data as dict
    [MUXSDKStats playbackModeChangeForPlayer:playName
                            withPlaybackMode:MUXSDKPlaybackModeBackground
                                   extraData:@{@"item1": @1, @"item2": @"value"}
    ];
    // Different mode, same mode data. Data shouldn't be de-duped
    [MUXSDKStats playbackModeChangeForPlayer:playName
                            withPlaybackMode:@"custom_mode"
                               extraData:@{@"item1": @1, @"item2": @"value"}
    ];
    // Encoded JSON should be evaluated correctly
    [MUXSDKStats playbackModeChangeForPlayer:playName
                            withPlaybackMode:@"custom_mode"
                        extraEncodedJSONData:encodedJSON
    ];
    //.. There's also a case where we send non-json data via withExtraEncodedJSONData but it's tested in the core, and the core is mocked here so we can't do it in this test anyway
    
    NSArray<id <MUXSDKEventTyping>> *events = [MUXSDKCore snapshotOfEventsForPlayer:playName];
    NSPredicate *filterPlaybackModeEvents = [NSPredicate predicateWithBlock:^BOOL(id <MUXSDKEventTyping> _Nullable evaluatedObject, NSDictionary<NSString *,id> * _Nullable bindings) {
        return [[evaluatedObject getType] isEqualToString:@"playbackmodechange"];
    }];
    NSArray *playbackModeChangeEvents = [events filteredArrayUsingPredicate:filterPlaybackModeEvents];
    
    // 1st event
    MUXSDKPlaybackEvent *event0 = [playbackModeChangeEvents objectAtIndex:0];
    XCTAssertEqual(MUXSDKPlaybackModeInline, event0.playerData.playerPlaybackMode);
    
    // 2nd event
    NSString *expectedJson1 = @"{\"item1\":1,\"item2\":\"value\"}";
    MUXSDKPlaybackEvent *event1 = [playbackModeChangeEvents objectAtIndex:1];
    MUXSDKPlayerData *playerData1 = event1.playerData;
    XCTAssertEqual(MUXSDKPlaybackModeBackground, event1.playerData.playerPlaybackMode);
    XCTAssertTrue([expectedJson1 isEqualToString:[[NSString alloc] initWithData:playerData1.playerPlaybackModeData encoding:NSUTF8StringEncoding]]);
    
    // 3rd event
    NSString *expectedJson2 = @"{\"item1\":1,\"item2\":\"value\"}";
    MUXSDKPlaybackEvent *event2 = [playbackModeChangeEvents objectAtIndex:2];
    MUXSDKPlayerData *playerData2 = event2.playerData;
    XCTAssertEqual(@"custom_mode", event2.playerData.playerPlaybackMode);
    XCTAssertTrue([expectedJson2 isEqualToString:[[NSString alloc] initWithData:playerData2.playerPlaybackModeData encoding:NSUTF8StringEncoding]]);
    
    // 4th event
    // mac catalyst sorts your json keys whether you like it or not, but order's not important for the test
#if TARGET_OS_MACCATALYST
    NSString *expectedJson3 = @"{\"encodedJSONItemNumber\":10000,\"encodedJSONItemStr\":\"encodedJSONStringValue\"}";
#else
    NSString *expectedJson3 = @"{\"encodedJSONItemStr\":\"encodedJSONStringValue\",\"encodedJSONItemNumber\":10000}";
#endif
    MUXSDKPlaybackEvent *event3 = [playbackModeChangeEvents objectAtIndex:3];
    MUXSDKPlayerData *playerData3 = event3.playerData;
    XCTAssertEqual(@"custom_mode", event3.playerData.playerPlaybackMode);
    XCTAssertTrue([expectedJson3 isEqualToString:[[NSString alloc] initWithData:playerData3.playerPlaybackModeData encoding:NSUTF8StringEncoding]]);
}

- (void) testRenditionChangeEvent API_UNAVAILABLE(visionos) {
    XCTSkipIf(TARGET_OS_VISION);

    MuxMockAVPlayerLayer *controller = [[MuxMockAVPlayerLayer alloc] init];
    MUXSDKCustomerPlayerData *customerPlayerData = [[MUXSDKCustomerPlayerData alloc] initWithEnvironmentKey:@"YOUR_COMPANY_NAME"];
    MUXSDKCustomerVideoData *customerVideoData = [[MUXSDKCustomerVideoData alloc] init];
    MUXSDKCustomerData *customerData = [[MUXSDKCustomerData alloc] initWithCustomerPlayerData:customerPlayerData
                                                                                    videoData:customerVideoData
                                                                                     viewData:nil];

    NSString *playName = MUXUniquePlayerName();
    MUXSDKPlayerBinding *binding = [MUXSDKStats monitorAVPlayerLayer:controller withPlayerName:playName customerData:customerData];
    if (![[binding valueForKey:@"shouldTrackRenditionChanges"] boolValue]) {
        // Mocking via notification is only available when tracking via binding
        return;
    }
    [controller.player play];
    
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
                                    MUXSDKPlaybackEventPlayEventType,
                                    MUXSDKDataEventType,
                                    MUXSDKPlaybackEventRenditionChangeEventType,
                                    MUXSDKDataEventType,
                                    MUXSDKPlaybackEventRenditionChangeEventType

    ];
    [self assertPlayer:playName dispatchedEventTypes:expectedEventTypes];
    
    id<MUXSDKEventTyping> event = [MUXSDKCore eventAtIndex:4 forPlayer:playName];
    MUXSDKVideoData *videoData = [((MUXSDKDataEvent *) event) videoData];
    XCTAssertNotNil(videoData);
    XCTAssertEqualWithAccuracy(258157, [videoData.videoSourceAdvertisedBitrate doubleValue], FLT_EPSILON);
    
    event = [MUXSDKCore eventAtIndex:6 forPlayer:playName];
    videoData = [((MUXSDKDataEvent *) event) videoData];
    XCTAssertNotNil(videoData);
    XCTAssertEqualWithAccuracy(558157, [videoData.videoSourceAdvertisedBitrate doubleValue], FLT_EPSILON);
    XCTAssertNil(videoData.videoSourceAdvertisedFrameRate);
    
    [MUXSDKStats destroyPlayer:playName];
}

- (void) testRenditionChangeEventsWithSameBitrate API_UNAVAILABLE(visionos) {
    XCTSkipIf(TARGET_OS_VISION);
    
    MuxMockAVPlayerLayer *controller = [[MuxMockAVPlayerLayer alloc] init];
    MUXSDKCustomerPlayerData *customerPlayerData = [[MUXSDKCustomerPlayerData alloc] initWithEnvironmentKey:@"YOUR_COMPANY_NAME"];
    MUXSDKCustomerVideoData *customerVideoData = [[MUXSDKCustomerVideoData alloc] init];
    MUXSDKCustomerData *customerData = [[MUXSDKCustomerData alloc] initWithCustomerPlayerData:customerPlayerData
                                                                                    videoData:customerVideoData
                                                                                     viewData:nil];

    NSString *playName = @"Player";
    MUXSDKPlayerBinding *binding = [MUXSDKStats monitorAVPlayerLayer:controller withPlayerName:playName customerData:customerData];
    if (![[binding valueForKey:@"shouldTrackRenditionChanges"] boolValue]) {
        // Mocking via notification is only available when tracking via binding
        return;
    }
    [controller.player play];
    
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
                                    MUXSDKPlaybackEventPlayEventType,
                                    MUXSDKDataEventType,
                                    MUXSDKPlaybackEventRenditionChangeEventType,

    ];
    [self assertPlayer:playName dispatchedEventTypes:expectedEventTypes];
    
    id<MUXSDKEventTyping> event = [MUXSDKCore eventAtIndex:4 forPlayer:playName];
    MUXSDKVideoData *videoData = [((MUXSDKDataEvent *) event) videoData];
    XCTAssertNotNil(videoData);
    XCTAssertEqualWithAccuracy(258157, [videoData.videoSourceAdvertisedBitrate doubleValue], FLT_EPSILON);
    
    [MUXSDKStats destroyPlayer:playName];
}

- (void) testOrientationAndRenditionChangeEventSequence API_UNAVAILABLE(visionos) {
    XCTSkipIf(TARGET_OS_VISION);

    MuxMockAVPlayerLayer *controller = [[MuxMockAVPlayerLayer alloc] init];
    MUXSDKCustomerPlayerData *customerPlayerData = [[MUXSDKCustomerPlayerData alloc] initWithEnvironmentKey:@"YOUR_COMPANY_NAME"];
    MUXSDKCustomerVideoData *customerVideoData = [[MUXSDKCustomerVideoData alloc] init];
    MUXSDKCustomerData *customerData = [[MUXSDKCustomerData alloc] initWithCustomerPlayerData:customerPlayerData
                                                                                    videoData:customerVideoData
                                                                                     viewData:nil];

    NSString *playName = @"Player";
    MUXSDKPlayerBinding *binding = [MUXSDKStats monitorAVPlayerLayer:controller withPlayerName:playName customerData:customerData];
    if (![[binding valueForKey:@"shouldTrackRenditionChanges"] boolValue]) {
        // Mocking via notification is only available when tracking via binding
        return;
    }
    [controller.player play];

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
                                    MUXSDKPlaybackEventPlayEventType,
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
        @(5): @{BANDWIDTH: @(258157)},
        @(7): @{BANDWIDTH: @(1927853)},
        @(10): @{BANDWIDTH: @(258157)},
    }];

    [self assertPlayer:playName dispatchedPlaybackEvents:@{
        @(0): [NSNull null],
        @(2): [NSNull null],
        @(4): @{X: @(0.0), Y: @(0.0), Z: @(90.0)},
        @(6): [NSNull null],
        @(8): [NSNull null],
        @(9): @{X: @(0.0), Y: @(0.0), Z: @(0.0)},
        @(11): [NSNull null],
    }];

    [MUXSDKStats destroyPlayer:playName];
}

- (void)testDispatchError API_UNAVAILABLE(visionos) {
    XCTSkipIf(TARGET_OS_VISION);

    MuxMockAVPlayerLayer *controller = [[MuxMockAVPlayerLayer alloc] init];
    MUXSDKCustomerPlayerData *customerPlayerData = [[MUXSDKCustomerPlayerData alloc] initWithEnvironmentKey:@"YOUR_COMPANY_NAME"];
    MUXSDKCustomerVideoData *customerVideoData = [[MUXSDKCustomerVideoData alloc] init];
    MUXSDKCustomerData *customerData = [[MUXSDKCustomerData alloc] initWithCustomerPlayerData:customerPlayerData
                                                                                    videoData:customerVideoData
                                                                                     viewData:nil];

    NSString *playName = MUXUniquePlayerName();
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

- (void)testDispatchErrorWithSeverity API_UNAVAILABLE(visionos) {
    XCTSkipIf(TARGET_OS_VISION);

    MuxMockAVPlayerLayer *controller = [[MuxMockAVPlayerLayer alloc] init];
    MUXSDKCustomerPlayerData *customerPlayerData = [[MUXSDKCustomerPlayerData alloc] initWithEnvironmentKey:@"YOUR_COMPANY_NAME"];
    MUXSDKCustomerVideoData *customerVideoData = [[MUXSDKCustomerVideoData alloc] init];
    MUXSDKCustomerData *customerData = [[MUXSDKCustomerData alloc] initWithCustomerPlayerData:customerPlayerData
                                                                                    videoData:customerVideoData
                                                                                     viewData:nil];
    NSString *playName = MUXUniquePlayerName();
    [MUXSDKStats monitorAVPlayerLayer:controller withPlayerName:playName customerData:customerData];

    [MUXSDKStats dispatchError:@"12345"
                   withMessage:@"Something aint right"
                      severity:MUXSDKErrorSeverityWarning
                     forPlayer:playName];

    NSArray *expectedEventTypes = @[MUXSDKPlaybackEventViewInitEventType,
                                    MUXSDKDataEventType,
                                    MUXSDKPlaybackEventPlayerReadyEventType,
                                    MUXSDKPlaybackEventErrorEventType,
    ];
    [self assertPlayer:playName dispatchedEventTypes:expectedEventTypes];

    id<MUXSDKEventTyping> event = [MUXSDKCore eventAtIndex:3
                                                 forPlayer:playName];
    XCTAssertTrue([event isPlayback] && [[event getType] isEqualToString:MUXSDKPlaybackEventErrorEventType]);

    MUXSDKErrorEvent *errorEvent = (MUXSDKErrorEvent *)event;
    XCTAssertTrue(errorEvent.severity == MUXSDKErrorSeverityWarning);

    [MUXSDKStats destroyPlayer:playName];
}

- (void)testDispatchBusinessExceptionError API_UNAVAILABLE(visionos) {
    XCTSkipIf(TARGET_OS_VISION);

    MuxMockAVPlayerLayer *controller = [[MuxMockAVPlayerLayer alloc] init];
    MUXSDKCustomerPlayerData *customerPlayerData = [[MUXSDKCustomerPlayerData alloc] initWithEnvironmentKey:@"YOUR_COMPANY_NAME"];
    MUXSDKCustomerVideoData *customerVideoData = [[MUXSDKCustomerVideoData alloc] init];
    MUXSDKCustomerData *customerData = [[MUXSDKCustomerData alloc] initWithCustomerPlayerData:customerPlayerData
                                                                                    videoData:customerVideoData
                                                                                     viewData:nil];
    NSString *playName = MUXUniquePlayerName();
    [MUXSDKStats monitorAVPlayerLayer:controller withPlayerName:playName customerData:customerData];

    [MUXSDKStats dispatchError:@"12345"
                   withMessage:@"Something aint right"
                      severity:MUXSDKErrorSeverityWarning
           isBusinessException:YES
                     forPlayer:playName];

    NSArray *expectedEventTypes = @[MUXSDKPlaybackEventViewInitEventType,
                                    MUXSDKDataEventType,
                                    MUXSDKPlaybackEventPlayerReadyEventType,
                                    MUXSDKPlaybackEventErrorEventType,
    ];
    [self assertPlayer:playName dispatchedEventTypes:expectedEventTypes];

    id<MUXSDKEventTyping> event = [MUXSDKCore eventAtIndex:3
                                                 forPlayer:playName];
    XCTAssertTrue([event isPlayback] && [[event getType] isEqualToString:MUXSDKPlaybackEventErrorEventType]);

    MUXSDKErrorEvent *errorEvent = (MUXSDKErrorEvent *)event;
    XCTAssertTrue(errorEvent.isBusinessException);
    XCTAssertTrue(errorEvent.severity == MUXSDKErrorSeverityWarning);

    [MUXSDKStats destroyPlayer:playName];
}

@end
