//
//  SaveScreenVC.m
//  AniWallpaper
//
//  Created by Vasyl Savka on 1/30/16.
//  Copyright © 2016 Vasyl Savka. All rights reserved.
//

#import "SaveScreenVC.h"
#import "AniWallpaper-Swift.h"
#import "DataKeeper.h"
#import "SVProgressHUD.h"
#import "AWSS3Client.h"
#import "PremiumCategory.h"
#import "StyledPageControl.h"
#import "Constants.h"
#import <HeyzapAds/HeyzapAds.h>

@import Photos;
@import PhotosUI;
@import MobileCoreServices;

@interface SaveScreenVC() <PHLivePhotoViewDelegate, PHPhotoLibraryChangeObserver, AWSS3ClientDelegate, HZAdsDelegate>

@property (strong, nonatomic) PHLivePhotoView *livePhotoView;
@property (strong, nonatomic) NSLayoutConstraint *leftLC;
@property (strong, nonatomic) NSURL *photoURL;
@property (strong, nonatomic) NSURL *videoURL;
@property (strong, nonatomic) IBOutlet UIScrollView *scrollView;
@property (strong, nonatomic) StyledPageControl *pageControl;
@property (strong, nonatomic) NSMutableArray *arrayFreeLivePhoto;
@property (strong, nonatomic) NSMutableArray *arrayPremiumLivePhoto;
@property (assign, nonatomic) PHLivePhotoRequestID currentRequestID;
@property (strong, nonatomic) NSMutableArray *arrayIndicatorView;
@property (strong, nonatomic) NSMutableArray *arrayImageView;
@property (assign, nonatomic) CategoryType currentCategoryType;
@property (assign, nonatomic) BOOL isStartedFreeRandom;

- (IBAction)saveAction:(id)sender;

@end

@implementation SaveScreenVC

- (void)awakeFromNib
{
    [[PHPhotoLibrary sharedPhotoLibrary] registerChangeObserver:self];
    
    [AWSS3Client sharedClient].delegate = self;
    self.arrayFreeLivePhoto = [NSMutableArray array];
    self.arrayPremiumLivePhoto = [NSMutableArray array];
    self.arrayImageView = [NSMutableArray array];
    self.arrayIndicatorView = [NSMutableArray array];
    self.currentCategoryType = Category_Free;
    self.isStartedFreeRandom = NO;
}

- (void)dealloc
{
    [[PHPhotoLibrary sharedPhotoLibrary] unregisterChangeObserver:self];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    DataKeeper *dataKeeper = [DataKeeper sharedInstance];
    self.arrayFreeLivePhoto = [NSMutableArray arrayWithArray:dataKeeper.arrayFree];
    
    [self loadPremiumInfo];
    
    [self initLivePhotoView];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    DataKeeper *dataKeeper = [DataKeeper sharedInstance];
    if (dataKeeper.currentCategoryType != self.currentCategoryType)
    {
        [self initUI];
        
        self.photoURL = nil;
        self.videoURL = nil;
        
        if (dataKeeper.isFreeMode)
        {
            DataKeeper *dataKeeper = [DataKeeper sharedInstance];
            self.leftLC.constant = dataKeeper.currentPageIndex * self.view.frame.size.width;
            [self.view layoutIfNeeded];
            [self initFreeLivePhoto:dataKeeper.currentPageIndex];
        }
        else
        {
            AWSS3TransferManager *transferManager = [AWSS3TransferManager defaultS3TransferManager];
            [transferManager cancelAll];
            
            self.leftLC.constant = 0;
            [self.view layoutIfNeeded];
            [self loadPremiumData:0];
        }
        
        self.currentCategoryType = dataKeeper.currentCategoryType;
    }
    else
    {
        self.photoURL = nil;
        self.videoURL = nil;
        
        if (dataKeeper.isFreeMode)
        {
            if (dataKeeper.arrayFree.count != self.arrayFreeLivePhoto.count)
                [self initUI];
            
            DataKeeper *dataKeeper = [DataKeeper sharedInstance];
            self.leftLC.constant = dataKeeper.currentPageIndex * self.view.frame.size.width;
            [self.view layoutIfNeeded];
            [self initFreeLivePhoto:dataKeeper.currentPageIndex];
        }
        else
        {
            AWSS3TransferManager *transferManager = [AWSS3TransferManager defaultS3TransferManager];
            [transferManager resumeAll:^(AWSRequest *request) {
                
            }];
            
            [self.livePhotoView stopPlayback];
            //[self.livePhotoView startPlaybackWithStyle:PHLivePhotoViewPlaybackStyleFull];
        }
    }
    
    [self.scrollView scrollRectToVisible:CGRectMake(self.leftLC.constant, 0, self.view.frame.size.width, self.view.frame.size.height) animated:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)loadPremiumInfo
{
    BOOL success;
    NSError* error;
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0]:nil;
    NSString *filePath = [basePath stringByAppendingPathComponent:@"Premium.plist"];
    
    if ([fileManager fileExistsAtPath:filePath]) {
        [fileManager removeItemAtPath:filePath error:&error];
    }
    
    NSString *defaultDBPath = [[NSBundle mainBundle] pathForResource:@"Premium" ofType:@"plist"];
    success = [fileManager copyItemAtPath:defaultDBPath toPath:filePath error:&error];
    if (!success) {
        NSCAssert1(0, @"Failed to create writable database file with message '%@'.", [error localizedDescription]);
    }
    
    if (!success) {
        NSCAssert1(0, @"Failed to create writable database file with message '%@'.", [error localizedDescription]);
    }
    
    DataKeeper *dataKeeper = [DataKeeper sharedInstance];
    NSArray *arrayPremium = [[NSMutableArray alloc] initWithArray:[NSMutableArray arrayWithContentsOfFile:filePath]];
    for (int i = 0 ; i < arrayPremium.count ; i ++) {
        NSDictionary *dic = [arrayPremium objectAtIndex:i];
        
        PremiumCategory *premium = [[PremiumCategory alloc] init];
        
        premium.name = [dic objectForKey:keyName];
        premium.count = [[dic objectForKey:keyCount] integerValue];
        premium.thumbImageName = [dic objectForKey:keyThumb];
        
        NSArray *arrayNames = [NSArray arrayWithArray:[dic objectForKey:keyLivePhotos]];
        
        for (int i = 0 ; i < arrayNames.count ; i ++)
        {
            LivePhotoDataModel *livePhotoDataModel = [[LivePhotoDataModel alloc] init];
            livePhotoDataModel.name = [arrayNames objectAtIndex:i];
            [premium.arrayLivePhotos addObject:livePhotoDataModel];
        }
        
        [dataKeeper.arrayPremium addObject:premium];
    }
}

- (void)initUI
{
    [self removeAllLivePhotoViewFromSuperView];
    
    DataKeeper *dataKeeper = [DataKeeper sharedInstance];

    if (dataKeeper.isFreeMode)
    {
        [self addFreeLivePhotoViews];
    }
    else
    {
        [self addPremiumLivePhotoViews];
    }
    
    [self.scrollView bringSubviewToFront:self.livePhotoView];
    self.livePhotoView.hidden = YES;
}

- (void)initLivePhotoView
{
    CGFloat width = self.scrollView.frame.size.width;
    DataKeeper *dataKeeper = [DataKeeper sharedInstance];
    
    if (self.livePhotoView == nil)
    {
        self.livePhotoView = [[PHLivePhotoView alloc] init];
        self.livePhotoView.delegate = self;
        self.livePhotoView.tag = 10000;
        self.livePhotoView.muted = NO;
        self.livePhotoView.translatesAutoresizingMaskIntoConstraints = NO;
        self.livePhotoView.backgroundColor = [UIColor clearColor];
        [self.scrollView addSubview:self.livePhotoView];
        
        self.leftLC = [NSLayoutConstraint constraintWithItem:self.livePhotoView
                                                   attribute:NSLayoutAttributeLeft
                                                   relatedBy:NSLayoutRelationEqual
                                                      toItem:self.scrollView
                                                   attribute:NSLayoutAttributeLeft
                                                  multiplier:1.0
                                                    constant:width * dataKeeper.currentPageIndex];
        [self.scrollView addConstraint:self.leftLC];
        
        [self.scrollView addConstraint:[NSLayoutConstraint constraintWithItem:self.livePhotoView
                                                                    attribute:NSLayoutAttributeTop
                                                                    relatedBy:NSLayoutRelationEqual
                                                                       toItem:self.scrollView
                                                                    attribute:NSLayoutAttributeTop
                                                                   multiplier:1.0
                                                                     constant:0]];
        
        [self.scrollView addConstraint:[NSLayoutConstraint constraintWithItem:self.livePhotoView
                                                                    attribute:NSLayoutAttributeWidth
                                                                    relatedBy:NSLayoutRelationEqual
                                                                       toItem:self.scrollView
                                                                    attribute:NSLayoutAttributeWidth
                                                                   multiplier:1.0
                                                                     constant:0]];
        
        [self.scrollView addConstraint:[NSLayoutConstraint constraintWithItem:self.livePhotoView
                                                                    attribute:NSLayoutAttributeHeight
                                                                    relatedBy:NSLayoutRelationEqual
                                                                       toItem:self.scrollView
                                                                    attribute:NSLayoutAttributeHeight
                                                                   multiplier:1.0
                                                                     constant:0.0]];
    }
}

- (void)addFreeLivePhotoViews
{
    CGFloat width = self.view.bounds.size.width;
    DataKeeper *dataKeeper = [DataKeeper sharedInstance];
    NSInteger count = dataKeeper.arrayFree.count;
    NSInteger startIndex = -1;
    for (NSInteger i = 0 ; i < count ; i ++)
    {
        LivePhotoDataModel *model = [dataKeeper.arrayFree objectAtIndex:i];
        UIImageView *subView = [[UIImageView alloc] init];
        subView.translatesAutoresizingMaskIntoConstraints = NO;
        subView.tag = i;
        subView.contentMode = UIViewContentModeScaleAspectFill;
        
        subView.backgroundColor = [UIColor colorWithRed:10 * i / 255.0 green:10 * i / 255.0 blue:10 * i / 255.0 alpha:1.0];
        [self.scrollView addSubview:subView];
        
        [self.scrollView addConstraint:[NSLayoutConstraint constraintWithItem:subView
                                                                    attribute:NSLayoutAttributeLeft
                                                                    relatedBy:NSLayoutRelationEqual
                                                                       toItem:self.scrollView
                                                                    attribute:NSLayoutAttributeLeft
                                                                   multiplier:1.0
                                                                     constant:width * i]];
        
        [self.scrollView addConstraint:[NSLayoutConstraint constraintWithItem:subView
                                                                    attribute:NSLayoutAttributeTop
                                                                    relatedBy:NSLayoutRelationEqual
                                                                       toItem:self.scrollView
                                                                    attribute:NSLayoutAttributeTop
                                                                   multiplier:1.0
                                                                     constant:0]];
        
        [self.scrollView addConstraint:[NSLayoutConstraint constraintWithItem:subView
                                                                    attribute:NSLayoutAttributeWidth
                                                                    relatedBy:NSLayoutRelationEqual
                                                                       toItem:self.scrollView
                                                                    attribute:NSLayoutAttributeWidth
                                                                   multiplier:1.0
                                                                     constant:0]];
        
        [self.scrollView addConstraint:[NSLayoutConstraint constraintWithItem:subView
                                                                    attribute:NSLayoutAttributeHeight
                                                                    relatedBy:NSLayoutRelationEqual
                                                                       toItem:self.scrollView
                                                                    attribute:NSLayoutAttributeHeight
                                                                   multiplier:1.0
                                                                     constant:0.0]];
        
        UIActivityIndicatorView *indicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        indicatorView.translatesAutoresizingMaskIntoConstraints = NO;
        [subView addSubview:indicatorView];
        
        [subView addConstraint:[NSLayoutConstraint constraintWithItem:indicatorView
                                                            attribute:NSLayoutAttributeCenterX
                                                            relatedBy:NSLayoutRelationEqual
                                                               toItem:subView
                                                            attribute:NSLayoutAttributeCenterX
                                                           multiplier:1.0
                                                             constant:0]];
        
        [subView addConstraint:[NSLayoutConstraint constraintWithItem:indicatorView
                                                            attribute:NSLayoutAttributeCenterY
                                                            relatedBy:NSLayoutRelationEqual
                                                               toItem:subView
                                                            attribute:NSLayoutAttributeCenterY
                                                           multiplier:1.0
                                                             constant:0]];
        [indicatorView startAnimating];
        indicatorView.hidesWhenStopped = YES;
        
        [self.arrayIndicatorView addObject:indicatorView];
        [self.arrayImageView addObject:subView];
        
        UIImage *image = [UIImage imageWithContentsOfFile:model.photoURL.path];
        if (image)
        {
            subView.image = image;
            [indicatorView stopAnimating];
        }
        else
        {
            if (_isStartedFreeRandom == NO)
            {
                startIndex = i;
                _isStartedFreeRandom = YES;
            }
        }
    }
    
    if (startIndex != -1)
        [self loadFreeRandomData:startIndex];
    
    self.scrollView.contentSize = CGSizeMake(width * count, self.view.bounds.size.height);
    
    self.scrollView.pagingEnabled = YES;
    self.scrollView.showsHorizontalScrollIndicator = NO;
    self.scrollView.showsVerticalScrollIndicator = NO;
    self.scrollView.scrollsToTop = NO;
    
    self.pageControl = [[StyledPageControl alloc] init];
    [self.view addSubview:self.pageControl];
    [self.pageControl setFrame:CGRectMake(0, 0, 0, 0)];
    [self.pageControl setPageControlStyle:PageControlStyleDefault];
    [self.pageControl setNumberOfPages:(int)count];
    [self.pageControl setCurrentPage:(int)dataKeeper.currentPageIndex];
    [self.pageControl setUserInteractionEnabled:NO];
    
    CGRect frame = self.scrollView.frame;
    frame.origin.x = width * dataKeeper.currentPageIndex;
    frame.origin.y = 0;
    [self.scrollView scrollRectToVisible:frame animated:YES];
}

- (void)addPremiumLivePhotoViews
{
    CGFloat width = self.view.frame.size.width;
    DataKeeper *dataKeeper = [DataKeeper sharedInstance];
    NSInteger count = dataKeeper.currentPremium.arrayLivePhotos.count;
    for (NSInteger i = 0 ; i < count ; i ++)
    {
        UIImageView *livePhotoView = [[UIImageView alloc] init];
        livePhotoView.translatesAutoresizingMaskIntoConstraints = NO;
        livePhotoView.tag = i;
        livePhotoView.contentMode = UIViewContentModeScaleAspectFill;
        livePhotoView.backgroundColor = [UIColor blackColor];
        
        [self.scrollView addSubview:livePhotoView];
        [self.arrayImageView addObject:livePhotoView];
        
        [self.scrollView addConstraint:[NSLayoutConstraint constraintWithItem:livePhotoView
                                                                    attribute:NSLayoutAttributeLeft
                                                                    relatedBy:NSLayoutRelationEqual
                                                                       toItem:self.scrollView
                                                                    attribute:NSLayoutAttributeLeft
                                                                   multiplier:1.0
                                                                     constant:width * i]];
        
        [self.scrollView addConstraint:[NSLayoutConstraint constraintWithItem:livePhotoView
                                                                    attribute:NSLayoutAttributeTop
                                                                    relatedBy:NSLayoutRelationEqual
                                                                       toItem:self.scrollView
                                                                    attribute:NSLayoutAttributeTop
                                                                   multiplier:1.0
                                                                     constant:0]];
        
        [self.scrollView addConstraint:[NSLayoutConstraint constraintWithItem:livePhotoView
                                                                    attribute:NSLayoutAttributeWidth
                                                                    relatedBy:NSLayoutRelationEqual
                                                                       toItem:self.scrollView
                                                                    attribute:NSLayoutAttributeWidth
                                                                   multiplier:1.0
                                                                     constant:0]];
        
        [self.scrollView addConstraint:[NSLayoutConstraint constraintWithItem:livePhotoView
                                                                    attribute:NSLayoutAttributeHeight
                                                                    relatedBy:NSLayoutRelationEqual
                                                                       toItem:self.scrollView
                                                                    attribute:NSLayoutAttributeHeight
                                                                   multiplier:1.0
                                                                     constant:0.0]];
        
        UIActivityIndicatorView *indicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        indicatorView.translatesAutoresizingMaskIntoConstraints = NO;
        [livePhotoView addSubview:indicatorView];
        
        [livePhotoView addConstraint:[NSLayoutConstraint constraintWithItem:indicatorView
                                                                  attribute:NSLayoutAttributeCenterX
                                                                  relatedBy:NSLayoutRelationEqual
                                                                     toItem:livePhotoView
                                                                  attribute:NSLayoutAttributeCenterX
                                                                 multiplier:1.0
                                                                   constant:0]];
        
        [livePhotoView addConstraint:[NSLayoutConstraint constraintWithItem:indicatorView
                                                                  attribute:NSLayoutAttributeCenterY
                                                                  relatedBy:NSLayoutRelationEqual
                                                                     toItem:livePhotoView
                                                                  attribute:NSLayoutAttributeCenterY
                                                                 multiplier:1.0
                                                                   constant:0]];
        [indicatorView startAnimating];
        indicatorView.hidesWhenStopped = YES;
        
        [self.arrayIndicatorView addObject:indicatorView];
    }
    
    self.scrollView.contentSize = CGSizeMake(width * count, self.view.bounds.size.height);
    
    self.scrollView.pagingEnabled = YES;
    self.scrollView.showsHorizontalScrollIndicator = NO;
    self.scrollView.showsVerticalScrollIndicator = NO;
    self.scrollView.scrollsToTop = NO;
    
    self.pageControl = [[StyledPageControl alloc] init];
    [self.view addSubview:self.pageControl];
    [self.pageControl setFrame:CGRectMake(0, 0, 0, 0)];
    [self.pageControl setPageControlStyle:PageControlStyleDefault];
    [self.pageControl setNumberOfPages:(int)count];
    [self.pageControl setCurrentPage:(int)dataKeeper.currentPageIndex];
    [self.pageControl setUserInteractionEnabled:NO];
    
    CGRect frame = self.scrollView.frame;
    frame.origin.x = width * dataKeeper.currentPageIndex;
    frame.origin.y = 0;
    [self.scrollView scrollRectToVisible:frame animated:YES];
}

- (void)removeAllLivePhotoViewFromSuperView
{
    for (UIView *view in self.scrollView.subviews) {
        if (view.tag != 10000)
            [view removeFromSuperview];
    }
    
    [self.arrayIndicatorView removeAllObjects];
    [self.arrayImageView removeAllObjects];
}

- (void)initFreeLivePhoto:(NSInteger)index
{
    self.photoURL = nil;
    self.videoURL = nil;
    
    [self.livePhotoView stopPlayback];
    [PHLivePhoto cancelLivePhotoRequestWithRequestID:self.currentRequestID];
    
    DataKeeper *dataKeeper = [DataKeeper sharedInstance];
    LivePhotoDataModel *model = [dataKeeper.arrayFree objectAtIndex:index];
    NSArray<NSURL *> *urls = @[
                               model.photoURL,
                               model.videoURL,
                               ];
    self.currentRequestID = [PHLivePhoto requestLivePhotoWithResourceFileURLs:urls placeholderImage:nil targetSize:self.livePhotoView.frame.size contentMode:PHImageContentModeAspectFill resultHandler:^(PHLivePhoto * _Nullable livePhoto, NSDictionary * _Nonnull info) {
        self.livePhotoView.hidden = NO;
        self.livePhotoView.livePhoto = livePhoto;
        //[self.livePhotoView startPlaybackWithStyle:PHLivePhotoViewPlaybackStyleFull];
        
        self.photoURL = model.photoURL;
        self.videoURL = model.videoURL;
    }];
}

- (void)initPremiumLivePhoto:(LivePhotoDataModel *)model
{
    self.photoURL = nil;
    self.videoURL = nil;
    
    [self.livePhotoView stopPlayback];
    [PHLivePhoto cancelLivePhotoRequestWithRequestID:self.currentRequestID];
    
    NSArray<NSURL *> *urls = @[
                               model.photoURL,
                               model.videoURL,
                               ];
    self.currentRequestID = [PHLivePhoto requestLivePhotoWithResourceFileURLs:urls placeholderImage:nil targetSize:self.livePhotoView.frame.size contentMode:PHImageContentModeAspectFill resultHandler:^(PHLivePhoto * _Nullable livePhoto, NSDictionary * _Nonnull info) {
        self.livePhotoView.hidden = NO;
        self.livePhotoView.livePhoto = livePhoto;
        //[self.livePhotoView startPlaybackWithStyle:PHLivePhotoViewPlaybackStyleFull];
        
        self.photoURL = model.photoURL;
        self.videoURL = model.videoURL;
    }];
}

- (void)loadFreeRandomData:(NSInteger)index
{
    DataKeeper *dataKeeper = [DataKeeper sharedInstance];
    if (dataKeeper.arrayFree.count <= index)
        return;
    
    LivePhotoDataModel *model = [dataKeeper.arrayFree objectAtIndex:index];
    
    NSString *photoName = [NSString stringWithFormat:@"%@.JPG", model.name];
    NSString *videoName = [NSString stringWithFormat:@"%@.MOV", model.name];
    
    if (!model.isLoadedImage)
    {
        [[AWSS3Client sharedClient] getS3Object:photoName Callback:^(NSURL *fileURL) {
            UIImageView *imageView = [self.arrayImageView objectAtIndex:index];
            imageView.image = [UIImage imageWithContentsOfFile:fileURL.path];
            [imageView layoutIfNeeded];
            
            model.photoURL = fileURL;
            
            if (model.isLoadedVideo)
            {
                UIActivityIndicatorView *view = [self.arrayIndicatorView objectAtIndex:index];
                [view stopAnimating];
                
                if (dataKeeper.currentPageIndex == index)
                    [self initFreeLivePhoto:index];
                
                [self loadFreeRandomData:index + 1];
            }
            
            model.isLoadedImage = YES;
        }];
    }
    
    if (!model.isLoadedVideo)
    {
        [[AWSS3Client sharedClient] getS3Object:videoName Callback:^(NSURL *fileURL) {
            model.videoURL = fileURL;
            
            if (model.isLoadedImage)
            {
                UIActivityIndicatorView *view = [self.arrayIndicatorView objectAtIndex:index];
                [view stopAnimating];
                
                if (dataKeeper.currentPageIndex == index)
                    [self initFreeLivePhoto:index];
                
                [self loadFreeRandomData:index + 1];
            }
            
            model.isLoadedVideo = YES;
        }];
    }
}

- (void)loadPremiumData:(NSInteger)index
{
    DataKeeper *dataKeeper = [DataKeeper sharedInstance];
    if (dataKeeper.currentPremium.arrayLivePhotos.count <= index)
        return;
    
    LivePhotoDataModel *model = [dataKeeper.currentPremium.arrayLivePhotos objectAtIndex:index];
    
    NSString *photoName = [NSString stringWithFormat:@"%@.JPG", model.name];
    NSString *videoName = [NSString stringWithFormat:@"%@.MOV", model.name];
    
    if (!model.isLoadedImage)
    {
        [[AWSS3Client sharedClient] getS3Object:photoName Callback:^(NSURL *fileURL) {
            UIImageView *imageView = [self.arrayImageView objectAtIndex:index];
            imageView.image = [UIImage imageWithContentsOfFile:fileURL.path];
            [imageView layoutIfNeeded];
            
            model.photoURL = fileURL;
            
            if (model.isLoadedVideo)
            {
                UIActivityIndicatorView *view = [self.arrayIndicatorView objectAtIndex:index];
                [view stopAnimating];
                
                if (dataKeeper.currentPageIndex == index)
                    [self initPremiumLivePhoto:model];
                
                [self loadPremiumData:index + 1];
            }
            
            model.isLoadedImage = YES;
        }];
    }
    
    if (!model.isLoadedVideo)
    {
        [[AWSS3Client sharedClient] getS3Object:videoName Callback:^(NSURL *fileURL) {
            model.videoURL = fileURL;
            
            if (model.isLoadedImage)
            {
                UIActivityIndicatorView *view = [self.arrayIndicatorView objectAtIndex:index];
                [view stopAnimating];
                
                if (dataKeeper.currentPageIndex == index)
                    [self initPremiumLivePhoto:model];
                
                [self loadPremiumData:index + 1];
            }
            
            model.isLoadedVideo = YES;
        }];
    }
}

- (void)loadVideo:(NSString*)name WithVideoURL:(NSURL*)videoURL
{
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:videoURL options:nil];
    
    AVAssetImageGenerator *generator = [AVAssetImageGenerator assetImageGeneratorWithAsset:asset];
    generator.appliesPreferredTrackTransform = YES;
    
    CMTime time = CMTimeMakeWithSeconds(CMTimeGetSeconds(asset.duration) / 2, asset.duration.timescale);
    
    [generator generateCGImagesAsynchronouslyForTimes:[NSArray arrayWithObject:[NSValue valueWithCMTime:time]] completionHandler:^(CMTime requestedTime, CGImageRef  _Nullable image, CMTime actualTime, AVAssetImageGeneratorResult result, NSError * _Nullable error) {
        NSData *data = UIImagePNGRepresentation([UIImage imageWithCGImage:image]);
        if (image && data)
        {
            NSURL *imageURL = [self getLivePhotURL:name];
            [data writeToURL:imageURL atomically:YES];
            
            NSString *imagePath = [imageURL path];
            NSString *moviePath = [videoURL path];
            NSString *outputPath = [self getOutPutPath];
            NSString *assetIdentifier = [NSUUID UUID].UUIDString;
            
            NSString *videoName = [NSString stringWithFormat:@"%@.MOV", name];
            NSString *imageName = [NSString stringWithFormat:@"%@.JPG", name];
            
            if ([[NSFileManager defaultManager] createDirectoryAtPath:outputPath withIntermediateDirectories:YES attributes:nil error:nil])
            {
                [[NSFileManager defaultManager] removeItemAtPath:[outputPath stringByAppendingString:imageName] error:nil];
                [[NSFileManager defaultManager] removeItemAtPath:[outputPath stringByAppendingString:videoName] error:nil];
            }
            
            JPEG *jpeg = [[JPEG alloc] initWithPath:imagePath];
            [jpeg write:[outputPath stringByAppendingString:imageName] assetIdentifier:assetIdentifier];
            
            QuickTimeMov *mov = [[QuickTimeMov alloc] initWithPath:moviePath];
            [mov write:[outputPath stringByAppendingString:videoName] assetIdentifier:assetIdentifier];
            
            NSLog(@"%@ video completed successfully", name);
            
            self.photoURL = [NSURL URLWithString:[outputPath stringByAppendingString:imageName]];
            self.videoURL = [NSURL URLWithString:[outputPath stringByAppendingString:videoName]];
            
            NSArray<NSURL *> *urls = @[
                                       [NSURL fileURLWithPath:[outputPath stringByAppendingString:imageName]],
                                       [NSURL fileURLWithPath:[outputPath stringByAppendingString:videoName]],
                                       ];
            
            [PHLivePhoto requestLivePhotoWithResourceFileURLs:urls placeholderImage:nil targetSize:self.view.bounds.size contentMode:PHImageContentModeAspectFill resultHandler:^(PHLivePhoto * _Nullable livePhoto, NSDictionary * _Nonnull info) {
            }];
        }
    }];
}

- (NSURL*)getLivePhotURL:(NSString *)fileName {
    
    // find Documents directory
    NSURL *documentsURL = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] objectAtIndex:0];
    
    // append a file name to it
    documentsURL = [documentsURL URLByAppendingPathComponent:fileName];
    
    return documentsURL;
}

- (void)exportLivePhoto
{
    if (self.photoURL == nil || self.videoURL == nil)
        return;
    
    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
        PHAssetCreationRequest *request = [PHAssetCreationRequest creationRequestForAsset];
        [request addResourceWithType:PHAssetResourceTypePairedVideo fileURL:self.videoURL options:nil /*videoOptions*/];
        [request addResourceWithType:PHAssetResourceTypePhoto fileURL:self.photoURL options:nil /*photoOptions*/];
    } completionHandler:^(BOOL success, NSError * _Nullable error) {
        NSLog(@"success? %d, error: %@", success, error);
        [SVProgressHUD showSuccessWithStatus:@"Saved"];
    }];
}

- (NSString *)getOutPutPath
{
    NSString *path = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *outputPath = [path stringByAppendingString:@"/"];
    
    return outputPath;
}

#pragma mark - Action

- (IBAction)saveAction:(id)sender
{
    if ([PHPhotoLibrary authorizationStatus] == PHAuthorizationStatusAuthorized)
    {
        [self exportLivePhoto];
    }
    else
    {
        UIAlertController *controller = [UIAlertController alertControllerWithTitle:@"Please Allow to Access Your Photos in Setting"
                                                                            message:nil
                                                                     preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *alertAction = [UIAlertAction actionWithTitle:@"Ok"
                                                              style:UIAlertActionStyleDefault
                                                            handler:^(UIAlertAction *action) {
                                                                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
                                                            }];
        
        [controller addAction: alertAction];
        [self presentViewController: controller animated: YES completion: nil];
    }
}

#pragma mark - UINavigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(nullable id)sender
{
    if (![segue.destinationViewController isKindOfClass:[SaveScreenVC class]]) {
        [self.livePhotoView stopPlayback];
        AWSS3TransferManager *transferManager = [AWSS3TransferManager defaultS3TransferManager];
        [transferManager pauseAll];
    }
}

#pragma mark - PHPhotoLibraryChangeObserver

- (void)photoLibraryDidChange:(PHChange *)changeInstance {
}

#pragma mark - PHLivePhotoView Delegate

- (void)livePhotoView:(PHLivePhotoView *)livePhotoView didEndPlaybackWithStyle:(PHLivePhotoViewPlaybackStyle)playbackStyle
{
    [self.livePhotoView stopPlayback];
//    [self.livePhotoView startPlaybackWithStyle:playbackStyle];
}

#pragma mark - UIScrollView Delegate

- (void)scrollViewWillBeginDecelerating:(UIScrollView *)scrollView
{
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    CGFloat pageWidth = scrollView.frame.size.width;
    int page = floor((scrollView.contentOffset.x - pageWidth / 2) / pageWidth) + 1;
   
    self.livePhotoView.livePhoto = nil;

    DataKeeper *dataKeeper = [DataKeeper sharedInstance];
    if (dataKeeper.isFreeMode)
    {
        LivePhotoDataModel *model = [dataKeeper.arrayFree objectAtIndex:page];
        if ([model isLoaded])
        {
            self.leftLC.constant = page * self.view.frame.size.width;
            [self.view layoutIfNeeded];
            
            [self initFreeLivePhoto:page];
        }
    }
    else
    {
        LivePhotoDataModel *model = [dataKeeper.currentPremium.arrayLivePhotos objectAtIndex:page];
        if ([model isLoaded])
        {
            self.leftLC.constant = page * self.view.frame.size.width;
            [self.view layoutIfNeeded];
            
            [self initPremiumLivePhoto:model];
        }
    }
    
    dataKeeper.currentPageIndex = page;
}

@end
