//
//  MDMWidget.h
//  MDMEngine
//
//  Created by 李华林 on 14/11/28.
//  Copyright (c) 2014年 李华林. All rights reserved.
//
//  应用定义（应用：表示一个具体的窗口，在这里我们使用Widget来表示）
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import "MDM.h"
#import "MDMEngine.h"

@interface MDMWidget : NSObject<UIWebViewDelegate>

@property (nonatomic, weak) id<MDMEngineWebViewDelegate> engineDelegate;

@property (nonatomic, copy  ) NSString                 *openerInfo;

@property (nonatomic, copy  ) NSString                 *callback;
@property (nonatomic, copy  ) NSString                 * resultInfo;

@property (nonatomic, assign) BOOL                     isSwitchingView;
@property (nonatomic, assign) BOOL                     shouldOpenMessageListView;
@property (nonatomic, assign) BOOL                     isBack;

@property (nonatomic, copy  ) NSString                 *rootPath;
@property (nonatomic, copy  ) NSString                 *startPage;
@property (nonatomic, strong) MDMWebView               * webView;

@property (nonatomic, assign) BOOL                     isSubWidget;

@property (nonatomic, copy  ) NSString                 *widgetId;
@property (nonatomic, weak  ) MDMWidget                *rootWidget;

@property (nonatomic, strong) NSMutableArray           *webViewArray;// widget所含的窗口队列


//创建根应用
+ (MDMWidget *)createRootWidgetWithId:(NSString *)widgetId
                             rootPath:(NSString *)rootPath
                            startPage:(NSString *)startPage
                           controller:(UIViewController *)viewController ;
//创建子应用
+ (MDMWidget *)createSubWidgetWithId:(NSString *)widgetId
                          rootWidget:(MDMWidget*)rootWidget
                          openerInfo:(NSString *)openerInfo
                            callback:(NSString *)callback
                          controller:(UIViewController *)viewController;

//创建窗口框架，生成webview对象，并预加载，但未附加到主视图之上
- (void)openRootWindow:(CGRect)frame;

//创建子视图,并预加载，但未附加到视图之上
- (void)openWindow:(NSString *)windowName
          withData:(NSString *)urlData
            ofType:(NSUInteger)dataType
             frame:(CGRect)frame
       animationId:(AnimateID)animationId
          duration:(CGFloat)animationDuration
              flag:(NSUInteger)flag;

// 用窗口名作为参数从当前widget的窗口列表中(webViewArray)查找存在于内存中的窗口
- (MDMWebView*)webViewWithName:(NSString*)windowName;

//后台运行WEBVIEW
- (void)webView:(UIWebView *)webView loadBackgroundService:(NSString *)urlString;

//将webview对象附加主视图之上
- (void)showWebView:(MDMWebView*)theNewWebView;

//关闭webview
- (void)closeWebView;

//创建MDMWEBVIEW
- (MDMWebView*)createWebViewWithName:(NSString*)windowName
                               frame:(CGRect)frame
                         animationId:(AnimateID)animationId
                            duration:(CGFloat)animationDuration;

- (void)openPushMessageListWindow;

+ (void)ensurePathExist:(NSString *)path;
+ (NSString *)rootPathOfSubWidget:(NSString *)widgetId createIfNotExist:(BOOL)createIfNotExist;
- (NSString *)resourcePath;
- (NSString *)sandboxPath;

- (NSString *)photoPath;
- (NSString *)audioPath;
- (NSString *)videoPath;
- (NSString *)dataPath;
- (NSString *)myspacePath;

- (NSString *)pathFromSchemePath:(NSString *)schemePath;
+ (BOOL)isSubWidgetInstalled:(NSString *)widgetId;

+ (NSString *)getRootWidgetInfo;
+ (NSString *)getSubWidgetInfo:(NSString *)widgetId;

@end
