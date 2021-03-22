#import "ViewController.h"

static NSString *DEMO_PLAYER_NAME = @"demoplayer";

@interface ViewController ()

@end

@implementation ViewController

//NSString *const kAdTagURLString = @"https://pubads.g.doubleclick.net/gampad/ads?sz=640x480&"
//@"iu=/124319096/external/ad_rule_samples&ciu_szs=300x250&ad_rule=1&impl=s&gdfp_req=1&env=vp&"
//@"output=vmap&unviewed_position_start=1&cust_params=deployment%3Ddevsite%26sample_ar%3D"
//@"premidpostlongpod&cmsid=496&vid=short_tencue&correlator=[TIMESTAMP]";

NSString *const kAdTagURLString = @"https://pubads.g.doubleclick.net/gampad/ads?sz=640x480&iu=/124319096/external/ad_rule_samples&ciu_szs=300x250&ad_rule=1&impl=s&gdfp_req=1&env=vp&output=vmap&unviewed_position_start=1&cust_params=deployment%3Ddevsite%26sample_ar%3Dpremidpostpod&cmsid=496&vid=short_onecue&correlator=";
NSString *const kAdTagURLStringPostRoll = @"https://pubads.g.doubleclick.net/gampad/ads?sz=640x480&iu=/124319096/external/ad_rule_samples&ciu_szs=300x250&ad_rule=1&impl=s&gdfp_req=1&env=vp&output=vmap&unviewed_position_start=1&cust_params=deployment%3Ddevsite%26sample_ar%3Dpostonly&cmsid=496&vid=short_onecue&correlator=";

- (void)viewDidLoad {
    [super viewDidLoad];
    _avplayerController = [AVPlayerViewController new];
//    AVPlayer *player = [self testAvPlayer];
    AVPlayer *player = [self testImaSDK];
    [self setupAVPlayerViewController: player];
}

- (void) viewDidAppear:(BOOL)animated {
    [self requestAds];
}

- (void)setupAVPlayerViewController:(AVPlayer *)player {
    _avplayer = player;
    _avplayerController.player = _avplayer;
    
//    // TODO: Add your property key!
    MUXSDKCustomerPlayerData *playerData = [[MUXSDKCustomerPlayerData alloc] initWithPropertyKey:@"YOUR_ENV_KEY_HERE"];
    MUXSDKCustomerVideoData *videoData = [MUXSDKCustomerVideoData new];
    videoData.videoTitle = @"Big Buck Bunny";
    videoData.videoId = @"bigbuckbunny";
    videoData.videoSeries = @"animation";
    _playerBinding = [MUXSDKStats monitorAVPlayerViewController:_avplayerController
                                withPlayerName:DEMO_PLAYER_NAME
                                    playerData:playerData
                                     videoData:videoData];
    _imaListener = [[MuxImaListener alloc] initWithPlayerBinding:_playerBinding];
    [_avplayer play];

    
    _avplayerController.view.frame = self.view.bounds;
    _avplayerController.showsPlaybackControls = YES;
    [self addChildViewController:_avplayerController];
    [self.view insertSubview:_avplayerController.view atIndex:0];
    [_avplayerController didMoveToParentViewController:self];
}

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

- (void) requestAds {
    IMAAdDisplayContainer *adDisplayContainer = [[IMAAdDisplayContainer alloc] initWithAdContainer:self.view viewController:self];
    IMAAdsRequest *request = [[IMAAdsRequest alloc] initWithAdTagUrl:kAdTagURLStringPostRoll
                                                  adDisplayContainer:adDisplayContainer
                                                     contentPlayhead:_contentPlayhead
                                                         userContext:nil];
    [_adsLoader requestAdsWithRequest:request];
}

- (AVPlayer *)testAvPlayer {
    NSURL* videoURL = [NSURL URLWithString:@"https://bitdash-a.akamaihd.net/content/sintel/hls/playlist.m3u8"];
    AVPlayer *player = [AVPlayer playerWithURL:videoURL];
    _videoChangeTimer = [NSTimer scheduledTimerWithTimeInterval:20.0
                                                         target:self
                                                       selector:@selector(changeVideo:)
                                                       userInfo:nil
                                                        repeats:NO];
    return player;
}

- (void)contentDidFinishPlaying:(NSNotification *)notification {
    if (notification.object == _avplayer.currentItem) {
        [_adsLoader contentComplete];
    }
}

- (void)dealloc {
  [NSNotificationCenter.defaultCenter removeObserver:self];
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

#pragma mark - IMAAdsLoaderDelegate

- (void)adsLoader:(IMAAdsLoader *)loader adsLoadedWithData:(IMAAdsLoadedData *)adsLoadedData {
  // Initialize and listen to the ads manager loaded for this request.
    _adsManager = adsLoadedData.adsManager;
    _adsManager.delegate = self;
    IMAAdsRenderingSettings *adsRenderingSettings = [[IMAAdsRenderingSettings alloc] init];
    adsRenderingSettings.webOpenerPresentingController = self;
    [_adsManager initializeWithAdsRenderingSettings:adsRenderingSettings];
}

- (void)adsLoader:(IMAAdsLoader *)loader failedWithErrorData:(IMAAdLoadingErrorData *)adErrorData {
  // Fall back to playing content.
  NSLog(@"Error loading ads: %@", adErrorData.adError.message);
  [_avplayerController.player play];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
