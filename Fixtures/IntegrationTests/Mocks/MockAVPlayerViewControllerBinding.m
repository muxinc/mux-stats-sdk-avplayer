//
//  MockAVPlayerViewControllerBinding.m
//  IntegrationTests
//
//  Created by Fabrizio Persichetti on 26/5/25.
//

#import "MockAVPlayerViewControllerBinding.h"

@implementation MockAVPlayerViewControllerBinding

- (CGRect)getViewBounds {
    CGRect rect = [super getViewBounds];
    if (CGRectEqualToRect(rect, CGRectZero)) {
        self.didReturnZeroRect = YES;
    }
    return rect;
}

@end
