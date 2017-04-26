//
//  BRTap.h
//  BRRecord
//
//  Created by chris glace on 4/25/16.
//  Copyright © 2016 Breakout Room. All rights reserved.
//

#ifndef BRTap_h
#define BRTap_h


#endif /* BRTap_h */
#import <Foundation/Foundation.h>

@interface BRTap : NSObject

@property unsigned int x;
@property unsigned int y;
@property NSNumber* timestamp;
- (NSDictionary *) toDict;

@end
