//
//  DataKeeper.m
//  AniWallpaper
//
//  Created by Vasyl Savka on 2/2/16.
//  Copyright © 2016 Vasyl Savka. All rights reserved.
//

#import "DataKeeper.h"
#import <HeyzapAds/HeyzapAds.h>

@implementation DataKeeper

+ (DataKeeper*)sharedInstance
{
    static DataKeeper *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[DataKeeper alloc] init];
    });
    
    return sharedInstance;
}

- (id)init
{
    self = [super init];
    
    if (self)
    {
        self.arrayFree = [NSMutableArray array];
        self.arrayPremium = [NSMutableArray array];
        self.currentPremium = nil;
        self.isFreeMode = YES;
        self.currentPageIndex = 0;
        self.currentCategoryType = Category_None;
        self.arrayNativeAd = [NSMutableArray array];
    }
    
    return self;
}

- (void)initNativeAds
{
    [HZNativeAdController fetchAds:20 tag:nil completion:^(NSError *error, HZNativeAdCollection *collection) {
        if (error) {
            NSLog(@"error = %@",error);
        } else {
            // Use the `collection` to display ads
            self.arrayNativeAd = [NSMutableArray arrayWithArray:collection.ads];
            [collection reportImpressionOnAllAds];            
        }
    }];
}

- (void)writeFreeInfoToFile
{
    NSMutableArray *arrayFreeName = [NSMutableArray array];
    for (int i = 0 ; i < self.arrayFree.count ; i ++) {
        LivePhotoDataModel *model = [self.arrayFree objectAtIndex:i];
        [arrayFreeName addObject:model.name];
    }
    [arrayFreeName writeToFile:self.filePath atomically:YES];
}


@end
