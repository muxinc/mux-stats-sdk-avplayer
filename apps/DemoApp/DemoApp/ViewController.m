#import "ViewController.h"

@import MUXSDKStats;

static NSString *DEMO_PLAYER_NAME = @"demoplayer";

NSString *const livestreamTestURL = @"https://stream.mux.com/v69RSHhFelSm4701snP22dYz2jICy4E4FUyk02rW4gxRM.m3u8?low_latency=false";
NSString *const livestreamLowLatencyTestURL = @"https://stream.mux.com/v69RSHhFelSm4701snP22dYz2jICy4E4FUyk02rW4gxRM.m3u8";
NSString *const vodTestURL = @"http://qthttp.apple.com.edgesuite.net/1010qwoeiuryfg/sl.m3u8";

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.playerViewController = [[AVPlayerViewController alloc] init];
    self.playerViewController.view.accessibilityIdentifier = @"AVPlayerView";
    
    AVPlayer *player;
    if ([[self testScenario] isEqual:@"UPDATE_CUSTOM_DIMENSIONS"]) {
        player = [self testUpdateCustomDimensions];
    } else if ([[self testScenario] isEqual:@"CHANGE_VIDEO"]) {
        player = [self testVideoChange];
    } else if ([[self testScenario] isEqual:@"AV_QUEUE"]) {
        player = [self testAVQueuePlayer];
    } else if ([[self testScenario] isEqual:@"PROGRAM_CHANGE"]) {
        player = [self testProgramChange];
    } else if ([[self testScenario] isEqual:@"LIVESTREAM"]) {
        player = [self testAVPlayer: livestreamTestURL];
    } else if ([[self testScenario] isEqual:@"LOW_LATENCY_LIVESTREAM"]) {
        player = [self testAVPlayer: livestreamLowLatencyTestURL];
    } else if ([[self testScenario] isEqual:@"AUTO_SEEK"]) {
        player = [self testAutoSeek];
    } else if ([[self testScenario] isEqual:@"UI_SEEK"]) {
        player = [self testAVPlayer: vodTestURL];
    } else {
        player = [self testAVPlayer];
    }
    [self setupAVPlayerViewController: player];
}

#pragma mark Orientation Changes

- (void)viewWillTransitionToSize:(CGSize)size
       withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {} completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        [MUXSDKStats orientationChangeForPlayer:DEMO_PLAYER_NAME withOrientation:[self viewOrientationForSize:size]];
    }];
}

- (MUXSDKViewOrientation) viewOrientationForSize:(CGSize)size {
    return (size.width > size.height) ? MUXSDKViewOrientationLandscape : MUXSDKViewOrientationPortrait;
}

#pragma mark Test Cases

- (AVPlayer *)testAVQueuePlayer {
    AVPlayerItem *item1 = [AVPlayerItem playerItemWithURL:[NSURL URLWithString:@"https://bitdash-a.akamaihd.net/content/sintel/hls/playlist.m3u8"]];
    AVPlayerItem *item2 = [AVPlayerItem playerItemWithURL:[NSURL URLWithString:vodTestURL]];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playerItemDidReachEnd:)
                                                 name:AVPlayerItemDidPlayToEndTimeNotification
                                               object:item1];
    AVQueuePlayer *player = [[AVQueuePlayer alloc] initWithItems:@[item1, item2]];
    return player;
}


- (AVPlayer *)testAVPlayer {
    return [self testAVPlayer:vodTestURL];
}

- (AVPlayer *)testAVPlayer: (NSString *) testURL {
    NSURL* videoURL = [NSURL URLWithString:testURL];
    AVPlayer *player = [AVPlayer playerWithURL:videoURL];
    return player;
}

- (AVPlayer *)testVideoChange {
    NSURL* videoURL = [NSURL URLWithString:vodTestURL];
    AVPlayer *player = [AVPlayer playerWithURL:videoURL];
    
    // After 5 seconds, we'll change the video.
    _timer = [NSTimer scheduledTimerWithTimeInterval:5.0
                                              target:self
                                            selector:@selector(changeVideo:)
                                            userInfo:nil
                                             repeats:NO];
    return player;
}

- (AVPlayer *)testProgramChange{
    NSURL* videoURL = [NSURL URLWithString:vodTestURL];
    AVPlayer *player = [AVPlayer playerWithURL:videoURL];
    

    // Schedue two program change events, in 30s and 60s
    _timer = [NSTimer scheduledTimerWithTimeInterval:30.0
                                              target:self
                                            selector:@selector(changeProgram:)
                                            userInfo:[self testCustomerData:@"ProgramChange1"]
                                             repeats:NO];

    _timer = [NSTimer scheduledTimerWithTimeInterval:60.0
                                              target:self
                                            selector:@selector(changeProgram:)
                                            userInfo:[self testCustomerData:@"ProgramChange2"]
                                             repeats:NO];

    return player;
}

- (MUXSDKCustomerData *)testCustomerData:(nonnull NSString *)prefix {
    MUXSDKCustomerPlayerData *playerData = nil;

    MUXSDKCustomerVideoData *videoData = [MUXSDKCustomerVideoData new];
    videoData.videoTitle = [NSString stringWithFormat:@"%@ Test VideoTitle", prefix];
    videoData.videoId = [NSString stringWithFormat:@"%@ Test VideoID", prefix];
    videoData.videoSeries = [NSString stringWithFormat:@"%@ Test VideoSeries", prefix];

    MUXSDKCustomerViewData *viewData = [MUXSDKCustomerViewData new];
    viewData.viewSessionId = [NSString stringWithFormat:@"%@ Test SessionID", prefix];

    MUXSDKCustomData *customData = [MUXSDKCustomData new];
    customData.customData1 = [NSString stringWithFormat:@"%@ Custom1", prefix];
    customData.customData2 = [NSString stringWithFormat:@"%@ Custom2", prefix];
    customData.customData3 = [NSString stringWithFormat:@"%@ Custom3", prefix];
    customData.customData4 = [NSString stringWithFormat:@"%@ Custom4", prefix];
    customData.customData5 = [NSString stringWithFormat:@"%@ Custom5", prefix];

    return [[MUXSDKCustomerData alloc] initWithCustomerPlayerData:playerData videoData:videoData viewData:viewData customData:customData];
}

- (AVPlayer *)testUpdateCustomDimensions {
    NSURL *videoURL = [NSURL URLWithString:@"https://bitdash-a.akamaihd.net/content/sintel/hls/playlist.m3u8"];
    AVPlayer *player = [AVPlayer playerWithURL:videoURL];
    // After 5 seconds, we'll update the custom dimensions
    _timer = [NSTimer scheduledTimerWithTimeInterval:5.0
                                              target:self
                                            selector:@selector(updateCustomData:)
                                            userInfo:nil
                                             repeats:NO];
    return player;
}

- (AVPlayer *)testAutoSeek {
    AVPlayer *player = [AVPlayer playerWithURL:[NSURL URLWithString:vodTestURL]];
    _timer = [NSTimer scheduledTimerWithTimeInterval:15.0
                                              target:self
                                            selector:@selector(autoSeek:)
                                            userInfo:nil
                                             repeats:NO];
    return player;
}

- (void)setupAVPlayerViewController:(AVPlayer *)player {
    _player = player;
    _playerViewController.player = player;
    
    // TODO: Add your property key!
    NSString *envKey = [NSProcessInfo.processInfo.environment objectForKey:@"ENV_KEY"];
    if(envKey == nil) {
        envKey = @"YOUR ENV KEY HERE";
    }
    MUXSDKCustomData *customData = [[MUXSDKCustomData alloc] init];
    // We use c1 to tag which views were generated by which test cases
    [customData setCustomData1:[self testScenario]];
    [customData setCustomData2:@"my-custom-dimension-2"];
    MUXSDKCustomerPlayerData *playerData = [[MUXSDKCustomerPlayerData alloc] initWithPropertyKey:envKey];
    MUXSDKCustomerVideoData *videoData = [MUXSDKCustomerVideoData new];
    videoData.videoTitle = @"Big Buck Bunny";
    videoData.videoId = @"bigbuckbunny";
    videoData.videoSeries = @"animation";
    MUXSDKCustomerViewData *viewData= [[MUXSDKCustomerViewData alloc] init];
    viewData.viewSessionId = @"some session id";
    MUXSDKCustomerViewerData *viewerData = [[MUXSDKCustomerViewerData alloc] init];
    viewerData.viewerApplicationName = @"MUX DemoApp";
    viewerData.viewerDeviceCategory = @"kiosk";
    viewerData.viewerDeviceModel = @"ABC-12345";
    viewerData.viewerDeviceManufacturer = @"Example Display Systems, Inc";
    MUXSDKCustomerData *customerData = [[MUXSDKCustomerData alloc] initWithCustomerPlayerData:playerData
                                                                                    videoData:videoData
                                                                                     viewData:viewData
                                                                                   customData:customData
                                                                                   viewerData:viewerData];
    _playerBinding = [MUXSDKStats monitorAVPlayerViewController:_playerViewController
                                                 withPlayerName:DEMO_PLAYER_NAME
                                                   customerData:customerData];
    [_player play];
    [self addChildViewController:_playerViewController];
    _playerViewController.view.frame = self.view.bounds;
    [self.view insertSubview:_playerViewController.view atIndex:0];
    [_playerViewController didMoveToParentViewController:self];
}

- (void)changeVideo:(NSTimer *)timer {
    MUXSDKCustomerVideoData *videoData = [MUXSDKCustomerVideoData new];
    videoData.videoTitle = @"Apple Keynote";
    videoData.videoId = @"applekeynote2010";
    MUXSDKCustomData *customData = [[MUXSDKCustomData alloc] init];
    [customData setCustomData1:[self testScenario]];
    [customData setCustomData2:@"change-video-to-apple-keynote"];
    MUXSDKCustomerData *customerData = [[MUXSDKCustomerData alloc] init];
    customerData.customData = customData;
    customerData.customerVideoData = videoData;
    
    [MUXSDKStats videoChangeForPlayer:DEMO_PLAYER_NAME
                     withCustomerData:customerData];
    NSURL* videoURL = [NSURL URLWithString:vodTestURL];
    AVPlayerItem *keynote = [AVPlayerItem playerItemWithURL:videoURL];
    [_player replaceCurrentItemWithPlayerItem:keynote];
    [_player play];
}

- (void)changeProgram:(NSTimer *)timer {
    MUXSDKCustomerData *customerData = (MUXSDKCustomerData *) timer.userInfo;
    [MUXSDKStats programChangeForPlayer:DEMO_PLAYER_NAME withCustomerData:customerData];
}

- (void)playerItemDidReachEnd:(NSNotification *)notification {
    MUXSDKCustomerVideoData *videoData = [MUXSDKCustomerVideoData new];
    videoData.videoTitle = @"Apple Keynote";
    videoData.videoId = @"applekeynote2010";
    
    MUXSDKCustomerData *customerData = [
        [MUXSDKCustomerData alloc] initWithCustomerPlayerData:nil
        videoData:videoData
        viewData:nil
        customData:nil
        viewerData:nil
    ];
    
    [MUXSDKStats videoChangeForPlayer:DEMO_PLAYER_NAME withCustomerData:customerData];
}

- (void) updateCustomData:(NSTimer *)timer {
    MUXSDKCustomData *customData = [[MUXSDKCustomData alloc] init];
    [customData setCustomData2:@"update-custom-dimension-2"];
    MUXSDKCustomerData *customerData = [[MUXSDKCustomerData alloc] init];
    customerData.customData = customData;
    [MUXSDKStats setCustomerData:customerData forPlayer:DEMO_PLAYER_NAME];
}

- (void)autoSeek:(NSTimer *)timer {
    [_player.currentItem seekToTime:CMTimeMakeWithSeconds(15, 60000)];
}

- (NSString *) testScenario {
    return [NSProcessInfo.processInfo.environment objectForKey:@"TEST_SCENARIO"];
}

@end
