//
//  LocalHTTPServer.m
//  DemoApp
//
//  Created by Nidhi Kulkarni on 11/6/20.
//  Copyright © 2020 Mux, Inc. All rights reserved.
//

#import "LocalHTTPServer.h"
#import "GCDWebServer.h"
#import "GCDWebServerDataResponse.h"
#import "GCDWebServerDataRequest.h"

@interface LocalHTTPServer()

@property (nonatomic, strong) GCDWebServer* webServer;
@property (nonatomic, strong) NSMutableArray *beacons;

@end

@implementation LocalHTTPServer

- (id) init {
    self = [super init];
    if (self) {
        _webServer = [[GCDWebServer alloc] init];
        _beacons = [[NSMutableArray alloc] init];
        [self setUpPostHandler];
        [self setUpGetHandler];
        [_webServer startWithPort:8080 bonjourName:nil];
    }
    return self;
}

- (void) setUpPostHandler {
    __weak LocalHTTPServer *weakSelf = self;
    [_webServer addDefaultHandlerForMethod:@"POST"
                            requestClass:[GCDWebServerDataRequest class]
                            processBlock:^GCDWebServerResponse *(GCDWebServerDataRequest* request) {
        NSLog(@"%@", request.jsonObject);
        [weakSelf.beacons addObject:request.jsonObject];
        return [GCDWebServerDataResponse responseWithStatusCode:200];
    }];
}

- (void) setUpGetHandler {
    __weak LocalHTTPServer *weakSelf = self;
    [_webServer addDefaultHandlerForMethod:@"GET"
                            requestClass:[GCDWebServerDataRequest class]
                            processBlock:^GCDWebServerResponse *(GCDWebServerDataRequest* request) {
        NSArray *beacons = [[NSArray alloc] initWithArray:weakSelf.beacons];
        return [GCDWebServerDataResponse responseWithJSONObject:@{@"beacons": beacons}];
    }];
}

@end
