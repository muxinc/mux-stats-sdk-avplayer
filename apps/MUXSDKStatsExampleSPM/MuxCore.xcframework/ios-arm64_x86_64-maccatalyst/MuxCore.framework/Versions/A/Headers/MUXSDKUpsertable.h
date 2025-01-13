//
//  MUXSDKQueryDataUpsert.h
//  MuxCore
//
//  Created by Nidhi Kulkarni on 3/2/22.
//  Copyright © 2022 Mux. All rights reserved.
//

#ifndef MUXSDKQueryDataUpsert_h
#define MUXSDKQueryDataUpsert_h

@protocol MUXSDKUpsertable
+ (MUXSDKQueryData * _Nonnull) upsert:(MUXSDKQueryData * _Nullable) query withData:( NSDictionary * _Nonnull ) updates;
@end

#endif /* MUXSDKQueryDataUpsert_h */
