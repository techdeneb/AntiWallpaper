//
//  LivePhotoListVC.m
//  AniWallpaper
//
//  Created by Vasyl Savka on 1/30/16.
//  Copyright © 2016 Vasyl Savka. All rights reserved.
//

#import "LivePhotoListVC.h"
#import "FreeLivePhotoCell.h"
#import "PremiumLivePhotoCell.h"
#import "PremiumPhotoListVC.h"
#import "DataKeeper.h"
#import "SVPullToRefresh.h"
#import "AWSS3Client.h"
#import "SVProgressHUD.h"
#import "SaveScreenVC.h"
#import "Constants.h"
#import "FreeThemeVC.h"
#import "NativeAdCell.h"
#import "UIImageView+AFNetworking.h"
#import <AWSS3/AWSS3.h>
#import <HeyzapAds/HeyzapAds.h>

static NSString *freeCellIdentifier = @"FreeCell";
static NSString *premiumCellIdentifier = @"PremiumCell";
static NSString *nativeAdCellIdentifier = @"NativeAdCell";
static NSString *freePremiumCellIdentifier = @"FreePremiumCell";
static NSInteger indexHeyZapCell = 8;

@interface LivePhotoListVC() <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, AWSS3ClientDelegate, HZAdsDelegate, SKStoreProductViewControllerDelegate>

@property (strong, nonatomic) IBOutlet UIButton *buttonFree;
@property (strong, nonatomic) IBOutlet UIButton *buttonPremium;
@property (strong, nonatomic) IBOutlet UIView *viewFreeMark;
@property (strong, nonatomic) IBOutlet UIView *viewPremiumMark;
@property (strong, nonatomic) IBOutlet UICollectionView *collectionView;

@property (assign, nonatomic) BOOL isFree;
@property (strong, nonatomic) UIImage *imageNativeAd;
@property (strong, nonatomic) HZNativeAd *nativeAd;

@end

@implementation LivePhotoListVC

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationController.navigationBarHidden = YES;
    
    self.isFree = YES;
    [self selectedItem:0];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.navigationController.navigationBarHidden = YES;
    
    [self.collectionView reloadData];
}

- (void)initHZVideoAd
{
    [HZVideoAd setDelegate:self];
    
    [HeyzapAds networkCallbackWithBlock:^(NSString *network, NSString *callback) {
        [self logToConsole:[NSString stringWithFormat:@"Network: %@ Callback: %@", network, callback]];
        
        NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
        NSString *videoAdTag = @"0";
        if ([prefs objectForKey:keyVideoAdTag])
            videoAdTag = [prefs objectForKey:keyVideoAdTag];
        
        [HZVideoAd fetchForTag:videoAdTag withCompletion:^(BOOL result, NSError *error) {
            [self logToConsole:[NSString stringWithFormat:@"Fetch successful? %@ error: %@", result ? @"yes" : @"no", error]];
        }];
    }];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(remoteDataRefreshed:) name:HZRemoteDataRefreshedNotification object:nil];
}

- (void)showNativeAds
{
    [UIApplication sharedApplication].keyWindow.rootViewController = self;
    [_nativeAd presentAppStoreFromViewController:self
                                  storeDelegate:self
                                     completion:^(BOOL result, NSError *error) {
                                         // Dismiss the loading spinner here, if you showed one.
                                         // Apple's SKStoreProductViewController may error out trying to load the app store; you can ignore this error as we fallback to switching to the app store app in this case.
                                         NSLog(@"%@", error);
                                     }];
}

- (void)selectedItem:(NSInteger)selectedItem
{
    switch (selectedItem) {
        case 0:
        {
            [self.buttonFree setSelected:YES];
            [self.buttonPremium setSelected:NO];
            [self.viewFreeMark setHidden:NO];
            [self.viewPremiumMark setHidden:YES];
            
            self.isFree = YES;
            
            [self.collectionView reloadData];
        }
            break;
        case 1:
        {
            [self.buttonFree setSelected:NO];
            [self.buttonPremium setSelected:YES];
            [self.viewFreeMark setHidden:YES];
            [self.viewPremiumMark setHidden:NO];
            
            self.isFree = NO;
            
            [self.collectionView reloadData];
        }
            break;
        default:
            break;
    }
}

- (void)logToConsole:(NSString *)consoleString {
    NSDateFormatter * format = [[NSDateFormatter alloc]init];
    [format setDateFormat:@"[h:mm:ss a]"];
    NSLog(@"\n\n%@ %@",[format stringFromDate:[NSDate date]], consoleString);
}

#pragma mark - Action

- (IBAction)selectItemAction:(id)sender
{
    UIButton *button = (UIButton*)sender;
    [self selectedItem:button.tag];
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    NSInteger count = 0;
    DataKeeper *dataKeeper = [DataKeeper sharedInstance];
    if (self.isFree)
        count = dataKeeper.arrayFree.count + 2;
    else
        count = dataKeeper.arrayPremium.count;
    
    return count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    DataKeeper *dataKeeper = [DataKeeper sharedInstance];
    if (self.isFree)
    {
        NSInteger index = indexPath.row;
        if (index == indexHeyZapCell)
        {
            DataKeeper *dataKeeper = [DataKeeper sharedInstance];

            NativeAdCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:nativeAdCellIdentifier forIndexPath:indexPath];
            if (cell.imageView.image || dataKeeper.arrayNativeAd.count == 0)
            {
                return cell;
            }
            
            srand((unsigned int)time(nil));
            int randomIndex = (int)(random() % (dataKeeper.arrayNativeAd.count - 1));
            
            _nativeAd = [dataKeeper.arrayNativeAd objectAtIndex:randomIndex];
            [_nativeAd reportImpression];
            
            NSURLRequest *reqeust = nil;
            if (_nativeAd.portraitCreative)
                reqeust = [NSURLRequest requestWithURL:_nativeAd.portraitCreative.url];
            else
                reqeust = [NSURLRequest requestWithURL:_nativeAd.landscapeCreative.url];
            
            __weak NativeAdCell *weakCell = cell;
            [cell.imageView setImageWithURLRequest:reqeust placeholderImage:nil success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
                _imageNativeAd = image;
                [weakCell.imageView setImage:_imageNativeAd];
                [weakCell layoutIfNeeded];
            } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
                NSLog(@"Failed");
            }];
            
            return cell;
        }
        else if (index == dataKeeper.arrayFree.count + 1)
        {
            UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:freePremiumCellIdentifier forIndexPath:indexPath];
            return cell;
        }
        else
        {
            if (index > indexHeyZapCell)
                index --;
            
            FreeLivePhotoCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:freeCellIdentifier forIndexPath:indexPath];
            LivePhotoDataModel *model = [dataKeeper.arrayFree objectAtIndex:index];

            if (model.photoURL)
            {
                UIImage *image = [UIImage imageWithContentsOfFile:model.photoURL.path];
                [cell setImage:image];
                [cell.progressView stopAnimating];
            }
            else
            {
                [cell setImage:nil];
                [cell.progressView startAnimating];
            }
            
            [cell layoutIfNeeded];
            
            return cell;
        }
    }
    else
    {
        PremiumLivePhotoCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:premiumCellIdentifier forIndexPath:indexPath];
        PremiumCategory *premium = [dataKeeper.arrayPremium objectAtIndex:indexPath.row];
        [cell setImage:[UIImage imageNamed:premium.thumbImageName]];
        [cell setTitle:premium.name];
        [cell setCount:premium.count];
        [cell layoutIfNeeded];
        
        return cell;
    }
}

#pragma mark - UICollectionViewLayout Delegate

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    CGSize size = CGSizeMake(self.collectionView.frame.size.width / 2 , self.collectionView.frame.size.height / 2);
    
    return size;
}

#pragma mark - UICollectionView Delegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    DataKeeper *dataKeeper = [DataKeeper sharedInstance];
    dataKeeper.isFreeMode = self.isFree;
    
    if (self.isFree)
    {
        NSInteger index = indexPath.row;
        if (index == indexHeyZapCell)
        {
            [self showNativeAds];
        }
        else if (index == dataKeeper.arrayFree.count + 1)
        {
        }
        else
        {
            if (index > indexHeyZapCell)
                index --;
            
            dataKeeper.isFreeMode = YES;
            dataKeeper.currentPageIndex = index;
            dataKeeper.currentCategoryType = Category_Free;
            [self dismissViewControllerAnimated:YES completion:nil];
        }
    }
    else
    {
        dataKeeper.currentPremium = [dataKeeper.arrayPremium objectAtIndex:indexPath.row];
        dataKeeper.isFreeMode = NO;
        dataKeeper.currentPageIndex = 0;
        dataKeeper.currentCategoryType = (CategoryType)(indexPath.row + 1);
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Configure the destination PhotoEditVC.
    if ([segue.destinationViewController isKindOfClass:[SaveScreenVC class]]) {
    }
}

#pragma mark - NSNotifications

- (void)remoteDataRefreshed:(NSNotification *)notification {
    if([notification.userInfo count] > 0) {
        [self logToConsole:[NSString stringWithFormat:@"Remote data refreshed. Data: %@", notification.userInfo]];
    } else {
        [self logToConsole:[NSString stringWithFormat:@"Remote data refreshed (empty)"]];
    }
}

@end
