#import <UIKit/UIKit.h>

@import AVKit;
@import AVFoundation;
@import GoogleInteractiveMediaAds;

@interface ViewController : UIViewController <IMAAdsLoaderDelegate, IMAAdsManagerDelegate> {
@private
    AVPlayer *_avplayer;
    AVPlayerViewController *_avplayerController;
    NSTimer *_videoChangeTimer;
    IMAAdsLoader *_adsLoader;
    IMAAdsManager *_adsManager;
    IMAAVPlayerContentPlayhead *_contentPlayhead;
}

@end

