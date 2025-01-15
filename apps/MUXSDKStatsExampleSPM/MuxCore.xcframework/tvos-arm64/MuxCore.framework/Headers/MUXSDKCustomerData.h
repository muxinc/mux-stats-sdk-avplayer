#ifndef MUXSDKCustomerData_h
#define MUXSDKCustomerData_h

#import "MUXSDKQueryData.h"
#import "MUXSDKCustomerPlayerData.h"
#import "MUXSDKCustomerVideoData.h"
#import "MUXSDKCustomerViewData.h"
#import "MUXSDKCustomData.h"
#import "MUXSDKCustomerViewerData.h"
#import <Foundation/Foundation.h>

@interface MUXSDKCustomerData : MUXSDKQueryData

@property (strong, nonatomic, nullable) MUXSDKCustomerPlayerData *customerPlayerData;
@property (strong, nonatomic, nullable) MUXSDKCustomerVideoData *customerVideoData;
@property (strong, nonatomic, nullable) MUXSDKCustomerViewData *customerViewData;
@property (strong, nonatomic, nullable) MUXSDKCustomerViewerData *customerViewerData;
@property (strong, nonatomic, nullable) MUXSDKCustomData *customData;

- (id _Nullable) initWithCustomerPlayerData:(nullable MUXSDKCustomerPlayerData *) playerData
                                  videoData:(nullable MUXSDKCustomerVideoData *) videoData
                                   viewData:(nullable MUXSDKCustomerViewData *) viewData;

- (id _Nullable) initWithCustomerPlayerData:(nullable MUXSDKCustomerPlayerData *) playerData
                                  videoData:(nullable MUXSDKCustomerVideoData *) videoData
                                   viewData:(nullable MUXSDKCustomerViewData *) viewData
                                 customData:(nullable MUXSDKCustomData *) customData;

- (id _Nullable) initWithCustomerPlayerData:(nullable MUXSDKCustomerPlayerData *) playerData
                                  videoData:(nullable MUXSDKCustomerVideoData *) videoData
                                   viewData:(nullable MUXSDKCustomerViewData *) viewData
                                 customData:(nullable MUXSDKCustomData *) customData
                                 viewerData:(nullable MUXSDKCustomerViewerData *) viewerData;
@end

#endif
