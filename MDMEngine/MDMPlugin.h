//
//  MDMPlugin.h
//  MDMEngine
//
//  Created by 李华林 on 14/11/28.
//  Copyright (c) 2014年 李华林. All rights reserved.
//
//  MDM插件基类

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class MDMWebView;
@class MDMWidget;

@interface MDMPlugin : NSObject

@property (nonatomic, weak) MDMWebView *curWebView;               //调用本插件时所在的WEBVIEW
@property (nonatomic, weak) MDMWidget *curWidget;               //调用本插件时所在的WIDGET
@property (nonatomic, weak) UIViewController  *viewController;    //主控制器


/*
 功能：设置JS的回调函数
 参数：
 opId:操作ID
 dataType:操作类型
 data:返回的数据
 */
-(void)setJsCallback:(NSString*)strCallbackName
                opId:(int)inOpId
            dataType:(int)inDataType
                data:(NSString*)strData;

//直接在插件所在的curWebView中执行JavaScript
-(void)evalJavaScript:(NSString *)strJs;

//前台路径转换为代码所需的实际路径(wgt:// res:// box://)
-(NSString *)changeSchemeToPath:(NSString *)scheme;

//获取相关地址
- (NSString *)photoPath;
- (NSString *)audioPath;
- (NSString *)videoPath;
- (NSString *)dataPath;
- (NSString *)myspacePath;

-(NSString*)getEngineBuild;
-(NSString*)getEngineVersion;

//添加子VIEW
-(void)addSubView:(UIView*)view;
//设置插件是否支持横屏或竖屏
-(void)setIsOrientationPortrait:(BOOL)flag;
//设置插件是否支持自动旋转屏
- (void)setIsShouldAutorotate:(BOOL)flag;//henry
//设置强制旋转屏
-(void) setIsForceRotation:(BOOL)flag;//henry

@end
