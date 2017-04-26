//
//  IntroScreenVC.m
//  AniWallpaper
//
//  Created by Vasyl Savka on 1/30/16.
//  Copyright © 2016 Vasyl Savka. All rights reserved.
//

#import "IntroScreenVC.h"
#import "SaveScreenVC.h"

@implementation IntroScreenVC

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"rectangle80.png"]];
}

- (IBAction)closeAction:(id)sender
{
    SaveScreenVC *vc = (SaveScreenVC *)self.parentViewController;
    [vc.containerView setHidden:YES];
    [self willMoveToParentViewController:nil];
    [self.view removeFromSuperview];
    [self removeFromParentViewController];
}

@end
