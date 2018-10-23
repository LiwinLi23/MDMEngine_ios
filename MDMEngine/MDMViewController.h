//
//  MDMViewController.h
//  MDMEngine
//
//  Created by 李华林 on 14/11/28.
//  Copyright (c) 2014年 李华林. All rights reserved.
//
//  MDMClientApp的ViewController的父类

#import <UIKit/UIKit.h>
@interface MDMViewController : UIViewController

@property (readwrite, assign) BOOL isOrientationPortrait;
@property (readwrite, assign) BOOL isShouldAutorotate;//henry
@property (readwrite, assign) BOOL isForceRotation;//henry

@end
