//
//  MockAVPlayerViewControllerBinding.h
//  IntegrationTests
//
//  Created by Fabrizio Persichetti on 26/5/25.
//

#import <MUXSDKStats/MUXSDKPlayerBinding.h>

@interface MockAVPlayerViewControllerBinding : MUXSDKAVPlayerViewControllerBinding

@property (nonatomic, assign) BOOL didReturnNil;

@end
