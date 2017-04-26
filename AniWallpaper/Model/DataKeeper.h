//
//  DataKeeper.h
//  AniWallpaper
//
//  Created by Vasyl Savka on 2/2/16.
//  Copyright © 2016 Vasyl Savka. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PremiumCategory.h"

typedef enum
{
    Category_Free = 0,
    Category_Abstract,
    Category_Animals,
    Category_Bokeh,
    Category_Music,
    Category_Particle,
    Category_Religion,
    Category_Space,
    Category_UnderWater,
    Category_None
} CategoryType;

@interface DataKeeper : NSObject

@property (strong, nonatomic) NSMutableArray *arrayFree;
@property (strong, nonatomic) NSMutableArray *arrayPremium;
@property (strong, nonatomic) PremiumCategory *currentPremium;
@property (assign, nonatomic) BOOL isFreeMode;
@property (assign, nonatomic) NSInteger currentPageIndex;
@property (assign, nonatomic) CategoryType currentCategoryType;
@property (strong, nonatomic) NSMutableArray    *arrayNativeAd;
@property (strong, nonatomic) NSString *filePath;

+ (DataKeeper*)sharedInstance;

- (void)initNativeAds;
- (void)writeFreeInfoToFile;

@end
