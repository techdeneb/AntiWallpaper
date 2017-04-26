//
//  PremiumPhotoListVC.m
//  AniWallpaper
//
//  Created by Vasyl Savka on 2/1/16.
//  Copyright © 2016 Vasyl Savka. All rights reserved.
//

#import "PremiumPhotoListVC.h"
#import "FreeLivePhotoCell.h"
#import "DataKeeper.h"
#import "SVProgressHUD.h"
#import "AWSS3Client.h"

static NSString *cellIdentifier = @"Cell";

@interface PremiumPhotoListVC () <AWSS3ClientDelegate>

@property (strong, nonatomic) IBOutlet UICollectionView *collectionView;
@property (strong, nonatomic) IBOutlet UILabel *labelTitle;

@end

@implementation PremiumPhotoListVC

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationController.navigationBarHidden = YES;
}

- (IBAction)backAction:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    DataKeeper *dataKeeper = [DataKeeper sharedInstance];
    return dataKeeper.currentPremium.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    FreeLivePhotoCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier forIndexPath:indexPath];
    DataKeeper *dataKeeper = [DataKeeper sharedInstance];
    NSString *imagePath = [dataKeeper.currentPremium.arrayLivePhotoNames objectAtIndex:indexPath.row];
    [cell setImage:[UIImage imageWithContentsOfFile:imagePath]];
    [cell layoutIfNeeded];
    
    return cell;
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
}

@end
