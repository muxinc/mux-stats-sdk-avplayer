#import <UIKit/UIKit.h>

@import AVKit;
@import AVFoundation;

@interface ViewController : UIViewController {
    @private
    AVPlayer *_avplayer;
    AVPlayerViewController *_avplayerController;
    NSTimer *_videoChangeTimer;
}

@end

