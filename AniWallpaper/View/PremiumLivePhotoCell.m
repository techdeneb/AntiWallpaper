//
//  PremiumLivePhotoCell.m
//  AniWallpaper
//
//  Created by Vasyl Savka on 2/1/16.
//  Copyright © 2016 Vasyl Savka. All rights reserved.
//

#import "PremiumLivePhotoCell.h"

@interface PremiumLivePhotoCell()

@property (strong, nonatomic) IBOutlet UIImageView *imageView;
@property (strong, nonatomic) IBOutlet UILabel *labelTitle;
@property (strong, nonatomic) IBOutlet UILabel *labelCount;

@end

@implementation PremiumLivePhotoCell

- (void)setImage:(UIImage*)image
{
    [self.imageView setImage:image];
}

- (void)setTitle:(NSString*)title
{
    [self.labelTitle setText:title];
}

- (void)setCount:(NSInteger)count
{
    [self.labelCount setText:[NSString stringWithFormat:@"%d", (int)count]];
}

@end
