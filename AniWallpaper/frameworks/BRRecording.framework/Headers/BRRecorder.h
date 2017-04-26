//
// Created by chris glace on 3/16/16.
// Copyright (c) 2016 Fullstack.io. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "ScreenRecorder.h"
#import "BRReachability.h"
#import "SegmentData.h"
#import "BRTapRecorder.h"
#import <AWSS3/AWSS3.h>
#import "BRTapRecorder.h"
#import "BRUtils.h"

typedef NS_ENUM(NSInteger, BRVideoQuality) {
    BR_VIDEO_VERY_LOW,
    BR_VIDEO_LOW,
    BR_VIDEO_MEDIUM,
    BR_VIDEO_HIGH,
    BR_VIDEO_VERY_HIGH
};

@interface BRRecorder : NSObject

@property NSMutableArray *events;
@property ScreenRecorder *screenCapture;
@property (nonatomic, readonly) BOOL isRecording;

@property bool wifiOnly;
@property(setter = setFps:, getter = getFps) NSNumber *fps;
@property(setter = setQualityLevel:, getter = getQualityLevel) BRVideoQuality qualityLevel;
@property bool autoUpload;
@property NSInteger maxRecordLength;
@property NSString *userConfigurableIdentifier;
@property NSMutableDictionary *metaData;
/**
 * if saveURL is nil, video will be saved into camera roll
 * this property can not be changed whilst recording is in progress
 */
@property (strong, nonatomic) NSURL *videoURL;

+ (instancetype)sharedInstance;
+ (instancetype)sharedInstance:(NSString *)accountIdentifier;
+ (instancetype)sharedInstance:(NSDictionary *)settings identifiedWith:(NSString *)accountIdentifier;
- (BOOL)startRecording;
- (void) setIdentifier:(NSString *) identifier;
- (NSDictionary *) getEvent:(NSString *)eventString andData:(NSString *)eventData;
- (void)pauseRecording;
- (void)resumeRecording;
- (void)stopAndUpload;
- (void)stopRecording;
- (void)stopRecordingWithoutUpload;
- (void)maxRecordLengthTriggered;
- (void)addMetaData:(NSString *) key value:(id)value;
@end