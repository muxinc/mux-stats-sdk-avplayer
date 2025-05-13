#import <AVKit/AVKit.h>
#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>

#import <MUXSDKStats/MUXSDKStats.h>

@interface ViewController : UIViewController

@property (nonatomic) AVPlayer *player;
@property (nonatomic) AVPlayerViewController *playerViewController;

@property (nonatomic) NSTimer *timer;
@property (nonatomic) MUXSDKPlayerBinding *playerBinding;

@end

