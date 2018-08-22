#import "ViewController.h"

@import MuxCore;
@import MUXSDKStats;

static NSString *DEMO_PLAYER_NAME = @"demoplayer";

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    AVPlayer *player = [self testAVQueuePlayer]; //[self testAVPlayer];
    [self testAVPlayerViewController: player];
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

- (void)testAVPlayerViewController:(AVPlayer *)player {
    _avplayer = player;
    _avplayerController = [AVPlayerViewController new];
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
