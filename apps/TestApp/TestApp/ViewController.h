#import <UIKit/UIKit.h>

@import AVKit;
@import AVFoundation;
@import GoogleInteractiveMediaAds;

@class MuxImaListener;
@class MUXSDKPlayerBinding;

@interface ViewController : UIViewController <IMAAdsLoaderDelegate, IMAAdsManagerDelegate> {
    @private
    AVPlayer *_avplayer;
    AVPlayerViewController *_avplayerController;
    NSTimer *_videoChangeTimer;

    // IMA SDK variables
    IMAAdsLoader *_adsLoader;
    IMAAdsManager *_adsManager;
    IMAAVPlayerContentPlayhead *_contentPlayhead;
    MuxImaListener *_imaListener;
    MUXSDKPlayerBinding *_playerBinding;
}

@end

