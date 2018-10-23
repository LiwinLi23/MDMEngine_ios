//
//  MDMPlugin.m
//  MDMEngine
//
//  Created by 李华林 on 14/11/28.
//  Copyright (c) 2014年 李华林. All rights reserved.
//
//  MDM插件基类

#import "MDMPlugin.h"
#import "MDMWebView.h"
#import "MDMWidget.h"
#import "MDMViewController.h"
#import "MDMNavigationController.h"

@implementation MDMPlugin

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
                data:(NSString*)strData
{
    NSString* strJs = [NSString stringWithFormat:@"if(%@) %@(%d,%d,'%@');",
                       strCallbackName,
                       strCallbackName,
                       inOpId,
                       inDataType,
                       strData];
//    NSLog(@"%@",strData);
    [self.curWebView stringByEvaluatingJavaScriptFromString:strJs];
    
    
    if ([MDMStatisticsPlugin sharedInstance].isDebug) {
        NSString *logs = [NSString stringWithFormat:@"%@(%d,%d,'%@');",strCallbackName,
                          inOpId,
                          inDataType,
                          strData];
        [[MDMStatisticsPlugin sharedInstance] sendDebugLog:logs];
    } else {
        NSLog(@"回调：%@",strCallbackName);
    }
}

//直接在插件所在的curWebView中执行JavaScript
-(void)evalJavaScript:(NSString *)strJs
{
    [self.curWebView stringByEvaluatingJavaScriptFromString:strJs];
    if ([MDMStatisticsPlugin sharedInstance].isDebug) {
        NSString *logs = [NSString stringWithFormat:@"%@",strJs];
        [[MDMStatisticsPlugin sharedInstance] sendDebugLog:logs];
    } else {
        NSLog(@"eval:%@",strJs);
    }
}

//前台路径转换为代码所需的实际路径
- (NSString *)changeSchemeToPath:(NSString *)scheme
{
    return [self.curWidget pathFromSchemePath:scheme];
}

//获取相关地址
- (NSString *)photoPath
{
    return [self.curWidget photoPath];
}
- (NSString *)audioPath
{
    return [self.curWidget audioPath];
}
- (NSString *)videoPath
{
    return [self.curWidget videoPath];
}
- (NSString *)dataPath
{
    return [self.curWidget dataPath];
}
- (NSString *)myspacePath
{
    return [self.curWidget myspacePath];
}

-(NSString*)getEngineBuild
{
    return [NSString stringWithFormat:@"%@",MDMENGINE_BUILD];
}
-(NSString*)getEngineVersion
{
    return [NSString stringWithFormat:@"%@",MDMENGINE_VERSION];
}

//添加子VIEW
-(void)addSubView:(UIView*)view
{
    [self.curWebView addSubview:view];
}

-(void)setIsOrientationPortrait:(BOOL)flag
{
    [(MDMViewController*)((MDMNavigationController*)(self.viewController)).visibleViewController setIsOrientationPortrait:flag];
//    printf("\n========IsOrientationPortrait:%d\n",flag);
}

- (void)setIsShouldAutorotate:(BOOL)flag
{
    [(MDMViewController*)((MDMNavigationController*)(self.viewController)).visibleViewController setIsShouldAutorotate:flag];
}
-(void) setIsForceRotation:(BOOL)flag
{
    [(MDMViewController*)((MDMNavigationController*)(self.viewController)).visibleViewController setIsForceRotation:flag];
}
@end
