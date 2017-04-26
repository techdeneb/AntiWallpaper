//
//  AWSS3Client.m
//  AniWallpaper
//
//  Created by Vasyl Savka on 2/6/16.
//  Copyright © 2016 Vasyl Savka. All rights reserved.
//

#import "AWSS3Client.h"
#import "PremiumCategory.h"
#import "DataKeeper.h"
#import "Constants.h"
#import <AWSS3/AWSS3.h>

@interface AWSS3Client ()

@property (copy, nonatomic) AWSS3TransferUtilityDownloadCompletionHandlerBlock completionHandler;
@property (copy, nonatomic) AWSS3TransferUtilityDownloadProgressBlock downloadProgress;

@end

@implementation AWSS3Client

+ (AWSS3Client*)sharedClient
{
    static AWSS3Client *sharedClient = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedClient = [[AWSS3Client alloc] init];
    });
    
    return sharedClient;
}

- (void)getPremiumInfoFromAWS
{
    AWSS3 *s3 = [AWSS3 defaultS3];
    
    AWSS3ListObjectsRequest *listObjectsRequest = [AWSS3ListObjectsRequest new];
    listObjectsRequest.bucket = S3BucketName;
    listObjectsRequest.prefix = @"PremiumInfo";
    [[s3 listObjects:listObjectsRequest] continueWithBlock:^id(AWSTask *task) {
        if (task.error) {
            NSLog(@"listObjects failed: [%@]", task.error);
        } else {
            AWSS3ListObjectsOutput *listObjectsOutput = task.result;
            for (AWSS3Object *s3Object in listObjectsOutput.contents) {
                NSString *fileName = [s3Object.key lastPathComponent];
                NSString *downloadingFilePath = [NSTemporaryDirectory() stringByAppendingPathComponent:fileName];
                
                if ([[NSFileManager defaultManager] fileExistsAtPath:downloadingFilePath])
                {
                    NSLog(@"%@", downloadingFilePath);
                    NSString *extName = [[downloadingFilePath lastPathComponent] pathExtension];
                    if ([extName isEqualToString:@"plist"])
                    {
                        [self getPremiumCategoryInfoFromFilePath:downloadingFilePath];
                        
                        return nil;
                    }
                }
                else
                {
                    AWSS3TransferManagerDownloadRequest *downloadRequest = [AWSS3TransferManagerDownloadRequest new];
                    downloadRequest.bucket = S3BucketName;
                    downloadRequest.key = s3Object.key;
                    
                    [self download:downloadRequest Callback:nil];
                }
            }
        }
        
        return nil;
    }];
}

- (void)getS3Object:(NSString *)key Callback:(void (^)(NSURL *fileURL))callback
{
    NSString *downloadFilePath = [NSTemporaryDirectory() stringByAppendingPathComponent:key];
    if ([[NSFileManager defaultManager] fileExistsAtPath:downloadFilePath]) {
        NSURL *url = [NSURL fileURLWithPath:downloadFilePath];
        if (callback) callback(url);
    }
    else {
        AWSS3TransferManagerDownloadRequest *downloadRequest = [[AWSS3TransferManagerDownloadRequest alloc] init];
        downloadRequest.bucket = S3BucketName;
        downloadRequest.key = key;
        [self download:downloadRequest Callback:^{
            if (callback) callback(downloadRequest.downloadingFileURL);
        }];
    }
}

- (void)download:(AWSS3TransferManagerDownloadRequest *)downloadRequest Callback:(void (^)(void))callback {
    AWSS3TransferManager *transferManager = [AWSS3TransferManager defaultS3TransferManager];
    [[transferManager download:downloadRequest] continueWithExecutor:[AWSExecutor mainThreadExecutor]
                                                           withBlock:^id(AWSTask *task) {
                                                               if (task.error){
                                                                   if ([task.error.domain isEqualToString:AWSS3TransferManagerErrorDomain]) {
                                                                       switch (task.error.code) {
                                                                           case AWSS3TransferManagerErrorCancelled:
                                                                           case AWSS3TransferManagerErrorPaused:
                                                                               break;
                                                                               
                                                                           default:
                                                                               NSLog(@"Error: %@", task.error);
                                                                               break;
                                                                       }
                                                                   } else {
                                                                       // Unknown error.
                                                                       NSLog(@"Error: %@", task.error);
                                                                   }
                                                               }

                                                               if (task.result) {
                                                                   if (callback) callback();
                                                               }
                                                               
                                                               return nil;
                                                           }];
}

- (void)getPremiumCategoryInfoFromFilePath:(NSString *)path
{
    DataKeeper *dataKeeper = [DataKeeper sharedInstance];
    if (dataKeeper.arrayPremium.count > 0)
        return;
    
    NSMutableArray *arrayInfo = [[NSMutableArray alloc] initWithArray:[NSMutableArray arrayWithContentsOfFile:path]];
    for (int i = 0 ; i < arrayInfo.count ; i ++) {
        NSDictionary *dic = [arrayInfo objectAtIndex:i];
        PremiumCategory *premium = [[PremiumCategory alloc] init];
        premium.name = [dic objectForKey:keyName];
        premium.count = [[dic objectForKey:keyCount] integerValue];
        NSString *thumbPath = [NSString stringWithFormat:@"%@%@", [[path stringByDeletingLastPathComponent] stringByAppendingString:@"/"], [dic objectForKey:keyThumb]];
        premium.thumbImageName = thumbPath;
        [dataKeeper.arrayPremium addObject:premium];
    }
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(didFinishGetPremiumInfo)])
    {
        [self.delegate didFinishGetPremiumInfo];
    }
}

- (void)getPremiumContext:(NSString *)name
{
    AWSS3 *s3 = [AWSS3 defaultS3];
    
    AWSS3ListObjectsRequest *listObjectsRequest = [AWSS3ListObjectsRequest new];
    listObjectsRequest.bucket = S3BucketName;
    listObjectsRequest.prefix = [name lowercaseString];
    [[s3 listObjects:listObjectsRequest] continueWithBlock:^id(AWSTask *task) {
        if (task.error) {
            NSLog(@"listObjects failed: [%@]", task.error);
        } else {
        }
        
        return nil;
    }];}

- (void)getS3Objects:(NSArray*)arrayS3Objects;
{
    for (AWSS3Object *s3Object in arrayS3Objects)
    {
        NSString *fileName = [s3Object.key lastPathComponent];
        NSString *downloadingFilePath = [NSTemporaryDirectory() stringByAppendingPathComponent:fileName];
        
        NSLog(@"%@", downloadingFilePath);
        
        if ([[NSFileManager defaultManager] fileExistsAtPath:downloadingFilePath])
        {
            if (self.delegate && [self.delegate respondsToSelector:@selector(didFinishDownloadObject)])
            {
                [self.delegate didFinishDownloadObject];
            }
        }
        else
        {
            AWSS3TransferManagerDownloadRequest *downloadRequest = [AWSS3TransferManagerDownloadRequest new];
            downloadRequest.bucket = S3BucketName;
            downloadRequest.key = s3Object.key;
            
            [self download:downloadRequest Callback:nil];
        }
    }
}

@end
