//
//  PremiumCategory.m
//  AniWallpaper
//
//  Created by Vasyl Savka on 2/6/16.
//  Copyright © 2016 Vasyl Savka. All rights reserved.
//

#import "PremiumCategory.h"

@implementation PremiumCategory

- (id)init
{
    self = [super init];
    if (self)
    {
        self.name = nil;
        self.count = 0;
        self.thumbImageName = nil;
        self.currentLivePhoto = nil;
        self.arrayLivePhotos = [NSMutableArray array];
    }
    
    return self;
}

@end
