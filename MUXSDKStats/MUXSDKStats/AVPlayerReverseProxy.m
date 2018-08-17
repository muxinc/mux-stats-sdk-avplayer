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
        _isHttps = false;
    }
    return self;
}

- (NSURL *)startPlayerProxyWithReverseProxyHost:(nonnull NSString *)originStreamUrl notifyObj:(id)obj withCallback:(SEL)callback {
    NSURL* videoURL = [NSURL URLWithString: originStreamUrl];
    NSString *externalDomain = [videoURL host];
    _isHttps = [[videoURL scheme] isEqualToString:@"https"];

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
                                      GCDWebServerResponse *response = [weakSelf sendRequest:request toHost:externalDomain withHeaders:weakHeaders];
                                      return response;
                                  }];
        
        // Start server on port 8080
        [_webServer startWithPort:PortNumber bonjourName:nil];
    });

    _proxyLocalHost = [NSString stringWithFormat:@"%@:%d", GCDWebServerGetPrimaryIPAddress(NO), PortNumber];
    NSString *customUrl = [originStreamUrl stringByReplacingOccurrencesOfString:externalDomain withString: _proxyLocalHost];
    if (_isHttps)
        customUrl = [customUrl stringByReplacingOccurrencesOfString:@"https" withString: @"http"];
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

- (GCDWebServerResponse *)sendRequest:(GCDWebServerRequest *)request toHost:(NSString *)reverseProxyHost withHeaders:(NSDictionary *)headers {
    NSError *error = nil;
    NSHTTPURLResponse *urlResponse = nil;
    
    // ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    // Replace the local url with the reverse host to recreate the original url
    // ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    NSString *customUrl = [request.URL.absoluteString stringByReplacingOccurrencesOfString:_proxyLocalHost withString:reverseProxyHost];
    if (_isHttps)
        customUrl = [customUrl stringByReplacingOccurrencesOfString:@"http" withString: @"https"];
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
        NSNumber *length = [responseHeaders objectForKey:@"Content-Length"];
        loadData.requestBytesLoaded = length;
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
