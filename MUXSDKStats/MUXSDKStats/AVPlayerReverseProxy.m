//
//  AVPlayerProxy.m
//  AVPlayerHTTPHeaders
//
//  Created by Kevin Hunt on 2017-01-16.
//  Copyright © 2017 Prophet Studios. All rights reserved.
//

#import "AVPlayerReverseProxy.h"
#import "GCDWebServer.h"
#import "GCDWebServerDataResponse.h"
#import "GCDWebServerFunctions.h"

@import MuxCore;

static const int PortNumber = 8080;

NSString *const AVPlayerReverseProxyDidReceiveHeadersNotification         = @"AVPlayerReverseProxyDidReceiveHeadersNotification";

NSString *const AVPlayerReverseProxyNotificationRequestURLKey             = @"AVPlayerReverseProxyNotificationRequestURLKey";
NSString *const AVPlayerReverseProxyNotificationHeadersKey                = @"AVPlayerReverseProxyNotificationHeadersKey";
NSString *const AVPlayerReverseProxyNotificationMetricsKey                = @"AVPlayerReverseProxyNotificationMetricsKey";

@implementation AVPlayerReverseProxy {
    NSDictionary *_httpHeaders;
    GCDWebServer *_webServer;
}

- (instancetype)init {
    if (self = [super init]) {
        _httpHeaders = [[NSDictionary alloc] init];
        _proxyHosts = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (NSString *)replaceWithLocalProxyHost:(NSString *)streamUrl {
    NSString *customUrl = streamUrl;
    NSURL *videoURL = [NSURL URLWithString: streamUrl];
    if (videoURL != nil) {
        NSString *externalDomain = [videoURL host];
        NSNumber *port =[videoURL port];
        if (externalDomain == nil) {
            NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"\\/\\/.*\\/" options:NSRegularExpressionCaseInsensitive error:NULL];
            NSTextCheckingResult *match = [regex firstMatchInString:streamUrl
                                                            options:0
                                                              range:NSMakeRange(0, [streamUrl length])];
            if (match) {
                NSRange range = [match range];
                range = NSMakeRange(range.location + 2, range.length - 3);
                externalDomain = [streamUrl substringWithRange: range];
            }
        } else if (port != nil) {
            externalDomain = [NSString stringWithFormat:@"%@:%ld", externalDomain, [port longValue]];
        }
        bool isHttps = [[videoURL scheme] isEqualToString:@"https"];
        if (externalDomain != nil) {
            NSNumber *strHash = [NSNumber numberWithUnsignedInteger:[externalDomain hash]];
            if (![_proxyHosts objectForKey: strHash]) {
                [_proxyHosts setObject: externalDomain forKey:strHash];
            }
            NSString *proxyLocalHost = [NSString stringWithFormat:@"%@:%d/[%d=%@]", GCDWebServerGetPrimaryIPAddress(NO), PortNumber, isHttps, [strHash stringValue]];
            customUrl = [streamUrl stringByReplacingOccurrencesOfString:externalDomain withString: proxyLocalHost];
            if (isHttps)
                customUrl = [customUrl stringByReplacingOccurrencesOfString:@"https" withString: @"http"];
        }
    }
    return customUrl;
}

- (NSString *)replaceWithExternalHost:(NSString *)localProxyUrl {
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"%5B.*%5D" options:NSRegularExpressionCaseInsensitive error:NULL];
    NSTextCheckingResult *match = [regex firstMatchInString:localProxyUrl
                                                    options:0
                                                      range:NSMakeRange(0, [localProxyUrl length])];
    NSString *externalUrl = nil;
    if (match) {
        NSRange range = [match range];
        range = NSMakeRange(range.location + 3, range.length - 6);
        externalUrl = [localProxyUrl substringWithRange: range];
        NSArray *components = [externalUrl componentsSeparatedByString:@"="];
        if ([components count] == 2) {
            bool isHttps = [[components objectAtIndex:0] integerValue] > 0;
            NSNumber *strHash = [NSNumber numberWithUnsignedInteger:[[components objectAtIndex:1] integerValue]];
            NSString *externHost = [_proxyHosts objectForKey: strHash];
            if (externHost) {
                range = [match range];
                range = NSMakeRange(range.location, range.length + 1);
                externalUrl = [localProxyUrl stringByReplacingCharactersInRange:range withString:@""];
                NSString *proxyLocalHost = [NSString stringWithFormat:@"%@:%d", GCDWebServerGetPrimaryIPAddress(NO), PortNumber];
                externalUrl = [externalUrl stringByReplacingOccurrencesOfString:proxyLocalHost withString:externHost];
                if (isHttps)
                    externalUrl = [externalUrl stringByReplacingOccurrencesOfString:@"http" withString: @"https"];
            }
        }
    }
    return externalUrl;
}

- (NSData *)parseM3u8:(NSData *)file {
    NSString* content = [[NSString alloc] initWithData:file encoding:NSUTF8StringEncoding];
    NSMutableArray *lines = [NSMutableArray array];
    NSScanner *scanner = [NSScanner scannerWithString:content];
    while (![scanner isAtEnd]) {
        NSString *line = nil;
        [scanner scanUpToCharactersFromSet:[NSCharacterSet newlineCharacterSet] intoString:&line];
        if (line && ![line hasPrefix:@"#EXT"]) {
            line = [self replaceWithLocalProxyHost: line];
        }
        [lines addObject:line];
    }
    NSMutableString *newM3u8 = [[NSMutableString alloc] init];
    for (NSString *line in lines) {
        [newM3u8 appendFormat:@"%@\n", line];
    }
    NSData* data = [newM3u8 dataUsingEncoding:NSUTF8StringEncoding];
    return data;
}

- (NSURL *)startPlayerProxyWithReverseProxyHost:(nonnull NSString *)originStreamUrl notifyObj:(id)obj withCallback:(SEL)callback {
    [[NSNotificationCenter defaultCenter] addObserver:obj selector:callback name:AVPlayerReverseProxyDidReceiveHeadersNotification object:nil];

    dispatch_async(dispatch_get_main_queue(), ^{
        _webServer = [[GCDWebServer alloc] init];

        __weak NSDictionary *weakHeaders = _httpHeaders;
        __weak typeof(self) weakSelf = self;
        // Add a handler to respond to GET requests on any local URL
        [_webServer addDefaultHandlerForMethod:@"GET"
                                  requestClass:[GCDWebServerRequest class]
                                  processBlock:^GCDWebServerResponse *(GCDWebServerRequest* request) {
                                      
                                      // Process the request by sending it using the reverse proxy URL
                                      GCDWebServerResponse *response = [weakSelf sendRequest:request withHeaders:weakHeaders];
                                      return response;
                                  }];
        
        // Start server on port 8080
        [_webServer startWithPort:PortNumber bonjourName:nil];
    });

    NSString *customUrl = [self replaceWithLocalProxyHost:originStreamUrl];
    return [NSURL URLWithString: customUrl];
}

- (void)stopPlayerProxy {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerReverseProxyDidReceiveHeadersNotification object:nil];
    dispatch_async(dispatch_get_main_queue(), ^{
        [_webServer stop];
    });
}

- (void)addHttpHeaders:(NSDictionary*)httpHeaders {
    if (httpHeaders && [httpHeaders count] > 0) {
        NSMutableDictionary *mergeDict = [NSMutableDictionary dictionaryWithDictionary:_httpHeaders];
        [mergeDict addEntriesFromDictionary:httpHeaders];
        _httpHeaders = [NSDictionary dictionaryWithDictionary:mergeDict];
    }
}

- (void)removeHttpHeaders:(NSDictionary*)httpHeaders {
    if (httpHeaders && [httpHeaders count] > 0) {
        NSMutableDictionary *removeDict = [NSMutableDictionary dictionaryWithDictionary:_httpHeaders];
        [removeDict removeObjectsForKeys:[httpHeaders allKeys]];
        _httpHeaders = [NSDictionary dictionaryWithDictionary:removeDict];
    }
}

- (GCDWebServerResponse *)sendRequest:(GCDWebServerRequest *)request withHeaders:(NSDictionary *)headers {
    NSError *error = nil;
    NSHTTPURLResponse *urlResponse = nil;
    
    // ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    // Replace the local url with the reverse host to recreate the original url
    // ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    NSString *customUrl = [self replaceWithExternalHost:request.URL.absoluteString];
    NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:customUrl]];
    NSUInteger requestStart = round([[NSDate date] timeIntervalSince1970] * 1000);
    // Set the additional HTTP headers in the new request
    for (NSString *key in [headers allKeys]) {
        NSString *value = [headers valueForKey:key];
        [urlRequest setValue:value forHTTPHeaderField:key];
    }
    
    // Synchronously make the request
    NSData *responseData = [NSURLConnection sendSynchronousRequest:urlRequest returningResponse:&urlResponse error:&error];
    NSUInteger responseEnd = round([[NSDate date] timeIntervalSince1970] * 1000);
    
    // Capture the header info
    NSDictionary *responseHeaders = urlResponse.allHeaderFields;
    NSString *contentType = [responseHeaders valueForKey:@"Content-Type"];
    
    // Post notification containing headers an corresponding URL
    MUXSDKBandwidthMetricData *loadData = [[MUXSDKBandwidthMetricData alloc] init];
    if ([customUrl hasSuffix:@".m3u8"]){
        responseData = [self parseM3u8: responseData];
        loadData.requestEventType = @"hlsManifestLoaded";
        loadData.requestType = @"manifest";
    } else {
        loadData.requestEventType = @"hlsFragBuffered";
        loadData.requestType = @"media";
    }
    loadData.requestStart = [NSNumber numberWithLong: requestStart];
    loadData.requestResponseStart = [NSNumber numberWithLong: requestStart];
    loadData.requestResponseEnd = [NSNumber numberWithLong: responseEnd];
    if (responseHeaders != nil && [responseHeaders objectForKey:@"Content-Length"] != nil) {
        NSNumber *length = [NSNumber numberWithLong:[[responseHeaders objectForKey:@"Content-Length"] longLongValue]];
        loadData.requestBytesLoaded =  length;
    }
    loadData.requestUrl = customUrl;
    loadData.requestResponseHeaders = responseHeaders;
    loadData.requestCurrentLevel = nil;
    loadData.requestMediaStartTime = nil;
    loadData.requestMediaDuration = nil;
    loadData.requestVideoWidth = nil;
    loadData.requestVideoHeight = nil;
    loadData.requestRenditionLists = nil;
    NSDictionary *userInfoDict = [NSDictionary dictionaryWithObjectsAndKeys:
                                  customUrl, AVPlayerReverseProxyNotificationRequestURLKey,
                                  responseHeaders,  AVPlayerReverseProxyNotificationHeadersKey,
                                  loadData, AVPlayerReverseProxyNotificationMetricsKey,
                                  nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:AVPlayerReverseProxyDidReceiveHeadersNotification
                                                        object:nil
                                                      userInfo:userInfoDict];
    
    // Create the response to return back to the player
    GCDWebServerDataResponse *response = [GCDWebServerDataResponse responseWithData:responseData contentType:contentType];
    
    return response;
}

@end
