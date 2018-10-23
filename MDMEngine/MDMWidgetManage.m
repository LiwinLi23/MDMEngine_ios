//
//  MDMWidgetManage.m
//  MDMEngine
//
//  Created by 李华林 on 14/11/28.
//  Copyright (c) 2014年 李华林. All rights reserved.
//
//  管理所有子应用（应用：表示一个具体的窗口，在这里我们使用Widget来表示）
//

#import "MDMWidgetManage.h"
#import <QuartzCore/QuartzCore.h>
#import "MDMViewController.h"
#import "MDMUltil.h"

@interface MDMWidgetManage ()
@property (nonatomic, strong) UIViewController* viewControl;
@end

@implementation MDMWidgetManage

- (id)init
{
    self = [super init];
    if (self) {
        return self;
    }
    return nil;
}

- (void)dealloc
{
    _rootWidget = nil;
    _subWidget = nil;
    _currentWidget = nil;
    _viewControl = nil;
}

//初始化应用管理器，viewControl为需要承载应用的viewControl
-(MDMWidgetManage*)initWithViewControl:(UIViewController*) viewControl
{
    self = [self init];
    if (self) {
        self.viewControl = viewControl;
        return self;
    }
    return nil;
}

#pragma mark - widget management

//初使化root应用
- (BOOL)initRootWidget
{
    self.rootWidget = [MDMWidget createRootWidgetWithId:MDM_APPID
                                               rootPath:MDM_wwwBundleDir
                                              startPage:MDM_ROOT_FILE
                                             controller:_viewControl];
    
    return self.rootWidget == NULL?NO:YES;
}

//打开root应用
- (BOOL)openRootWidget
{
    if (self.rootWidget) {
        
        self.currentWidget = self.rootWidget;
        [self.currentWidget openRootWindow:[MDMUltil getMDMInitFrame]];
        return YES;
    }
    return NO;
}

//启动应用窗口
- (BOOL)startWidgetWithId:(NSString *)widgetId openerInfo:(NSString *)openerInfo callback:(NSString *)callback animationId:(NSUInteger)animationId duration:(CGFloat)animationDuration
{
    if (self.subWidget != nil)
        return NO;
    
    self.subWidget = [MDMWidget createSubWidgetWithId:widgetId
                                           rootWidget:self.rootWidget
                                           openerInfo:openerInfo
                                             callback:callback
                                           controller:_viewControl];
    
    [self.subWidget openRootWindow:[MDMUltil getMDMInitFrame]];
    return YES;
}

//进入应用窗口
- (void)enterSubWidgetViewWithAnimation:(NSUInteger)animationId duration:(CGFloat)animationDuration
{
    if (self.rootWidget &&
        self.rootWidget.webView &&
        self.subWidget &&
        self.subWidget.webView &&
        self.currentWidget==self.rootWidget)
    {
        self.subWidget.webView.alpha = 0.0;
        [self.subWidget.webView setHidden:NO];
        [self.viewControl.view addSubview:self.subWidget.webView];
        
        [UIView animateWithDuration:animationDuration
                              delay:0.0f
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^{
                             self.rootWidget.webView.alpha = 0.0;
                             self.subWidget.webView.alpha = 1.0;
                         }
                         completion:^(BOOL finished){
                             [self.rootWidget.webView removeFromSuperview];
                             self.rootWidget.isSwitchingView = NO;
                             self.subWidget.isSwitchingView = NO;
                             [self.subWidget.webViewArray addObject:self.subWidget.webView];
                             self.currentWidget = self.subWidget;
                             
                         }];
    }
}

//退出应用窗口
- (void)quitSubWidgetViewWithAnimation:(NSUInteger)animationId duration:(CGFloat)animationDuration
{
    if (self.rootWidget &&
        self.rootWidget.webView &&
        self.subWidget &&
        self.subWidget.webView &&
        self.currentWidget==self.subWidget)
    {
        self.rootWidget.webView.alpha = 0.0;
        [self.rootWidget.webView setHidden:NO];
        [self.viewControl.view addSubview:self.rootWidget.webView];
        
        [UIView animateWithDuration:animationDuration
                              delay:0.0f
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^{
                             self.subWidget.webView.alpha  = 0.0;
                             self.rootWidget.webView.alpha = 1.0;
                         }
                         completion:^(BOOL finished){
                             [self.subWidget.webView removeFromSuperview];
                             
                             self.rootWidget.isSwitchingView = NO;
                             self.subWidget.isSwitchingView  = NO;
                             
                             self.currentWidget = self.rootWidget;
                             
                             // 在root widget上根据subwidget的result info执行callback
                             if (self.subWidget.callback && self.subWidget.callback.length>0
                                 && self.subWidget.resultInfo && self.subWidget.resultInfo.length>0)
                             {
                                 NSString* javaScript = [NSString stringWithFormat:@"if (%@) %@('%@');", self.subWidget.callback, self.subWidget.callback,self.subWidget.resultInfo];
                                 [self.currentWidget.webView stringByEvaluatingJavaScriptFromString:javaScript];
                             }
                             
                             self.subWidget = nil;
                         }];
    }
}



@end
