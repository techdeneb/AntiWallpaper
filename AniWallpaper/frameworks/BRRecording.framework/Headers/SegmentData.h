//
//  SegmentData.h
//  Pods
//
//  Created by chris glace on 4/8/16.
//
//
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#ifndef SegmentData_h
#define SegmentData_h

@interface SegmentData : NSObject

- (NSInteger) segmentCount;
- (void) addSegment:(NSString *)videoId segment:(int)segment;
- (NSMutableArray *) getVideos;
- (void) removeOldSegments;
- (int) getSegmentCount;

@end

#endif /* SegmentData_h */
