#import <MUXSDKStats/MUXSDKPlayerBinding.h>

NS_ASSUME_NONNULL_BEGIN

@interface MUXSDKPlayerBinding (MUXSDKViewState)

@property (readonly, nonatomic) MUXSDKPlayerState state;

- (void)viewDidInitialize;

@end

NS_ASSUME_NONNULL_END
