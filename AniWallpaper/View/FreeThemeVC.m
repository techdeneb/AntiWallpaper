//
//  FreeThemeVC.m
//  AniWallpaper
//
//  Created by Vasyl Savka on 2/26/16.
//  Copyright © 2016 Vasyl Savka. All rights reserved.
//

#import "FreeThemeVC.h"
#import "AppDelegate.h"
#import "DataKeeper.h"
#import "PremiumCategory.h"
#import "AWSS3Client.h"
#import "LivePhotoDataModel.h"
#import "SVProgressHUD.h"
#import <Social/Social.h>
#import <HeyzapAds/HeyzapAds.h>

#define Key_WatchVideo  @"WatchVideo"
#define Key_ShareToFacebook @"ShareToFacebook"
#define Key_LikeUs  @"LikeUs"

@interface FreeThemeVC () <UITableViewDataSource, UITableViewDelegate, HZAdsDelegate>

@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) NSMutableArray *arrayCell;

@end

@implementation FreeThemeVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    _arrayCell = [NSMutableArray array];
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    [_arrayCell addObject:Key_WatchVideo];
    if ([[prefs objectForKey:Key_ShareToFacebook] boolValue] == NO)
        [_arrayCell addObject:Key_ShareToFacebook];
    if ([[prefs objectForKey:Key_LikeUs] boolValue] == NO)
        [_arrayCell addObject:Key_LikeUs];
    
    [_tableView reloadData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSString*)getCallIdentifier:(NSString*)name
{
    NSString *identifier = nil;
    if ([Key_WatchVideo isEqualToString:name])
        identifier = @"Cell1";
    else if ([Key_ShareToFacebook isEqualToString:name])
        identifier = @"Cell2";
    else if ([Key_LikeUs isEqualToString:name])
        identifier = @"Cell3";
    
    return identifier;
}

- (LivePhotoDataModel*)getRandomLivePhotoDataModel
{
    DataKeeper *dataKeeper = [DataKeeper sharedInstance];
    srand((unsigned int)time(nil));
    NSInteger randomIndex = random() % (dataKeeper.arrayPremium.count - 1);
    PremiumCategory *premium = [dataKeeper.arrayPremium objectAtIndex:randomIndex];
    randomIndex = random() % (premium.arrayLivePhotos.count - 1);
    LivePhotoDataModel *model = [premium.arrayLivePhotos objectAtIndex:randomIndex];
    if ([dataKeeper.arrayFree containsObject:model])
        model = [self getRandomLivePhotoDataModel];
    
    return model;
}

- (void)shareToFacebook
{
    if ([SLComposeViewController isAvailableForServiceType:SLServiceTypeFacebook]) {
        SLComposeViewController *controller = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeFacebook];
        controller.completionHandler = ^(SLComposeViewControllerResult result) {
            if (result == SLComposeViewControllerResultDone)
            {
                DataKeeper *dataKeeper = [DataKeeper sharedInstance];
                for (int i = 0 ; i < 5 ; i ++) {
                    LivePhotoDataModel *model = [self getRandomLivePhotoDataModel];
                    [dataKeeper.arrayFree addObject:model];
                }
                
                NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
                [prefs setObject:[NSNumber numberWithBool:YES] forKey:Key_ShareToFacebook];
                [_arrayCell removeObject:Key_ShareToFacebook];
                
                [_tableView reloadData];
                
                [dataKeeper writeFreeInfoToFile];                
            }
        };
        
        [controller setInitialText:@"#AniWallpaper"];
        [controller addImage:[UIImage imageNamed:@"B_Circles.JPG"]];
        [self presentViewController:controller animated:YES completion:Nil];
    }
}

- (IBAction)watchSponoredVideoAction:(id)sender
{
    [UIApplication sharedApplication].keyWindow.rootViewController = self;
    
    [HZVideoAd setDelegate:self];
    [HZVideoAd show];
}

- (IBAction)shareWithYourFriendsAction:(id)sender
{
    [self shareToFacebook];
}

- (IBAction)likeUsAction:(id)sender
{
    NSURL *instagramURL = [NSURL URLWithString:@"https://www.instagram.com/p/BB_kpvRluWu/"];
    if ([[UIApplication sharedApplication] canOpenURL:instagramURL]) {
        [[UIApplication sharedApplication] openURL:instagramURL];
        
        DataKeeper *dataKeeper = [DataKeeper sharedInstance];
        for (int i = 0 ; i < 3 ; i ++) {
            LivePhotoDataModel *model = [self getRandomLivePhotoDataModel];
            [dataKeeper.arrayFree addObject:model];
        }
        
        NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
        [prefs setObject:[NSNumber numberWithBool:YES] forKey:Key_LikeUs];
        [_arrayCell removeObject:Key_LikeUs];
        
        [_tableView reloadData];
        
        [dataKeeper writeFreeInfoToFile];
    }
}

#pragma mark - UITableView Delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 70;
}

- (IBAction)backAction:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UITableView DataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger count = [_arrayCell count];
    return count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *cellIdentifier = [self getCallIdentifier:(NSString *)[_arrayCell objectAtIndex:indexPath.row]];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    return cell;
}

#pragma mark - HeyzapAds Delegate

- (void)didHideAdWithTag: (NSString *) tag
{
    DataKeeper *dataKeeper = [DataKeeper sharedInstance];
    LivePhotoDataModel *model = [self getRandomLivePhotoDataModel];
    [dataKeeper.arrayFree addObject:model];
    
    [_tableView reloadData];
    
    [dataKeeper writeFreeInfoToFile];
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}

@end
