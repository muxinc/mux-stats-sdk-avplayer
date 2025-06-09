//
//  MockAVPlayerViewControllerBinding.m
//  IntegrationTests
//
//  Created by Fabrizio Persichetti on 26/5/25.
//

#import "MockAVPlayerViewControllerBinding.h"

@implementation MockAVPlayerViewControllerBinding

- (nullable NSValue *)getViewBounds {
    NSValue *viewBoundsValue = [super getViewBounds];
    if(viewBoundsValue == nil){
        self.didReturnNil = YES;
        return nil;
    }
    
    return viewBoundsValue;
}

@end
