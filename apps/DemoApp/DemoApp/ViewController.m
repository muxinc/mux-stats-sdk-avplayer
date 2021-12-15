#import "ViewController.h"

@import MUXSDKStats;
@import Mux_Stats_Google_IMA;

static NSString *DEMO_PLAYER_NAME = @"demoplayer";
NSString *const kAdTagURLStringPreRollMidRollPostRoll = @"https://pubads.g.doubleclick.net/gampad/ads?sz=640x480&iu=/124319096/external/ad_rule_samples&ciu_szs=300x250&ad_rule=1&impl=s&gdfp_req=1&env=vp&output=vmap&unviewed_position_start=1&cust_params=deployment%3Ddevsite%26sample_ar%3Dpremidpostlongpod&cmsid=496&vid=short_tencue&correlator=";

NSString *const livestreamTestURL = @"https://stream.mux.com/v69RSHhFelSm4701snP22dYz2jICy4E4FUyk02rW4gxRM.m3u8?low_latency=false";
NSString *const livestreamLowLatencyTestURL = @"https://stream.mux.com/v69RSHhFelSm4701snP22dYz2jICy4E4FUyk02rW4gxRM.m3u8";
NSString *const vodTestURL = @"http://qthttp.apple.com.edgesuite.net/1010qwoeiuryfg/sl.m3u8";

@interface ViewController () {
    AVPlayer *_avplayer;
    AVPlayerViewController *_avplayerController;
    NSTimer *_timer;
    
    // IMA SDK variables
    IMAAdsLoader *_adsLoader;
    IMAAdsManager *_adsManager;
    IMAAVPlayerContentPlayhead *_contentPlayhead;
    MuxImaListener *_imaListener;
    MUXSDKPlayerBinding *_playerBinding;
    IMAPictureInPictureProxy *_pictureInPictureProxy;
}
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _avplayerController = [AVPlayerViewController new];
    _avplayerController.view.accessibilityIdentifier = @"AVPlayerView";
    _avplayerController.delegate = self;
    
    AVPlayer *player;
    if ([[self testScenario] isEqualToString:@"IMA"]) {
        player = [self testImaSDK];
    } else if ([[self testScenario] isEqualToString:@"IMAPIP"]) {
        player = [self testImaPIPSDK];
    } else if ([[self testScenario] isEqual:@"UPDATE_CUSTOM_DIMENSIONS"]) {
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
    } else {
        player = [self testAVPlayer];
    }
    [self setupAVPlayerViewController: player];
}

- (void) viewDidAppear:(BOOL)animated {
    if ([[self testScenario] isEqualToString:@"IMA"] || [[self testScenario] isEqualToString:@"IMAPIP"]) {
        NSString *adTagURL = [NSProcessInfo.processInfo.environment objectForKey:@"AD_TAG_URL"];
        if (adTagURL == nil) {
            adTagURL = kAdTagURLStringPreRollMidRollPostRoll;
        }
        [self requestAdsWithURL:adTagURL];
    }
}

#pragma mark - Request Ads

- (void) requestAdsWithURL:(NSString *) adTagURL {
    IMAAdDisplayContainer *adDisplayContainer = [[IMAAdDisplayContainer alloc] initWithAdContainer:self.view viewController:self];
    IMAAdsRequest *request;
    
    if ([[self testScenario] isEqualToString:@"IMAPIP"]) {
        [_imaListener setPictureInPicture:YES];
        _pictureInPictureProxy =
            [[IMAPictureInPictureProxy alloc] initWithAVPictureInPictureControllerDelegate:self];
        
        IMAAVPlayerVideoDisplay *avPlayerVideoDisplay = [[IMAAVPlayerVideoDisplay alloc] initWithAVPlayer:_avplayer];
        
        request = [[IMAAdsRequest alloc] initWithAdTagUrl:adTagURL
                                       adDisplayContainer:adDisplayContainer
                                     avPlayerVideoDisplay:avPlayerVideoDisplay
                                    pictureInPictureProxy:_pictureInPictureProxy
                                              userContext:nil];
    } else {
        request = [[IMAAdsRequest alloc] initWithAdTagUrl:adTagURL
                                       adDisplayContainer:adDisplayContainer
                                          contentPlayhead:_contentPlayhead
                                              userContext:nil];
    }
    
    [_adsLoader requestAdsWithRequest:request];
}

- (void)contentDidFinishPlaying:(NSNotification *)notification {
    if (notification.object == _avplayer.currentItem) {
        [_adsLoader contentComplete];
    }
}

#pragma mark - IMAAdsLoaderDelegate

- (void)adsLoader:(IMAAdsLoader *)loader adsLoadedWithData:(IMAAdsLoadedData *)adsLoadedData {
    _adsManager = adsLoadedData.adsManager;
    _adsManager.delegate = self;
    IMAAdsRenderingSettings *adsRenderingSettings = [[IMAAdsRenderingSettings alloc] init];
    adsRenderingSettings.linkOpenerPresentingController = self;
    [_adsManager initializeWithAdsRenderingSettings:adsRenderingSettings];
}

- (void)adsLoader:(IMAAdsLoader *)loader failedWithErrorData:(IMAAdLoadingErrorData *)adErrorData {
    NSLog(@"Error loading ads: %@", adErrorData.adError.message);
    [_avplayerController.player play];
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


#pragma mark AdsManager Delegates

- (void)adsManager:(IMAAdsManager *)adsManager didReceiveAdEvent:(IMAAdEvent *)event {
    // When the SDK notified us that ads have been loaded, play them.
    if (event.type == kIMAAdEvent_LOADED) {
        [_adsManager start];
    }
    if (_imaListener != nil) {
        [_imaListener dispatchEvent: event];
    }
}

- (void)adsManager:(IMAAdsManager *)adsManager didReceiveAdError:(IMAAdError *)error {
    [_avplayer play];
    if (_imaListener != nil) {
        [_imaListener dispatchError: error.message];
    }
}

- (void)adsManagerDidRequestContentPause:(IMAAdsManager *)adsManager {
    [_avplayer pause];
    [_imaListener onContentPauseOrResume:true];
}

- (void)adsManagerDidRequestContentResume:(IMAAdsManager *)adsManager {
    [_avplayer play];
    [_imaListener onContentPauseOrResume:false];
}

#pragma mark Test Cases

- (AVPlayer *)testImaSDK {
    _adsLoader = [[IMAAdsLoader alloc] initWithSettings:nil];
    _adsLoader.delegate = self;
    NSURL *contentURL = [NSURL URLWithString:@"https://bitdash-a.akamaihd.net/content/sintel/hls/playlist.m3u8"];
    AVPlayer *player = [AVPlayer playerWithURL:contentURL];
    _contentPlayhead = [[IMAAVPlayerContentPlayhead alloc] initWithAVPlayer:player];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(contentDidFinishPlaying:)
                                                 name:AVPlayerItemDidPlayToEndTimeNotification
                                               object:player.currentItem];
    return player;
}

- (AVPlayer *)testImaPIPSDK {
    // Set the AVAudioSession properties to support background playback
    [[AVAudioSession sharedInstance] setActive:YES error:nil];
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
    
    // Enable background playback in IMASettings
    IMASettings *settings = [[IMASettings alloc] init];
    settings.enableBackgroundPlayback = YES;
    
    // Setup Ads Loader
    _adsLoader = [[IMAAdsLoader alloc] initWithSettings:settings];
    _adsLoader.delegate = self;
    NSURL *contentURL = [NSURL URLWithString:@"https://bitdash-a.akamaihd.net/content/sintel/hls/playlist.m3u8"];
    AVPlayer *player = [AVPlayer playerWithURL:contentURL];
    _contentPlayhead = [[IMAAVPlayerContentPlayhead alloc] initWithAVPlayer:player];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(contentDidFinishPlaying:)
                                                 name:AVPlayerItemDidPlayToEndTimeNotification
                                               object:player.currentItem];
    return player;
}

- (AVPlayer *)testAVQueuePlayer {
    AVPlayerItem *item1 = [AVPlayerItem playerItemWithURL:[NSURL URLWithString:@"https://bitdash-a.akamaihd.net/content/sintel/hls/playlist.m3u8"]];
    AVPlayerItem *item2 = [AVPlayerItem playerItemWithURL:[NSURL URLWithString:@"http://qthttp.apple.com.edgesuite.net/1010qwoeiuryfg/sl.m3u8"]];
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
    NSURL* videoURL = [NSURL URLWithString:@"http://qthttp.apple.com.edgesuite.net/1010qwoeiuryfg/sl.m3u8"];
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
    NSURL* videoURL = [NSURL URLWithString:@"http://qthttp.apple.com.edgesuite.net/1010qwoeiuryfg/sl.m3u8"];
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

- (void)setupAVPlayerViewController:(AVPlayer *)player {
    _avplayer = player;
    _avplayerController.player = _avplayer;
    
    // TODO: Add your property key!
    NSString *envKey = [NSProcessInfo.processInfo.environment objectForKey:@"ENV_KEY"];
    if(envKey == nil) {
        envKey = @"YOUR_ENV_KEY_HERE";
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
    MUXSDKCustomerData *customerData = [[MUXSDKCustomerData alloc] initWithCustomerPlayerData:playerData
                                                                                    videoData:videoData
                                                                                     viewData:viewData
                                                                                   customData:customData
                                                                                   viewerData:viewerData];
    _playerBinding = [MUXSDKStats monitorAVPlayerViewController:_avplayerController withPlayerName:DEMO_PLAYER_NAME customerData:customerData];
    _imaListener = [[MuxImaListener alloc] initWithPlayerBinding:_playerBinding];
    [_avplayer play];
    [self addChildViewController:_avplayerController];
    _avplayerController.view.frame = self.view.bounds;
    [self.view insertSubview:_avplayerController.view atIndex:0];
    [_avplayerController didMoveToParentViewController:self];
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
    NSURL* videoURL = [NSURL URLWithString:@"http://qthttp.apple.com.edgesuite.net/1010qwoeiuryfg/sl.m3u8"];
    AVPlayerItem *keynote = [AVPlayerItem playerItemWithURL:videoURL];
    [_avplayer replaceCurrentItemWithPlayerItem:keynote];
    [_avplayer play];
}

- (void)changeProgram:(NSTimer *)timer {
    MUXSDKCustomerData *customerData = (MUXSDKCustomerData *) timer.userInfo;
    [MUXSDKStats programChangeForPlayer:DEMO_PLAYER_NAME withCustomerData:customerData];
}

- (void)playerItemDidReachEnd:(NSNotification *)notification {
    MUXSDKCustomerVideoData *videoData = [MUXSDKCustomerVideoData new];
    videoData.videoTitle = @"Apple Keynote";
    videoData.videoId = @"applekeynote2010";
    [MUXSDKStats videoChangeForPlayer:DEMO_PLAYER_NAME withVideoData:videoData];
}

- (void) updateCustomData:(NSTimer *)timer {
    MUXSDKCustomData *customData = [[MUXSDKCustomData alloc] init];
    [customData setCustomData2:@"update-custom-dimension-2"];
    MUXSDKCustomerData *customerData = [[MUXSDKCustomerData alloc] init];
    customerData.customData = customData;
    [MUXSDKStats setCustomerData:customerData forPlayer:DEMO_PLAYER_NAME];
}

- (NSString *) testScenario {
    return [NSProcessInfo.processInfo.environment objectForKey:@"TEST_SCENARIO"];
}

@end
