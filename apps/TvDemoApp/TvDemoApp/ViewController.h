#import <UIKit/UIKit.h>
#import <GoogleInteractiveMediaAds/GoogleInteractiveMediaAds.h>

@import AVKit;
@import AVFoundation;
@import GoogleInteractiveMediaAds;
@import MuxCore;
@import MUXSDKStats;
//@import Mux_Stats_Google_IMA;

@interface ViewController : UIViewController <IMAAdsLoaderDelegate, IMAAdsManagerDelegate> {
@private
    AVPlayer *_avplayer;
    AVPlayerViewController *_avplayerController;
    NSTimer *_videoChangeTimer;

    IMAAdsLoader *_adsLoader;
    IMAAdsManager *_adsManager;
    IMAAVPlayerContentPlayhead *_contentPlayhead;
//    MuxImaListener *_imaListener;
    MUXSDKPlayerBinding *_playerBinding;
}

@end

