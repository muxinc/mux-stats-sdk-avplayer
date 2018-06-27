#ifndef MUXSDKTrackableEvent_h
#define MUXSDKTrackableEvent_h

#import "MUXSDKBaseEvent.h"
#import "MUXSDKCustomerVideoData.h"
#import "MUXSDKCustomerPlayerData.h"
#import "MUXSDKEnvironmentData.h"
#import "MUXSDKEventTyping.h"
#import "MUXSDKPlayerData.h"
#import "MUXSDKViewData.h"
#import "MUXSDKViewerData.h"
#import "MUXSDKVideoData.h"
#import "MUXSDKQueryData.h"

extern NSString *const MUXSDKTrackableEventType;

@interface MUXSDKTrackableEvent : MUXSDKBaseEvent <MUXSDKEventTyping> {
    @private
    MUXSDKQueryData* query;
}

- (id)initWithType:(NSString *)type;
- (void)updateAll;
- (NSDictionary *)getQuery;
- (void)setQuery: (NSDictionary *) query;

@property (nonatomic, copy) NSString *eventType;
@property (nonatomic, retain) MUXSDKViewData *viewData;
@property (nonatomic, retain) MUXSDKVideoData *videoData;
@property (nonatomic, retain) MUXSDKCustomerVideoData *customerVideoData;
@property (nonatomic, retain) MUXSDKPlayerData *playerData;
@property (nonatomic, retain) MUXSDKCustomerPlayerData *customerPlayerData;
@property (nonatomic, retain) MUXSDKEnvironmentData *environmentData;
@property (nonatomic, retain) MUXSDKViewerData *viewerData;

@end

#endif
