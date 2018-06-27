#ifndef MUXSDKPlayerData_h
#define MUXSDKPlayerData_h

#import "MUXSDKQueryData.h"
#import <Foundation/Foundation.h>

extern NSString *PLAYER_SEQUENCE_NUMBER;
extern NSString *PLAYER_PLAYHEAD_TIME;

@interface MUXSDKPlayerData : MUXSDKQueryData

@property (nullable) NSNumber *pageLoadTime;
@property (nullable) NSString *pageUrl;
@property (nullable) NSString *playerAutoplayOn;
@property (nullable) NSString *playerErrorCode;
@property (nullable) NSString *playerErrorMessage;
@property (nullable) NSNumber *playerHeight;
@property (nullable) NSString *playerInstanceId;
@property (nullable) NSString *playeriOSErrorData;
@property (nullable) NSString *playerIsFullscreen;
@property (nullable) NSNumber *playerIsPaused;
@property (nullable) NSString *playerLanguageCode;
@property (nullable) NSNumber *playerLoadTime;
@property (nullable) NSString *playerMuxPluginName;
@property (nullable) NSString *playerMuxPluginVersion;
@property (nullable) NSNumber *playerPlayheadTime;
@property (nullable) NSString *playerPreloadOn;
@property (nullable) NSNumber *playerSequenceNumber;
@property (nullable) NSString *playerSoftwareName;
@property (nullable) NSString *playerSoftwareVersion;
@property (nullable) NSNumber *playerStartupTime;
@property (nullable) NSNumber *playerViewCount;
@property (nullable) NSNumber *playerWidth;

@end

#endif
