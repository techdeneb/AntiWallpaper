//
//  AWSS3Client.h
//  AniWallpaper
//
//  Created by Vasyl Savka on 2/6/16.
//  Copyright © 2016 Vasyl Savka. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AWSS3/AWSS3.h>

@protocol AWSS3ClientDelegate <NSObject>

@optional
- (void)didFinishDownloadObject;
- (void)didFinishGetPremiumInfo;
- (void)didFinishGetListObject;

@end

@interface AWSS3Client : NSObject

@property (assign, nonatomic) id <AWSS3ClientDelegate> delegate;
@property (strong, nonatomic) NSArray *listS3Object;

+ (AWSS3Client*)sharedClient;

- (void)getPremiumInfoFromAWS;
- (void)getPremiumContext:(NSString *)name;
- (void)getS3Objects:(NSArray*)arrayS3Objects;

- (void)getS3Object:(NSString *)key Callback:(void (^)(NSURL *fileURL))callback;

@end
