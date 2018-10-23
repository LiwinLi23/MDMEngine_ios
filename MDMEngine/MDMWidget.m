//
//  MDMWidget.m
//  MDMEngine
//
//  Created by 李华林 on 14/11/28.
//  Copyright (c) 2014年 李华林. All rights reserved.
//
//  应用定义（应用：表示一个具体的窗口，在这里我们使用Widget来表示）
//

#import "MDMWidget.h"

@interface MDMWidget()


@property(nonatomic, weak) UIViewController* viewController;
@property(nonatomic, strong) MDMWebView* theNewWebView;
@property(nonatomic, strong) MDMWebView* backgroundWebView;

@property(nonatomic, strong) NSMutableDictionary *webViewNameDict;          // widget所含窗口的"名称-对象"字典
@property(nonatomic, strong) NSMutableDictionary *unusedWebViewNameDict;    // widget所含的不在"名称-对象"字典
@end

@implementation MDMWidget

- (MDMWidget *)initWidgetWith:(NSString *)widgetId
{
    if (self = [self init])
    {
        self.widgetId = widgetId;
        self.webViewArray = [[NSMutableArray alloc] initWithCapacity:3];
        self.webViewNameDict = [[NSMutableDictionary alloc] initWithCapacity:3];
        self.unusedWebViewNameDict = [[NSMutableDictionary alloc] initWithCapacity:3];
        self.webView = nil;
        self.isSwitchingView = NO;
        self.engineDelegate  = [MDMEngine shareEngine];
    }
    return self;
}

- (void)dealloc
{
    _widgetId = nil;
    _openerInfo = nil;
    _callback = nil;
    _rootPath = nil;
    _startPage = nil;
    
    [_webViewArray removeAllObjects];
    _webViewArray = nil;
    [_webViewNameDict removeAllObjects];
    _webViewNameDict = nil;
    [_unusedWebViewNameDict removeAllObjects];
    _unusedWebViewNameDict = nil;
    
    _webView = nil;
    _theNewWebView = nil;
    _rootWidget = nil;
    _viewController = nil;
    _backgroundWebView = nil;
}

#pragma mark - url management

- (NSString *)baseURLFromURLString:(NSString *)URLString
{
    NSRange range = [URLString rangeOfString:@"?"];
    NSString* baseURL = nil;
    
    if (range.location != NSNotFound)
        baseURL = [URLString substringToIndex:range.location];
    else
        baseURL = [NSString stringWithString:URLString];
    return baseURL;
}

- (NSURL *)urlFromString:(NSString *)urlString relativeToURL:(NSURL *)relativeURL
{
    if (urlString == nil)
        return nil;
    
    if ([urlString hasPrefix:@"http://"]==YES || [urlString hasPrefix:@"file://"]==YES)
    {
        return [NSURL URLWithString:[urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    }
    else if ([urlString hasPrefix:@"/"])
    {
        NSArray* pathArray = [urlString pathComponents];
        NSMutableString* path = [[NSMutableString alloc] init];
        for(NSUInteger i=0,j=0; i<[pathArray count]; i++)
        {
            NSString* str = [pathArray objectAtIndex:i];
            if ([str isEqual:@"/"])
                continue;
            (j>0) ? [path appendFormat:@"/%@",str] : [path appendString:str];
            j++;
        }

        NSString* baseURLString = [NSString stringWithFormat:@"file://localhost%@", self.rootPath];
        return [NSURL URLWithString:[baseURLString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    }
    else
    {
        if (relativeURL != nil)
        {
            return [NSURL URLWithString:[urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding] relativeToURL:relativeURL];
        }
        else
        {
            return [NSURL URLWithString:[urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
        }
    }
}

#pragma mark - Widget creat

//创建根应用
+ (MDMWidget *)createRootWidgetWithId:(NSString *)widgetId
                             rootPath:(NSString *)rootPath
                            startPage:(NSString *)startPage
                           controller:(UIViewController *)viewController
{
    if (widgetId == nil || viewController == nil)
        return nil;
    
    MDMWidget *widget = [[MDMWidget alloc] initWidgetWith:widgetId];
    
    widget.rootPath     = rootPath;
    widget.startPage    = startPage;
    widget.openerInfo   = nil;
    widget.isSubWidget  = NO;
    
    widget.viewController  = viewController;
    widget.engineDelegate  = [MDMEngine shareEngine];
    
    return widget;
}

//创建子应用
+ (MDMWidget *)createSubWidgetWithId:(NSString *)widgetId
                          rootWidget:(MDMWidget*)rootWidget
                          openerInfo:(NSString *)openerInfo
                            callback:(NSString *)callback
                          controller:(UIViewController *)viewController
{
    if (widgetId == nil || viewController == nil)
        return nil;
    
    MDMWidget *widget = [[MDMWidget alloc] initWidgetWith:widgetId];
    widget.isSubWidget = YES;
    widget.rootWidget  = rootWidget;
    
    
    widget.callback    = callback;
    widget.rootPath    = [MDMWidget wwwPathOfSubWidget:widgetId createIfNotExist:YES];
    widget.startPage   = MDM_ROOT_FILE;
    widget.openerInfo  = openerInfo;
    widget.viewController = viewController;
    widget.engineDelegate  = [MDMEngine shareEngine];
    
    return widget;
}

#pragma mark - Widget windows management

//创建窗口框架，生成webview对象，并预加载，但未附加到主视图之上
- (void)openRootWindow:(CGRect)frame
{
    NSString* startFilePath = (self.rootPath && self.startPage) ? [NSString stringWithFormat:@"%@/%@", self.rootPath, self.startPage] : nil;
    NSURL*    appURL  = nil;
    NSString* loadErr = nil;
    
    
    if (!startFilePath || ![MDM_FileMag fileExistsAtPath:startFilePath])
    {
        appURL = [NSURL URLWithString:[[[NSBundle mainBundle] infoDictionary] objectForKey:@"DefaultURL"]];
        
        loadErr = [NSString stringWithFormat:@"错误:没有找到主页:'%@/%@'", self.rootPath, self.startPage];
        MDMAlert(@"提示", loadErr);
    }
    else
    {
        NSString* urlString = [NSString stringWithFormat:@"file://localhost%@", startFilePath];
        appURL = [NSURL URLWithString:[urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    }
    
    self.webView = [self createWebViewWithName:MDM_ROOT_WindowName
                                         frame:frame
                                   animationId:cWindowAnimiIDNone
                                      duration:0.0f];
    
    NSURLRequest *appReq = [NSURLRequest requestWithURL:appURL
                                            cachePolicy:NSURLRequestUseProtocolCachePolicy
                                        timeoutInterval:20.0];
    [self.webView loadRequest:appReq];
    self.webView.baseURL = [NSURL URLWithString:[self baseURLFromURLString:[appURL absoluteString]]];
}

//创建子视图,并预加载，但未附加到视图之上
- (void)openWindow:(NSString *)windowName
          withData:(NSString *)urlData
            ofType:(NSUInteger)dataType
             frame:(CGRect)frame
       animationId:(AnimateID)animationId
          duration:(CGFloat)animationDuration
              flag:(NSUInteger)flag
{
    if (self.isSwitchingView == NO  &&  [self.webView.windowName isEqualToString:windowName] == NO)
    {
        MDMWebView* newWebView = [self createWebViewWithName:windowName
                                                       frame:frame
                                                 animationId:animationId
                                                    duration:animationDuration];
        if (newWebView)
        {
            NSString* data = [urlData stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            self.isSwitchingView = YES;
            
            switch(dataType)
            {
                case 0: // url方式载入
                {
                    NSURL *reqURL = [self urlFromString:urlData relativeToURL:self.webView.baseURL];
                    newWebView.baseURL = [NSURL URLWithString:[self baseURLFromURLString:[reqURL absoluteString]]];
                    NSURLRequest *urlReq = [NSURLRequest requestWithURL:reqURL cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:20.0];
                    [newWebView loadRequest:urlReq];
                    break;
                }
                case 1: // html内容方式载入
                {
                    NSURL* reqURL = [NSURL fileURLWithPath:self.rootPath];
                    newWebView.baseURL = [NSURL URLWithString:[self baseURLFromURLString:[reqURL absoluteString]]];
                    [newWebView loadHTMLString:data baseURL:reqURL];
                    break;
                }
                    
                case 2: // 既有url方式，又有html内容方式
                {
                    NSError* err = nil;
                    NSURL *reqURL = [self urlFromString:urlData relativeToURL:self.webView.baseURL];
                    NSString* htmlString = [NSString stringWithContentsOfURL:reqURL encoding:NSUTF8StringEncoding error:&err];
                    if (htmlString && data)
                    {
                        NSMutableString* mutableHtmlString = [NSMutableString stringWithString:htmlString];
                        [mutableHtmlString appendString:data];
                        [mutableHtmlString appendString:@"</body></html>"];
                        [newWebView loadHTMLString:mutableHtmlString baseURL:reqURL];
                    }
                    break;
                }
            }
        }
    }
}

// 用窗口名作为参数从当前widget的窗口列表中(webViewArray)查找存在于内存中的窗口
- (MDMWebView*)webViewWithName:(NSString*)windowName
{
    if (!windowName && [windowName length]>0)
    {
        MDMWebView* theWebView = (MDMWebView*)[self.webViewNameDict objectForKey:windowName];
        if (!theWebView)
            theWebView = (MDMWebView *)[self.unusedWebViewNameDict objectForKey:windowName];
        return theWebView;
    }
    else
    {
        return self.webView;
    }
}

//后台运行WEBVIEW
- (void)webView:(UIWebView *)webView loadBackgroundService:(NSString *)urlString
{
    if (urlString == nil)
        return;
    
    if (self.backgroundWebView == nil)
    {
        MDMWebView* theWebView = [[MDMWebView alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
        theWebView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
        theWebView.delegate = self;
        theWebView.viewController = self.viewController;
        theWebView.widget = self;
        theWebView.windowName = MDM_BG_Serv;
        theWebView.isBackground = YES;
        theWebView.windowType = kWindowTypeBackground;
        
        self.backgroundWebView = theWebView;
    }
    [self.backgroundWebView setHidden:YES];
    
    NSURL* reqURL = [self urlFromString:urlString relativeToURL:((MDMWebView *)webView).baseURL];
    NSURLRequest* req = [NSURLRequest requestWithURL:reqURL cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:20.0];
    
    [self.backgroundWebView loadRequest:req];
}

-(void)switchToWebView:(MDMWebView*)newWebView
           animationId:(NSUInteger)animationId
              duration:(NSTimeInterval)animationDuration
                isBack:(BOOL)isBack
{
    self.isBack = isBack;
    
    self.theNewWebView = newWebView;
    [self.theNewWebView setHidden:NO];
    [self.viewController.view addSubview:self.theNewWebView];
    
    CATransition *animation = [CATransition animation];
    animation.delegate = self;
    animation.duration = animationDuration;
    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    animation.fillMode = kCAFillModeForwards;
    animation.type = kCATransitionFade;
    
    [self.viewController.view.layer addAnimation:animation forKey:@"animation"];
}

-(void) animationDidStop:(CAAnimation *)anim finished:(BOOL)flag
{
    UIView* tempView = self.webView;
    self.webView = nil;
    
    self.webView = self.theNewWebView;
    self.theNewWebView = nil;
    
    [tempView removeFromSuperview];
    if (self.isBack)
    {
        [self.unusedWebViewNameDict setObject:(MDMWebView*)tempView forKey:((MDMWebView*)tempView).windowName];
        
        [self.webViewArray    removeObject:tempView];
        [self.webViewNameDict removeObjectForKey:((MDMWebView*)tempView).windowName];
        
        self.isBack = NO;
        
        NSString *tmbJsCommand = [NSString stringWithFormat:@"if (tmbWindow.cbGoBack) tmbWindow.cbGoBack();"];
        [self.webView stringByEvaluatingJavaScriptFromString:tmbJsCommand];
    }
    
    self.isSwitchingView = NO;
    
    // 延迟打开消息列表
    if (self.shouldOpenMessageListView)
    {
        self.shouldOpenMessageListView = NO;
        [self openPushMessageListWindow];
    }
    return;
}

//将webview对象附加主视图之上
- (void)showWebView:(MDMWebView*)theNewWebView
{
    if (!theNewWebView)
        return;
    
    @try {
        if ([self.webViewArray count] == 0)
        {
            if ([theNewWebView.windowName isEqualToString:MDM_ROOT_WindowName])
            {
                if (self.isSubWidget)
                {
                    self.isSwitchingView = YES;
                    self.rootWidget.isSwitchingView = YES;
                    [[MDMEngine shareEngine].mdmWidgetManage enterSubWidgetViewWithAnimation:0 duration:0.25f];
                }
                else
                {
                    [theNewWebView setHidden:NO];
                    [self.viewController.view addSubview:theNewWebView];
                    [self.webViewArray addObject:theNewWebView];
                    self.isSwitchingView = NO;
                    NSLog(@"打开ROOT应用成功!");
                }
            }
        }
        else if ([self.webViewArray count] > 0)
        {
            if ([self.webView.windowName isEqualToString:theNewWebView.windowName] == NO)
            {
                // maintain the view stack
                BOOL exist = NO;
                int index = (int)[self.webViewArray count] - 1;
                
                while(index>=0)
                {
                    MDMWebView* view = [self.webViewArray objectAtIndex:index];
                    
                    if ([view.windowName isEqualToString:theNewWebView.windowName] == YES)
                    {
                        exist = YES;
                        break;
                    }
                    index--;
                }
                
                if (exist)
                {
                    int toRemoveNum = (int)[self.webViewArray count] - index - 2;
                    for(int i=0; i<toRemoveNum; i++)
                    {
                        index = (int)[self.webViewArray count] - 2;
                        UIWebView* tempView = [self.webViewArray objectAtIndex:index];
                        [self.webViewArray removeObjectAtIndex:index];
                        
                        [tempView setHidden:YES];
                        [tempView removeFromSuperview];
                    }
                    [self.webViewArray removeObject:self.webView];
                }
                else
                {
                    [self.webViewArray addObject:theNewWebView];
                }
                
                if ([theNewWebView.windowName isEqualToString:MDM_ROOT_WindowName] == NO)
                {
                    [self switchToWebView:theNewWebView animationId:0 duration:0.3f isBack:NO];
                }
                else
                {
                    self.isSwitchingView = NO;
                    
                    UIWebView* tempView = self.webView;
                    [self.viewController.view addSubview:theNewWebView];
                    [theNewWebView setHidden:NO];
                    self.webView = theNewWebView;
                    
                    [tempView removeFromSuperview];
                    
                    // 延迟打开消息列表
                    if (self.shouldOpenMessageListView)
                    {
                        [self openPushMessageListWindow];
                        self.shouldOpenMessageListView = NO;
                    }
                }
            }
        }
    }
    @catch (NSException *exception) {
        
        MDMAlert(@"运行异常", exception.reason);
    }
    @finally {
        
    }
}

//关闭webview
- (void)closeWebView
{
    NSUInteger count = [self.webViewArray count];
    
    if (count == 1)
    {
        if (self.isSubWidget)
        {
            self.isSwitchingView = YES;
            self.rootWidget.isSwitchingView = YES;
            [[MDMEngine shareEngine].mdmWidgetManage quitSubWidgetViewWithAnimation:0 duration:0.25f];
        }
        else
        {
            // 返回淡入淡出效果
            NSUInteger vcCount = [[[self.viewController navigationController] viewControllers] count];
            if (vcCount > 1)
            {
                CATransition* animation = [CATransition animation];
                animation.delegate = self;
                animation.duration = 0.3f;
                animation.type = kCATransitionFade;
                [[self.viewController navigationController] performSelector:@selector(popViewControllerAnimated:)
                                                                 withObject:nil
                                                                 afterDelay:0.1];
                
                [[self.viewController navigationController].view.layer addAnimation:animation
                                                                             forKey:@"animation"];
            }
        }
    }
    else if (count > 1)
    {
        if (self.isSwitchingView == NO)
        {
            self.isSwitchingView = YES;
            MDMWebView* lastWebView = (MDMWebView*)[self.webViewArray objectAtIndex:([self.webViewArray count] - 2)];
            UIWebView* tempView = self.webView;
            [self switchToWebView:lastWebView animationId:0 duration:0.3f isBack:YES];
            [self.webViewArray removeObject:tempView];
        }
    }
}

//创建MDMWEBVIEW
- (MDMWebView*)createWebViewWithName:(NSString*)windowName
                               frame:(CGRect)frame
                         animationId:(AnimateID)animationId
                            duration:(CGFloat)animationDuration
{
    if (!windowName)
        return nil;
    
    MDMWebView* theWebView = (MDMWebView*)[self.webViewNameDict objectForKey:windowName];
    
    if (!theWebView)
        theWebView = (MDMWebView*)[self.unusedWebViewNameDict objectForKey:windowName];
    
    if (!theWebView)
    {
        theWebView = [[MDMWebView alloc] initWithFrame:frame];
        theWebView.autoresizesSubviews = YES;
        theWebView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
        theWebView.delegate = self;
        theWebView.viewController = self.viewController;
        theWebView.widget = self;
        theWebView.windowName = windowName;
        theWebView.animateID  = animationId;
        theWebView.isBackground = NO;
        theWebView.windowType = kWindowTypeWindow;
        theWebView.scrollView.bounces = NO;
        
        //加入到视图队列中
        [self.webViewNameDict setObject:theWebView forKey:windowName];
    }
    else
    {
        [self.webViewNameDict setObject:theWebView forKey:windowName];
        [self.unusedWebViewNameDict removeObjectForKey:windowName];
    }
    return theWebView;
}

- (void)openPushMessageListWindow
{
    if (self.isSubWidget == NO)
    {
        NSString* jsString = @"if(startFromWhere) startFromWhere();";
        if (self.webView)
        {
            if (self.isSwitchingView == NO)
                [self.webView stringByEvaluatingJavaScriptFromString:jsString];
            else
                self.shouldOpenMessageListView = YES;
        }
    }
}


#pragma mark - UIWebViewDelegate methods

- (void) webViewDidStartLoad:(UIWebView*)theWebView
{
    SEL sentAction = @selector(webViewDidStartLoad:theWebView:);
    if(_engineDelegate && [_engineDelegate respondsToSelector:sentAction])
    {
        [self.engineDelegate webViewDidStartLoad:self theWebView:(MDMWebView*)theWebView];
    }
    return;
}

- (void) webViewDidFinishLoad:(UIWebView*)theWebView
{
    //注入JS桥接
    [[MDMWebViewJsBridge shareBridge] webViewWithBaseBridge:theWebView];
    //注入JS API
    [[MDMWebViewJsBridge shareBridge] webViewWithPluginAPI:theWebView];
    
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    
    // 通知js框架web内容调入完成
    [theWebView stringByEvaluatingJavaScriptFromString:@"if(window.tmbOnload) window.tmbOnload(0);"];
    
    //通知engine进一步处理web页面载入事件
    SEL sentAction = @selector(webViewDidFinishLoad:theWebView:);
    if(_engineDelegate && [_engineDelegate respondsToSelector:sentAction])
    {
        [self.engineDelegate webViewDidFinishLoad:self theWebView:(MDMWebView*)theWebView];
    }
    
    //打开已载入的页面窗口
    if ([theWebView isKindOfClass:[MDMWebView class]] && ((MDMWebView*)theWebView).isBackground == NO)
    {
        [self showWebView:(MDMWebView*)theWebView];
    }
    return;
}

- (void) webView:(UIWebView*)theWebView didFailLoadWithError:(NSError*)error
{
    NSLog(@"警告:加载页面失败(%@)", [error localizedDescription]);
    
    self.isSwitchingView = NO;

    SEL sentAction = @selector(webView:curWidget:didFailLoadWithError:);
    if(_engineDelegate && [_engineDelegate respondsToSelector:sentAction])
    {
        [self.engineDelegate webView:(MDMWebView*)theWebView curWidget:self didFailLoadWithError:error];
    }
    
    
    if ([theWebView isKindOfClass:[MDMWebView class]] && !((MDMWebView*)theWebView).isBackground)
    {
        if ([((MDMWebView *)theWebView).windowName isEqualToString:MDM_ROOT_WindowName] == YES)
            [self.viewController.view addSubview:theWebView];
    }
    
    if ([theWebView isKindOfClass:[MDMWebView class]] && ((MDMWebView*)theWebView).isBackground == NO)
    {
        // 延迟打开消息列表
        if (self.shouldOpenMessageListView)
        {
            [self openPushMessageListWindow];
            self.shouldOpenMessageListView = NO;
        }
    }
}

- (BOOL) webView:(UIWebView*)theWebView shouldStartLoadWithRequest:(NSURLRequest*)request navigationType:(UIWebViewNavigationType)navigationType
{
    BOOL bShould   = NO;
    SEL sentAction = @selector(webView:curWidget:shouldStartLoadWithRequest:);
    if(_engineDelegate && [_engineDelegate respondsToSelector:sentAction])
    {
        bShould = [self.engineDelegate webView:(MDMWebView*)theWebView curWidget:self shouldStartLoadWithRequest:request];
    }

    return bShould;
}

#pragma mark - system path management

// 子widget的wwww目录. 由于有的安装包会自行创建www目录而不是把数据安装在子widget的根目录下，才增加此函数
+ (NSString *)wwwPathOfSubWidget:(NSString *)widgetId createIfNotExist:(BOOL)createIfNotExist
{
    NSString* documentPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString* toAddPathComponent = [NSString stringWithFormat:@"apps/plugins/%@", widgetId];
    
    NSString* widgetPath = [documentPath stringByAppendingPathComponent:toAddPathComponent];
    if (createIfNotExist) [MDMWidget ensurePathExist:widgetPath];
    
    NSString* widgetPath2 = [widgetPath stringByAppendingPathComponent:@"www"];
    
    // 如果存在www，则增加www作为子widget的root
    BOOL isPath = NO;
    BOOL pathExist = [[NSFileManager defaultManager] fileExistsAtPath:widgetPath2 isDirectory:&isPath];
    
    if (pathExist && isPath)  widgetPath = widgetPath2;
    if (createIfNotExist)  [MDMWidget ensurePathExist:widgetPath];
    
    return widgetPath;
}

+ (NSString *)rootPathOfSubWidget:(NSString *)widgetId createIfNotExist:(BOOL)createIfNotExist
{
    NSString* documentPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString* toAddPathComponent = [NSString stringWithFormat:@"apps/plugins/%@", widgetId];
    
    NSString* widgetPath = [documentPath stringByAppendingPathComponent:toAddPathComponent];
    
    if (createIfNotExist) [MDMWidget ensurePathExist:widgetPath];
    
    return widgetPath;
}

//是否存在路径，如不存在，创建该文件夹
+ (void)ensurePathExist:(NSString *)path
{
    NSFileManager *fileMgr = [NSFileManager defaultManager];
    BOOL isPath = NO;
    BOOL pathExist = [fileMgr fileExistsAtPath:path isDirectory:&isPath];
    if(!(pathExist && isPath))
        [fileMgr createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
}

- (NSString *)resourcePath
{
    NSString *resPath = [_rootPath stringByAppendingPathComponent:@"wgtRes"];
    return resPath;
}
- (NSString *)sandboxPath
{
    NSString* documentPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString* toAddPathComponent = [NSString stringWithFormat:@"apps/%@/box/", self.widgetId];
    NSString* boxPath = [documentPath stringByAppendingPathComponent:toAddPathComponent];
    [MDMWidget ensurePathExist:boxPath];
    
    return boxPath;
}

- (NSString *)photoPath
{
    NSString* boxPath = [self sandboxPath];
    NSString* path = [boxPath stringByAppendingPathComponent:@"photo"];
    [MDMWidget ensurePathExist:path];
    return path;
}
- (NSString *)audioPath
{
    NSString* boxPath = [self sandboxPath];
    NSString* path = [boxPath stringByAppendingPathComponent:@"audio"];
    [MDMWidget ensurePathExist:path];
    return path;
}
- (NSString *)videoPath
{
    NSString* boxPath = [self sandboxPath];
    NSString* path = [boxPath stringByAppendingPathComponent:@"video"];
    [MDMWidget ensurePathExist:path];
    return path;
}
- (NSString *)dataPath
{
    NSString* boxPath = [self sandboxPath];
    NSString* path = [boxPath stringByAppendingPathComponent:@"data"];
    [MDMWidget ensurePathExist:path];
    return path;
}
- (NSString *)myspacePath
{
    NSString* boxPath = [self sandboxPath];
    NSString* path = [boxPath stringByAppendingPathComponent:@"myspace"];
    [MDMWidget ensurePathExist:path];
    return path;
}

- (NSString *)pathFromSchemePath:(NSString *)schemePath
{
    NSRange range = [schemePath rangeOfString:@"wgt://"];
    if (range.location != NSNotFound)
    {
        NSString* path = [self.rootPath stringByAppendingPathComponent:[schemePath substringFromIndex:range.length]];
        NSString* pathExtension = [path pathExtension];
        if ([pathExtension length] > 0)
            return path;
        else
            return [NSString stringWithFormat:@"%@/",path];
    }
    
    range = [schemePath rangeOfString:@"res://"];
    if (range.location != NSNotFound)
    {
        NSString* path = [[self resourcePath] stringByAppendingPathComponent:[schemePath substringFromIndex:range.length]];
        return path;
    }
    
    range = [schemePath rangeOfString:@"box://"];
    if (range.location != NSNotFound)
    {
        NSString* path = [[self sandboxPath] stringByAppendingPathComponent:[schemePath substringFromIndex:range.length]];
        return path;
    }
    
    return schemePath;
}

+ (BOOL)isSubWidgetInstalled:(NSString *)widgetId
{
    NSString* widgetPath = [MDMWidget wwwPathOfSubWidget:widgetId createIfNotExist:NO];
    NSString* startPage = [widgetPath stringByAppendingPathComponent:MDM_ROOT_FILE];
    NSFileManager* fileMgr = [NSFileManager defaultManager];
    BOOL isPath = NO;
    BOOL pathExist = [fileMgr fileExistsAtPath:widgetPath isDirectory:&isPath];
    if (pathExist && isPath)
    {
        isPath = NO;
        pathExist = [fileMgr fileExistsAtPath:startPage isDirectory:&isPath];
        if (pathExist && isPath==NO)
            return YES;
    }
    return NO;
}

+ (NSString *)getRootWidgetInfo
{
    return nil;
}
+ (NSString *)getSubWidgetInfo:(NSString *)widgetId
{
    return nil;
}


@end
