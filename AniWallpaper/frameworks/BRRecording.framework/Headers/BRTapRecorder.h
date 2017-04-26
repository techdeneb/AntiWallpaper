//
//  BRTapRecording.h
//  BRRecord
//
//  Created by chris glace on 4/25/16.
//  Copyright © 2016 Breakout Room. All rights reserved.
//

#import "BRTap.h"

#ifndef BRTapRecording_h
#define BRTapRecording_h


#endif /* BRTapRecording_h */



@interface BRTapRecorder : NSObject
+ (instancetype)sharedInstance;
- (void)addTap:(BRTap *)tap;
- (NSArray *) getTaps;

@end