#import <UIKit/UIKit.h>

@import AVKit;
@import AVFoundation;
@import MUXSDKStats;

@interface ViewController : UIViewController

@property (nonatomic) AVPlayer *player;
@property (nonatomic) AVPlayerViewController *playerViewController;

@property (nonatomic) NSTimer *timer;
@property (nonatomic) MUXSDKPlayerBinding *playerBinding;

@end

