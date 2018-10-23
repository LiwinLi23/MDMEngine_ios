//
//  MDMUltil.m
//  MDMEngine
//
//  Created by 李华林 on 15/1/21.
//  Copyright (c) 2015年 李华林. All rights reserved.
//

#import "MDMUltil.h"

@implementation MDMUltil

+ (void)setNavigationBarColor:(UINavigationController *)navController color:(UIColor *)color
{
    
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0) {
        navController.navigationBar.barTintColor = color;
    } else {
        navController.navigationBar.tintColor = color;
        [navController.navigationBar setTranslucent:YES];
    }
}

+(CGRect)getMDMInitFrame
{
    if ([[[UIDevice currentDevice] systemVersion] floatValue] < 7.0 ){
        int appWidth = [UIScreen mainScreen].applicationFrame.size.width;
        int appHeight = [UIScreen mainScreen].applicationFrame.size.height;
        return CGRectMake(0, 0, appWidth, appHeight);
    }else{
//        NSLog(@"main Bundle:%@",[[NSBundle mainBundle] infoDictionary]);
        int appWidth = [UIScreen mainScreen].bounds.size.width;
        int appHeight = [UIScreen mainScreen].bounds.size.height;
        BOOL isStatusBarHidden=[UIApplication sharedApplication].statusBarHidden;
        if (isStatusBarHidden) {
            return CGRectMake(0, 0, appWidth, appHeight);
        }
        NSNumber *statusBarStyleIOS7 = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"StatusBarStyleIOS7"];
        int statusBarHeight = 20;
        if ([statusBarStyleIOS7 boolValue] == YES) {
            return CGRectMake(0, 0, appWidth, appHeight);
        }else{
            [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
            return CGRectMake(0, statusBarHeight, appWidth, appHeight - statusBarHeight);
        }
    }
}

@end
