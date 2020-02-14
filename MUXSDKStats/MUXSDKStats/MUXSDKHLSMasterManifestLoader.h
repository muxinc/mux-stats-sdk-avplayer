//
//  MUXSDKHLSMasterManifestLoader.h
//  MUXSDKStats
//
//  Created by Nidhi Kulkarni on 2/13/20.
//  Copyright © 2020 Mux, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
typedef void(^MUXSDKHLSMasterManifestLoadingCompletion)(NSArray*, NSError *);

@protocol MUXSDKHLSMasterManifestLoading
- (NSURLSessionTask *) masterPlaylistFromSource:(NSURL *) source completion:(MUXSDKHLSMasterManifestLoadingCompletion) onComplete;
- (NSNumber *) advertisedFrameRateFromPlaylist:(NSArray *) masterPlaylist forBandwidth:(NSNumber *) bandwidth;
@end
@interface MUXSDKHLSMasterManifestLoader : NSObject<MUXSDKHLSMasterManifestLoading>
- (NSArray *) parseMasterPlaylistFromData:(NSData *) data;
@end
