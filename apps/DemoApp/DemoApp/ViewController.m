#import "ViewController.h"

@import MuxCore;
@import MUXSDKStats;

static NSString *DEMO_PLAYER_NAME = @"demoplayer";

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _avplayerController = [AVPlayerViewController new];
    AVPlayer *player = [self testImaSDK]; //[self testAVQueuePlayer]; //[self testAVPlayer];
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

- (void)adsLoader:(IMAAdsLoader *)loader adsLoadedWithData:(IMAAdsLoadedData *)adsLoadedData {
    _adsManager = adsLoadedData.adsManager;
    _adsManager.delegate = self;
    IMAAdsRenderingSettings *adsRenderingSettings = [[IMAAdsRenderingSettings alloc] init];
    adsRenderingSettings.webOpenerPresentingController = self;
    [_adsManager initializeWithAdsRenderingSettings:adsRenderingSettings];
}

- (void)adsLoader:(IMAAdsLoader *)loader failedWithErrorData:(IMAAdLoadingErrorData *)adErrorData {
    NSLog(@"Error loading ads: %@", adErrorData.adError.message);
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

- (AVPlayer *)testAVQueuePlayer {
    AVPlayerItem *item1 = [AVPlayerItem playerItemWithURL:[NSURL URLWithString:@"https://bitdash-a.akamaihd.net/content/sintel/hls/playlist.m3u8"]];
    AVPlayerItem *item2 = [AVPlayerItem playerItemWithURL:[NSURL URLWithString:@"http://184.72.239.149/vod/smil:BigBuckBunny.smil/playlist.m3u8"]];
    AVQueuePlayer *player = [[AVQueuePlayer alloc] initWithItems:@[item1, item2]];
    return player;
}

- (AVPlayer *)testAVPlayer {
    NSURL* videoURL = [NSURL URLWithString:@"http://www.streambox.fr/playlists/x36xhzz/x36xhzz.m3u8"];
    AVPlayer *player = [AVPlayer playerWithURL:videoURL];
    
    // After 20 seconds, we'll change the video.
    _videoChangeTimer = [NSTimer scheduledTimerWithTimeInterval:20.0
                                                         target:self
                                                       selector:@selector(changeVideo:)
                                                       userInfo:nil
                                                        repeats:NO];
    return player;
}

- (void)setupAVPlayerViewController:(AVPlayer *)player {
    _avplayer = player;
    _avplayerController.player = _avplayer;

    // TODO: Add your property key!
    MUXSDKCustomerPlayerData *playerData = [[MUXSDKCustomerPlayerData alloc] initWithPropertyKey:@"YOUR_ENVIRONMENT_KEY"];
    MUXSDKCustomerVideoData *videoData = [MUXSDKCustomerVideoData new];
    videoData.videoTitle = @"Big Buck Bunny";
    videoData.videoId = @"bigbuckbunny";
    videoData.videoSeries = @"animation";
    [MUXSDKStats monitorAVPlayerViewController:_avplayerController
                                withPlayerName:DEMO_PLAYER_NAME
                                    playerData:playerData
                                     videoData:videoData];
    [_avplayer play];

    [self addChildViewController:_avplayerController];
    [self.view addSubview:_avplayerController.view];
    _avplayerController.view.frame = self.view.frame;

    _imaListener = [MUXSDKStats getImaAdsListener:DEMO_PLAYER_NAME];
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

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
