#import <UIKit/UIKit.h>

@import AVKit;
@import AVFoundation;
@import GoogleInteractiveMediaAds;

@class MUXSDKImaListener;

@interface ViewController : UIViewController <IMAAdsLoaderDelegate, IMAAdsManagerDelegate> {
    @private
    AVPlayer *_avplayer;
    AVPlayerViewController *_avplayerController;
    NSTimer *_videoChangeTimer;

    // IMA SDK variables
    IMAAdsLoader *_adsLoader;
    IMAAdsManager *_adsManager;
    IMAAVPlayerContentPlayhead *_contentPlayhead;
    MUXSDKImaListener *_imaListener;
}

@end

