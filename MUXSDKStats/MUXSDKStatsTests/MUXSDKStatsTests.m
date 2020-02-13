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

- (void)testVideoChangeForAVPlayerViewController{
    MuxMockAVPlayerViewController *controller = [[MuxMockAVPlayerViewController alloc] init];
    MUXSDKCustomerPlayerData *customerPlayerData = [[MUXSDKCustomerPlayerData alloc] initWithEnvironmentKey:@"YOUR_COMPANY_NAME"];
    MUXSDKCustomerVideoData *customerVideoData = [[MUXSDKCustomerVideoData alloc] init];
    [customerVideoData setVideoTitle:@"01234"];
    NSString *playName = @"Player";
    MUXSDKPlayerBinding *playerBinding = [MUXSDKStats monitorAVPlayerViewController:controller withPlayerName:playName playerData:customerPlayerData videoData:customerVideoData];
    XCTAssertNotNil(playerBinding, "expected monitorAVPlayerViewController to return a playerBinding");
    [customerVideoData setVideoTitle:@"56789"];
    [MUXSDKStats videoChangeForPlayer:playName withVideoData:customerVideoData];
    NSArray *expectedEventTypes = @[MUXSDKPlaybackEventViewInitEventType,
                                    MUXSDKDataEventType,
                                    MUXSDKPlaybackEventPlayerReadyEventType,
                                    MUXSDKPlaybackEventViewEndEventType
    ];
    [self assertPlayer:playName dispatchedEventTypes:expectedEventTypes];
    [MUXSDKStats destroyPlayer:playName];
}

- (void)testVideoChangeForAVPlayerLayer{
    MuxMockAVPlayerLayer *controller = [[MuxMockAVPlayerLayer alloc] init];
    MUXSDKCustomerPlayerData *customerPlayerData = [[MUXSDKCustomerPlayerData alloc] initWithEnvironmentKey:@"YOUR_COMPANY_NAME"];
    MUXSDKCustomerVideoData *customerVideoData = [[MUXSDKCustomerVideoData alloc] init];
    [customerVideoData setVideoTitle:@"01234"];
    NSString *playName = @"Player";
    MUXSDKPlayerBinding *playerBinding = [MUXSDKStats monitorAVPlayerLayer:controller withPlayerName:playName playerData:customerPlayerData videoData:customerVideoData];
    XCTAssertNotNil(playerBinding, "expected monitorAVPlayerLayer to return a playerBinding");
    [customerVideoData setVideoTitle:@"56789"];
    [MUXSDKStats videoChangeForPlayer:playName withVideoData:customerVideoData];
    NSArray *expectedEventTypes = @[MUXSDKPlaybackEventViewInitEventType,
                                    MUXSDKDataEventType,
                                    MUXSDKPlaybackEventPlayerReadyEventType,
                                    MUXSDKPlaybackEventViewEndEventType
    ];
    [self assertPlayer:playName dispatchedEventTypes:expectedEventTypes];
    [MUXSDKStats destroyPlayer:playName];
}

- (void)testupdateCustomerDataWithNulls{
    MuxMockAVPlayerLayer *controller = [[MuxMockAVPlayerLayer alloc] init];
    MUXSDKCustomerPlayerData *customerPlayerData = [[MUXSDKCustomerPlayerData alloc] initWithEnvironmentKey:@"YOUR_COMPANY_NAME"];
    MUXSDKCustomerVideoData *customerVideoData = [[MUXSDKCustomerVideoData alloc] init];
    NSString *playName = @"Player";
    [MUXSDKStats monitorAVPlayerLayer:controller withPlayerName:playName playerData:customerPlayerData videoData:customerVideoData];
    [MUXSDKStats updateCustomerDataForPlayer:playName withPlayerData:NULL withVideoData:NULL];
    NSArray *expectedEventTypes = @[MUXSDKPlaybackEventViewInitEventType,
                                    MUXSDKDataEventType,
                                    MUXSDKPlaybackEventPlayerReadyEventType
    ];
    [self assertPlayer:playName dispatchedEventTypes:expectedEventTypes];
    [MUXSDKStats destroyPlayer:playName];
}

- (void)testupdateCustomerDataWithPlayerDataAndNullVideoData{
    MuxMockAVPlayerLayer *controller = [[MuxMockAVPlayerLayer alloc] init];
    MUXSDKCustomerPlayerData *customerPlayerData = [[MUXSDKCustomerPlayerData alloc] initWithEnvironmentKey:@"YOUR_COMPANY_NAME"];
    MUXSDKCustomerVideoData *customerVideoData = [[MUXSDKCustomerVideoData alloc] init];
    NSString *playName = @"Player";
    [MUXSDKStats monitorAVPlayerLayer:controller withPlayerName:playName playerData:customerPlayerData videoData:customerVideoData];
    [customerPlayerData setPlayerVersion:@"playerVersionV1"];
    [MUXSDKStats updateCustomerDataForPlayer:playName withPlayerData:customerPlayerData withVideoData:NULL];
    NSArray *expectedEventTypes = @[MUXSDKPlaybackEventViewInitEventType,
                                    MUXSDKDataEventType,
                                    MUXSDKPlaybackEventPlayerReadyEventType,
                                    MUXSDKDataEventType
    ];
    [self assertPlayer:playName dispatchedEventTypes:expectedEventTypes];
    [MUXSDKStats destroyPlayer:playName];
}

- (void)testupdateCustomerDataWithNullPlayerDataAndVideoData{
    MuxMockAVPlayerLayer *controller = [[MuxMockAVPlayerLayer alloc] init];
    MUXSDKCustomerPlayerData *customerPlayerData = [[MUXSDKCustomerPlayerData alloc] initWithEnvironmentKey:@"YOUR_COMPANY_NAME"];
    MUXSDKCustomerVideoData *customerVideoData = [[MUXSDKCustomerVideoData alloc] init];
    NSString *playName = @"Player";
    [MUXSDKStats monitorAVPlayerLayer:controller withPlayerName:playName playerData:customerPlayerData videoData:customerVideoData];
    [customerVideoData setVideoTitle:@"Updated VideoTitle"];
    [MUXSDKStats updateCustomerDataForPlayer:playName withPlayerData:NULL withVideoData:customerVideoData];
    NSArray *expectedEventTypes = @[MUXSDKPlaybackEventViewInitEventType,
                                    MUXSDKDataEventType,
                                    MUXSDKPlaybackEventPlayerReadyEventType,
                                    MUXSDKDataEventType
    ];
    [self assertPlayer:playName dispatchedEventTypes:expectedEventTypes];
    [MUXSDKStats destroyPlayer:playName];
}

- (void) testOrientationChangeEvent {
    MuxMockAVPlayerLayer *controller = [[MuxMockAVPlayerLayer alloc] init];
    MUXSDKCustomerPlayerData *customerPlayerData = [[MUXSDKCustomerPlayerData alloc] initWithEnvironmentKey:@"YOUR_COMPANY_NAME"];
    MUXSDKCustomerVideoData *customerVideoData = [[MUXSDKCustomerVideoData alloc] init];
    NSString *playName = @"Player";
    [MUXSDKStats monitorAVPlayerLayer:controller withPlayerName:playName playerData:customerPlayerData videoData:customerVideoData];
    
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
    NSString *playName = @"Player";
    [MUXSDKStats monitorAVPlayerLayer:controller withPlayerName:playName playerData:customerPlayerData videoData:customerVideoData];
    
    NSDictionary *renditionInfo = @{
        RenditionChangeNotificationInfoAdvertisedBitrate: @(258157)
    };
    [[NSNotificationCenter defaultCenter] postNotificationName:RenditionChangeNotification object:renditionInfo];

    NSArray *expectedEventTypes = @[MUXSDKPlaybackEventViewInitEventType,
                                    MUXSDKDataEventType,
                                    MUXSDKPlaybackEventPlayerReadyEventType,
                                    MUXSDKDataEventType,
                                    MUXSDKPlaybackEventRenditionChangeEventType
    ];
    [self assertPlayer:playName dispatchedEventTypes:expectedEventTypes];
    
    id<MUXSDKEventTyping> dataEvent = [MUXSDKCore eventAtIndex:3 forPlayer:playName];
    MUXSDKVideoData *videoData = [((MUXSDKDataEvent *) dataEvent) videoData];
    XCTAssertNotNil(videoData);
    XCTAssertEqual(@(258157.0), videoData.videoSourceAdvertisedBitrate);
    [MUXSDKStats destroyPlayer:playName];
}

- (void) assertPlayer:(NSString *)name dispatchedEventTypes:(NSArray *) expectedEventTypes {
    for (int i = 0; i < expectedEventTypes.count; i++) {
        id<MUXSDKEventTyping> event = [MUXSDKCore eventAtIndex:i forPlayer:name];
        XCTAssertEqual([event getType], [expectedEventTypes objectAtIndex:i]);
    }
}
@end
