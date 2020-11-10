#import "ViewController.h"

@import MUXSDKStats;

static NSString *DEMO_PLAYER_NAME = @"demoplayer";

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _avplayerController = [AVPlayerViewController new];
//    AVPlayer *player = [self testImaSDK];
//    AVPlayer *player = [self testAVQueuePlayer];
    AVPlayer *player = [self testAVPlayer];
    [self setupAVPlayerViewController: player];
}

- (AVPlayer *)testImaSDK {
    NSURL* videoURL = [NSURL URLWithString:@"https://bitdash-a.akamaihd.net/content/sintel/hls/playlist.m3u8"];
    AVPlayer *player = [AVPlayer playerWithURL:videoURL];
    _contentPlayhead = [[IMAAVPlayerContentPlayhead alloc] initWithAVPlayer:player];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(contentDidFinishPlaying:)
                                                 name:AVPlayerItemDidPlayToEndTimeNotification
                                               object:player.currentItem];
    _adsLoader = [[IMAAdsLoader alloc] initWithSettings:nil];
    _adsLoader.delegate = self;

    IMAAdDisplayContainer *adDisplayContainer = [[IMAAdDisplayContainer alloc] initWithAdContainer:_avplayerController.view companionSlots:nil];
    IMAAdsRequest *request = [[IMAAdsRequest alloc] initWithAdTagUrl:@"https://pubads.g.doubleclick.net/gampad/ads?sz=640x480&iu=/124319096/external/ad_rule_samples&ciu_szs=300x250&ad_rule=1&impl=s&gdfp_req=1&env=vp&output=vmap&unviewed_position_start=1&cust_params=deployment%3Ddevsite%26sample_ar%3Dpremidpostpod&cmsid=496&vid=short_onecue&correlator="
                                                  adDisplayContainer:adDisplayContainer
                                                     contentPlayhead:_contentPlayhead
                                                         userContext:nil];
    [_adsLoader requestAdsWithRequest:request];
    return player;
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
    adsRenderingSettings.webOpenerPresentingController = self;
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
//    if (_imaListener != nil) {
//        [_imaListener dispatchEvent: event];
//    }
}

- (void)adsManager:(IMAAdsManager *)adsManager didReceiveAdError:(IMAAdError *)error {
    [_avplayer play];
//    if (_imaListener != nil) {
//        [_imaListener dispatchError: error.message];
//    }
}

- (void)adsManagerDidRequestContentPause:(IMAAdsManager *)adsManager {
    [_avplayer pause];
//    [_imaListener onContentPauseOrResume:true];
}

- (void)adsManagerDidRequestContentResume:(IMAAdsManager *)adsManager {
    [_avplayer play];
//    [_imaListener onContentPauseOrResume:false];
}

- (AVPlayer *)testAVQueuePlayer {
    AVPlayerItem *item1 = [AVPlayerItem playerItemWithURL:[NSURL URLWithString:@"https://bitdash-a.akamaihd.net/content/sintel/hls/playlist.m3u8"]];
    AVPlayerItem *item2 = [AVPlayerItem playerItemWithURL:[NSURL URLWithString:@"http://qthttp.apple.com.edgesuite.net/1010qwoeiuryfg/sl.m3u8"]];
    AVQueuePlayer *player = [[AVQueuePlayer alloc] initWithItems:@[item1, item2]];
    return player;
}

- (AVPlayer *)testAVPlayer {
    NSURL* videoURL = [NSURL URLWithString:@"http://qthttp.apple.com.edgesuite.net/1010qwoeiuryfg/sl.m3u8"];
    AVPlayer *player = [AVPlayer playerWithURL:videoURL];
    
    // After 20 seconds, we'll change the video.
    _videoChangeTimer = [NSTimer scheduledTimerWithTimeInterval:20.0
                                                         target:self
                                                       selector:@selector(changeVideo:)
                                                       userInfo:nil
                                                        repeats:NO];

//    // After 20 seconds, we'll change the program
//    _videoChangeTimer = [NSTimer scheduledTimerWithTimeInterval:20.0
//                                                         target:self
//                                                       selector:@selector(changeProgram:)
//                                                       userInfo:nil
//                                                        repeats:NO];
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
    MUXSDKCustomerPlayerData *playerData = [[MUXSDKCustomerPlayerData alloc] initWithPropertyKey:envKey];
    MUXSDKCustomerVideoData *videoData = [MUXSDKCustomerVideoData new];
    videoData.videoTitle = @"Big Buck Bunny";
    videoData.videoId = @"bigbuckbunny";
    videoData.videoSeries = @"animation";
    MUXSDKCustomerViewData *viewData= [[MUXSDKCustomerViewData alloc] init];
    viewData.viewSessionId = @"some session id";
    _playerBinding = [MUXSDKStats monitorAVPlayerViewController:_avplayerController
                                                 withPlayerName:DEMO_PLAYER_NAME
                                                     playerData:playerData
                                                      videoData:videoData
                                                       viewData: viewData];
//    _imaListener = [[MuxImaListener alloc] initWithPlayerBinding:_playerBinding];
    [_avplayer play];

    [self addChildViewController:_avplayerController];
    [self.view addSubview:_avplayerController.view];
    _avplayerController.view.frame = self.view.frame;
}

- (void)changeVideo:(NSTimer *)timer {
    MUXSDKCustomerVideoData *videoData = [MUXSDKCustomerVideoData new];
    videoData.videoTitle = @"Apple Keynote";
    videoData.videoId = @"applekeynote2010";
    [MUXSDKStats videoChangeForPlayer:DEMO_PLAYER_NAME
                        withVideoData:videoData];
    NSURL* videoURL = [NSURL URLWithString:@"http://qthttp.apple.com.edgesuite.net/1010qwoeiuryfg/sl.m3u8"];
    AVPlayerItem *keynote = [AVPlayerItem playerItemWithURL:videoURL];
    [_avplayer replaceCurrentItemWithPlayerItem:keynote];
    [_avplayer play];
}

- (void)changeProgram:(NSTimer *)timer {
    MUXSDKCustomerVideoData *videoData = [MUXSDKCustomerVideoData new];
    videoData.videoTitle = @"Apple Keynote";
    videoData.videoId = @"applekeynote2010";
    [MUXSDKStats programChangeForPlayer:DEMO_PLAYER_NAME
                        withVideoData:videoData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
