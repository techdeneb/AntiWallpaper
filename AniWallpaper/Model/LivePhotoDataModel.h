//
//  LivePhotoDataModel.h
//  AniWallpaper
//
//  Created by Vasyl Savka on 2/11/16.
//  Copyright © 2016 Vasyl Savka. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LivePhotoDataModel : NSObject

@property (strong, nonatomic) NSString *name;
@property (strong, nonatomic) NSURL *photoURL;
@property (strong, nonatomic) NSURL *videoURL;
@property (assign, nonatomic) BOOL  isLoadedImage;
@property (assign, nonatomic) BOOL  isLoadedVideo;

- (void)transferPhotoInBackground:(void (^)(void))successed;
- (void)transferVideoInBackground:(void (^)(void))successed;

- (BOOL)isLoaded;

@end
