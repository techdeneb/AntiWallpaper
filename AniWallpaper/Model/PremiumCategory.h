//
//  PremiumCategory.h
//  AniWallpaper
//
//  Created by Vasyl Savka on 2/6/16.
//  Copyright © 2016 Vasyl Savka. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "LivePhotoDataModel.h"

@interface PremiumCategory : NSObject

@property (strong, nonatomic) NSString *name;
@property (strong, nonatomic) NSArray *arrayLivePhotoNames;
@property (strong, nonatomic) LivePhotoDataModel *currentLivePhoto;
@property (assign, nonatomic) NSInteger count;
@property (strong, nonatomic) NSString *thumbImageName;
@property (strong, nonatomic) NSMutableArray *arrayLivePhotos;

@end
