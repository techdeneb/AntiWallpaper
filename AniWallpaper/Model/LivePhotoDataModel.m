//
//  LivePhotoDataModel.m
//  AniWallpaper
//
//  Created by Vasyl Savka on 2/11/16.
//  Copyright © 2016 Vasyl Savka. All rights reserved.
//

#import "LivePhotoDataModel.h"
#import <AWSS3/AWSS3.h>
#import "Constants.h"

@implementation LivePhotoDataModel

- (id)init
{
    self = [super init];
    if (self)
    {
        self.photoURL = nil;
        self.videoURL = nil;
        self.isLoadedImage = NO;
        self.isLoadedVideo = NO;
    }
    
    return self;
}

- (void)transferPhotoInBackground:(void (^)(void))successed
{
    __weak LivePhotoDataModel *weakSelf = self;
    AWSS3TransferUtilityDownloadCompletionHandlerBlock completionHandler = ^(AWSS3TransferUtilityDownloadTask *task, NSURL *location, NSData *data, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (error) {
                NSLog(@"%@", error);
            }
            if (location) {
                weakSelf.photoURL = location;
                if (successed)
                    successed();
            }
            if (data) {
                NSLog(@"%@", data);
            }
        });
    };
    
    AWSS3TransferUtilityDownloadProgressBlock downloadProgress = ^(AWSS3TransferUtilityTask *task, int64_t bytesWritten, int64_t totalBytesWritten, int64_t totalBytesExpectedToWrite) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"Photo %@ - %f", self.name, (double)totalBytesWritten / (double)totalBytesExpectedToWrite);
        });
    };
    
    NSString *photoName = [NSString stringWithFormat:@"%@.JPG", self.name];
    NSString *downloadFilePath = [NSTemporaryDirectory() stringByAppendingPathComponent:photoName];
    if ([[NSFileManager defaultManager] fileExistsAtPath:downloadFilePath])
    {
        [[NSFileManager defaultManager] removeItemAtPath:downloadFilePath error:nil];
    }
    
    NSURL *photoURL =  [NSURL fileURLWithPath:downloadFilePath];
    
    AWSS3TransferUtilityDownloadExpression *expression = [AWSS3TransferUtilityDownloadExpression new];
    expression.downloadProgress = downloadProgress;
    
    AWSS3TransferUtility *transferUtility = [AWSS3TransferUtility defaultS3TransferUtility];
    [[transferUtility downloadToURL:photoURL
                             bucket:S3BucketName
                                key:photoName
                         expression:expression
                   completionHander:completionHandler] continueWithBlock:^id(AWSTask *task) {
        if (task.error) {
            NSLog(@"Error: %@", task.error);
        }
        if (task.exception) {
            NSLog(@"Exception: %@", task.exception);
        }
        if (task.result) {
            dispatch_async(dispatch_get_main_queue(), ^{
                
            });
        }
        
        return nil;
    }];
}

- (void)transferVideoInBackground:(void (^)(void))successed
{
    __weak LivePhotoDataModel *weakSelf = self;
    AWSS3TransferUtilityDownloadCompletionHandlerBlock completionHandler = ^(AWSS3TransferUtilityDownloadTask *task, NSURL *location, NSData *data, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (error) {
                NSLog(@"%@", error);
            }
            if (location) {
                weakSelf.videoURL = location;
                if (successed)
                    successed();
            }
            if (data) {
                NSLog(@"%@", data);
            }
        });
    };
    
    AWSS3TransferUtilityDownloadProgressBlock downloadProgress = ^(AWSS3TransferUtilityTask *task, int64_t bytesWritten, int64_t totalBytesWritten, int64_t totalBytesExpectedToWrite) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"Video %@ - %f", self.name, (double)totalBytesWritten / (double)totalBytesExpectedToWrite);
        });
    };

    
    NSString *videoName = [NSString stringWithFormat:@"%@.MOV", self.name];
    NSString *downloadFilePath = [NSTemporaryDirectory() stringByAppendingPathComponent:videoName];
    if ([[NSFileManager defaultManager] fileExistsAtPath:downloadFilePath])
    {
        [[NSFileManager defaultManager] removeItemAtPath:downloadFilePath error:nil];
    }

    NSURL *videoURL =  [NSURL fileURLWithPath:downloadFilePath];
    
    AWSS3TransferUtilityDownloadExpression *expression = [AWSS3TransferUtilityDownloadExpression new];
    expression.downloadProgress = downloadProgress;
    
    AWSS3TransferUtility *transferUtility = [AWSS3TransferUtility defaultS3TransferUtility];
    [[transferUtility downloadToURL:videoURL
                             bucket:S3BucketName
                                key:videoName
                         expression:expression
                   completionHander:completionHandler] continueWithBlock:^id(AWSTask *task) {
        if (task.error) {
            NSLog(@"Error: %@", task.error);
        }
        if (task.exception) {
            NSLog(@"Exception: %@", task.exception);
        }
        if (task.result) {
            dispatch_async(dispatch_get_main_queue(), ^{
                
            });
        }
        
        return nil;
    }];
}

- (BOOL)isLoaded
{
    return (self.isLoadedImage && self.isLoadedVideo && self.photoURL && self.videoURL);
}

@end
