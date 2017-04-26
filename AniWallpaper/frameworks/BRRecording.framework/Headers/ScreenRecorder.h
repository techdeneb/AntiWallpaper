#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>


typedef void (^VideoCompletionBlock)(void);
@protocol ScreenRecorderDataSource;
@protocol ScreenRecorderDelegate;

@interface ScreenRecorder : NSObject
@property (nonatomic, readonly) BOOL isRecording;

/*
 *delegate is only required when implementing ASScreenRecorderDelegate - see below
 */

@property (strong, nonatomic) NSURL *videoURL;

@property (nonatomic, weak) id <ScreenRecorderDelegate> delegate;
@property (nonatomic, weak) id <ScreenRecorderDataSource> dataSource;
@property (nonatomic) BOOL uploading;
@property (nonatomic) CGFloat scale;
@property (nonatomic, getter = isPaused) BOOL paused;
@property (nonatomic, strong) UIApplication *application;
@property (nonatomic, strong) UIScreen *screen;
@property (nonatomic, strong) NSFileManager *fileManager;
@property (nonatomic, strong) UIDevice *device;
@property (nonatomic, strong) NSRunLoop *runLoop;
@property (nonatomic, strong) NSNumber *scaledHeight;
@property (nonatomic, strong) NSNumber *scaledWidth;



/**
 * Default value is 60.
 * Set this property before calling -startRecording;
 */
@property (nonatomic) NSNumber *fps;

+ (instancetype)sharedInstance;
- (BOOL)startRecording;
- (void)pauseRecording;
- (void)setScale:(CGFloat)scale;
- (void)resumeRecording;
- (void)stopRecordingWithCompletion:(VideoCompletionBlock)completionBlock;

@end


// If your view contains an AVCaptureVideoPreviewLayer or an openGL view
// you'll need to write that data into the CGContextRef yourself.
// In the viewcontroller responsible for the AVCaptureVideoPreviewLayer / openGL view
// set yourself as the dataSource for ASScreenRecorder.
// [ASScreenRecorder sharedInstance].dataSource = self
// Then implement 'screenRecorder:requestToDrawInContext:'
// use 'CGContextDrawImage' to draw your view into the provided CGContextRef
@protocol ScreenRecorderDelegate <NSObject>
- (void)writeBackgroundFrameInContext:(CGContextRef*)contextRef;
@end
