//
//  MDMViewController.m
//  MDMEngine
//
//  Created by 李华林 on 14/11/28.
//  Copyright (c) 2014年 李华林. All rights reserved.
//
//  MDMClientApp的ViewController的父类

#import "MDMViewController.h"
#import "MDM.h"
#import "MDMUltil.h"

@interface MDMViewController ()

@end

@implementation MDMViewController

//@synthesize isShouldAutorotate;

- (id)initWithNibName:(NSString*)nibNameOrNil bundle:(NSBundle*)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    
    return self;
}

- (id)initWithCoder:(NSCoder*)aDecoder
{
    self = [super initWithCoder:aDecoder];
    return self;
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (BOOL) canBecomeFirstResponder
{
    return YES;
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self becomeFirstResponder];
}

- (void) viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self resignFirstResponder];
}

-(void)loadView
{
    [super loadView];
    
    //self.isOrientationPortrait = YES;
//    self.isShouldAutorotate = YES;
    [[MDMEngine shareEngine].mdmWidgetManage initRootWidget];
}

- (void)viewDidLoad {
    
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    //打开ROOT应用
    [[MDMEngine shareEngine].mdmWidgetManage openRootWidget];
    
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault];
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
    //iOS7以前不支持setNeedsStatusBarAppearanceUpdate
    if ([self respondsToSelector:@selector(setNeedsStatusBarAppearanceUpdate)]) {
        [self setNeedsStatusBarAppearanceUpdate];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval) duration
{
    [[MDMEngine shareEngine].mdmPluginManage willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskAllButUpsideDown;
}
- (BOOL)shouldAutorotate
{
    return (self.isShouldAutorotate||self.isForceRotation);
}

//- (BOOL)prefersStatusBarHidden
//{
//    UIDeviceOrientation deviceOrientation = [[UIDevice currentDevice] orientation];
//    return ((deviceOrientation==UIDeviceOrientationLandscapeLeft) || (deviceOrientation==UIDeviceOrientationLandscapeRight) ? YES : NO);
//}

@end
