//
//  MUXSDKHLSMasterManifestLoader.m
//  MUXSDKStats
//
//  Created by Nidhi Kulkarni on 2/13/20.
//  Copyright © 2020 Mux, Inc. All rights reserved.
//

#import "MUXSDKHLSMasterManifestLoader.h"
#import "NSNumber+MUXSDK.h"

@interface MUXSDKHLSMasterManifestLoader()
@property (nonatomic, strong) NSNumberFormatter *f;
@end
@implementation MUXSDKHLSMasterManifestLoader

static NSString *bandwidthPattern = @"^#EXT-X-STREAM-INF:.*(?<!AVERAGE-)BANDWIDTH=(\\d+).*";
static NSString *frameRatePattern = @"^#EXT-X-STREAM-INF:.*FRAME-RATE=(\\d+(?:\\.\\d+)?).*";
static NSString *streamInfoPattern = @"#EXT-X-STREAM-INF";
static NSString *BANDWIDTH = @"BANDWIDTH";
static NSString *FRAMERATE = @"FRAME-RATE";

- (id) init {
    self = [super init];
    if (self) {
        self.f = [[NSNumberFormatter alloc] init];
        self.f.numberStyle = NSNumberFormatterDecimalStyle;
    }
    return self;
}

-(NSURLSessionTask *) masterPlaylistFromSource:(NSURL *) source completion:(MUXSDKHLSMasterManifestLoadingCompletion) onComplete {
    if (!onComplete) {
        return nil;
    }
    
    NSURLSessionTask *task = [[NSURLSession sharedSession] dataTaskWithURL:source completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        
        if (error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                onComplete(nil, error);
            });
            return;
        }
        
        NSArray *result =[self parseMasterPlaylistFromData:data];
        if (!result) {
            dispatch_async(dispatch_get_main_queue(), ^{
                onComplete(nil, nil);
            });
            return;
        }
        
        if (onComplete) {
            dispatch_async(dispatch_get_main_queue(), ^{
                onComplete(result, nil);
            });
        }
    }];
    
    [task resume];
    return task;
}

- (NSNumber *) advertisedFrameRateFromPlaylist:(NSArray *) masterPlaylist forBandwidth:(NSNumber *) bandwidth {
    if (!masterPlaylist) {
        return nil;
    }
    NSDictionary *info = [self renditionInfoFromPlaylist:masterPlaylist forBandwidth:bandwidth];
    return [info valueForKey:FRAMERATE];
}

- (NSArray *) parseMasterPlaylistFromData:(NSData *) data {
    NSString *manifest = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    if (!manifest) {
        return nil;
    }
    return [self parseMasterPlaylist:manifest];
}

# pragma mark Private Methods

- (NSArray *) parseMasterPlaylist:(NSString *) manifest {
    NSArray *lines = [manifest componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    NSMutableArray *result = [[NSMutableArray alloc] init];
    for (NSString *line in lines) {
        if ([line hasPrefix:streamInfoPattern]) {
            NSNumber *bandwidth = [self parseNumberFromString:line withRegex:[self bandwidthRegex]];
            NSNumber * frameRate = [self parseNumberFromString:line withRegex:[self frameRegex]];
            NSMutableDictionary *renditionInfo = [[NSMutableDictionary alloc] init];
            if (bandwidth) {
                [renditionInfo setValue:bandwidth forKey:BANDWIDTH];
            }
            if (frameRate) {
                [renditionInfo setValue:frameRate forKey:FRAMERATE];
            }
            [result addObject:renditionInfo];
        }
    }
    return result;
}

- (NSRegularExpression *) bandwidthRegex {
    return [NSRegularExpression regularExpressionWithPattern:bandwidthPattern options:0 error:nil];
}

- (NSRegularExpression *) frameRegex {
    return [NSRegularExpression regularExpressionWithPattern:frameRatePattern options:0 error:nil];
}

- (NSNumber *) parseNumberFromString:(NSString *) string withRegex:(NSRegularExpression *) regex {
    NSTextCheckingResult *match = [regex firstMatchInString:string options:0 range: NSMakeRange(0, string.length)];
    NSString * substring = [string substringWithRange:[match rangeAtIndex:1]];
    NSNumber * result = [self.f numberFromString:substring];
    return result;
}

- (NSDictionary *) renditionInfoFromPlaylist:(NSArray *) masterPlaylist forBandwidth:(NSNumber *) bandwidth {
    if (!masterPlaylist) {
        return nil;
    }
    for (NSDictionary *renditionInfo in masterPlaylist) {
        NSNumber *renditionBandwidth = [renditionInfo valueForKey:BANDWIDTH];
        if([bandwidth doubleValueIsEqual:renditionBandwidth]) {
            return renditionInfo;
        }
    }
    return nil;
}

@end
