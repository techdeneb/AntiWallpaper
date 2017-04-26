//
//  AppDelegate.m
//  AniWallpaper
//
//  Created by Vasyl Savka on 1/30/16.
//  Copyright © 2016 Vasyl Savka. All rights reserved.
//

@import AdSupport;
@import CoreGraphics;
@import CoreLocation;
@import CoreTelephony;
@import EventKit;
@import EventKitUI;
@import MediaPlayer;
@import MessageUI;
@import MobileCoreServices;
@import QuartzCore;
@import Security;
@import StoreKit;
@import SystemConfiguration;

#import "AppDelegate.h"
#import "DataKeeper.h"
#import <AWSCore/AWSCore.h>
#import <AWSS3/AWSS3.h>
#import <AWSCognito/AWSCognito.h>
#import "Constants.h"
#import <Fabric/Fabric.h>
#import <Crashlytics/Crashlytics.h>
#import <HeyzapAds/HeyzapAds.h>
#import <BRRecording/BRRecorder.h>

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    [self initAWS];
//    [self initHeyzapAds];
//    [self initFabric];
    
    [self loadFreeData];
    
    BRRecorder *screenRecorder = [BRRecorder sharedInstance: @{
                                                               @"fps": @(4.0),
                                                               @"qualityLevel": @(BR_VIDEO_MEDIUM),
                                                               @"maxRecordLength": @(200),
                                                               @"identifier": @"AniWallpaper",
                                                               @"wifiOnly": @(TRUE)
                                                               } identifiedWith: @"d79803d98a6fb17c"];
    
    [screenRecorder startRecording];
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (void)application:(UIApplication *)application handleEventsForBackgroundURLSession:(NSString *)identifier completionHandler:(void (^)())completionHandler {
    /*
     Store the completion handler.
     */
    [AWSS3TransferUtility interceptApplication:application
           handleEventsForBackgroundURLSession:identifier
                             completionHandler:completionHandler];
}

- (void)initHeyzapAds
{
    [HeyzapAds startWithPublisherID:HeyzapPublisherId];
    [HZVideoAd fetch];
    
    DataKeeper *dataKeeper = [DataKeeper sharedInstance];
    [dataKeeper initNativeAds];
}

- (void)initAWS
{
    AWSCognitoCredentialsProvider *credentialsProvider = [[AWSCognitoCredentialsProvider alloc] initWithRegionType:CognitoRegionType
                                                                                                    identityPoolId:CognitoIdentityPoolId];
    AWSServiceConfiguration *configuration = [[AWSServiceConfiguration alloc] initWithRegion:DefaultServiceRegionType
                                                                         credentialsProvider:credentialsProvider];
    AWSServiceManager.defaultServiceManager.defaultServiceConfiguration = configuration;
}

- (void)initFabric
{
    [Fabric with:@[[AWSCognito class], [Crashlytics class]]];
}

- (void)loadFreeData
{
    BOOL success;
    NSError* error;
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0]:nil;
    NSString *filePath = [basePath stringByAppendingPathComponent:@"Free.plist"];
    
    if ([fileManager fileExistsAtPath:filePath] == NO) {
        NSString *defaultDBPath = [[NSBundle mainBundle] pathForResource:@"Free" ofType:@"plist"];
        success = [fileManager copyItemAtPath:defaultDBPath toPath:filePath error:&error];
        if (!success) {
            NSCAssert1(0, @"Failed to create writable database file with message '%@'.", [error localizedDescription]);
        }
        
        if (!success) {
            NSCAssert1(0, @"Failed to create writable database file with message '%@'.", [error localizedDescription]);
        }
    }
    
    DataKeeper *dataKeeper = [DataKeeper sharedInstance];
    dataKeeper.filePath = filePath;
    NSMutableArray *arrayFree = [[NSMutableArray alloc] initWithArray:[NSMutableArray arrayWithContentsOfFile:filePath]];
    for (int i = 0 ; i < arrayFree.count ; i ++) {
        NSString *name = [arrayFree objectAtIndex:i];
        LivePhotoDataModel *model = [LivePhotoDataModel alloc];
        model.name = name;
        model.photoURL = [[NSBundle mainBundle] URLForResource:name withExtension:@"JPG"];
        model.videoURL = [[NSBundle mainBundle] URLForResource:name withExtension:@"MOV"];
        model.isLoadedImage = (model.photoURL != nil);
        model.isLoadedVideo = (model.videoURL != nil);
        [dataKeeper.arrayFree addObject:model];
    }
}

- (void)showVideoAd
{
    [HZVideoAd show];
    [HZVideoAd fetch];
}

@end
