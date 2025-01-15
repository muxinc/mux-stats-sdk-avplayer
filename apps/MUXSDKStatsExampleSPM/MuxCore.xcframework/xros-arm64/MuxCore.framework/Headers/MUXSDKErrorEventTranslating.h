//
//  MUXSDKErrorTranslating.h
//  MuxCore
//
//  Copyright © 2024 Mux. All rights reserved.
//

#ifndef MUXSDKErrorEventTranslating_h
#define MUXSDKErrorEventTranslating_h

#import <Foundation/Foundation.h>
#import <MuxCore/MUXSDKErrorEvent.h>

NS_ASSUME_NONNULL_BEGIN

@class MUXSDKErrorEvent;

@protocol MUXSDKErrorEventTranslating <NSObject>

- (nullable MUXSDKErrorEvent *)translateErrorEvent:(MUXSDKErrorEvent *)errorEvent;

@end

NS_ASSUME_NONNULL_END

#endif
