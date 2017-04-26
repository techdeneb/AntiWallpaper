//
//  Constants.m
//  AniWallpaper
//
//  Created by Vasyl Savka on 2/6/16.
//  Copyright © 2016 Vasyl Savka. All rights reserved.
//

#import "Constants.h"

// AWS
AWSRegionType const CognitoRegionType = AWSRegionUSEast1; // e.g. AWSRegionUSEast1
AWSRegionType const DefaultServiceRegionType = AWSRegionUSEast1; // e.g. AWSRegionUSEast1
NSString *const CognitoIdentityPoolId = @"us-east-1:c34ab2ef-5b80-4e43-a6b1-b9c37a6fa1b1";
NSString *const S3BucketName = @"aniwallpaper";

// plist file key values
NSString *const keyName = @"Name";
NSString *const keyCount = @"Count";
NSString *const keyThumb = @"Thumb";
NSString *const keyLivePhotos = @"LivePhotos";

NSString *const HeyzapPublisherId = @"39e670681bacafa6d98ce320e975f1a6";
NSString *const HeyzapAPIKey = @"1a4f4b97b1122695f1ad1f6cf37902f08f3654993a592b170c5e28ca29100f91";
NSString *const keyVideoAdTag = @"AdTag";
