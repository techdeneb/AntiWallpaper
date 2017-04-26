//
//  LivePhotoCell.h
//  AniWallpaper
//
//  Created by Vasyl Savka on 2/1/16.
//  Copyright © 2016 Vasyl Savka. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FreeLivePhotoCell : UICollectionViewCell

@property (strong, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *progressView;

- (void)setImage:(UIImage*)image;

@end
