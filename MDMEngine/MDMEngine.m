//
//  MDMEngine.m
//  MDMEngine
//
//  Created by 李华林 on 14/11/28.
//  Copyright (c) 2014年 李华林. All rights reserved.
//
//  MDM引擎，统一管理应用、插件，以及所有webview的交互请求

#import "MDMEngine.h"
#import "MDM.h"

static MDMEngine *_sharedEngine = nil;

@interface MDMEngine ()
{
    MDMWebViewJsBridge* _bridge;
}

@property (nonatomic, strong) MDMComdQueue    *comdQueue;   //命令处理队列
@end

@implementation MDMEngine




+(MDMEngine*)shareEngine
{
    @synchronized(self)
    {
        if (nil == _sharedEngine ) {
            _sharedEngine = [[self alloc] init];
        }
    }
    return _sharedEngine;
}

+(id)alloc
{
    @synchronized([MDMEngine class]) //线程访问加锁
    {
        NSAssert(_sharedEngine == nil, @"Attempted to allocate a second instance of a singleton.Please call +[sharedExerciseManage] method.");
        _sharedEngine  = [super alloc];
        return _sharedEngine;
    }
    return nil;
}

- (id)init
{
    self = [super init];
    if (self) {
        _comdQueue = [[MDMComdQueue alloc] init];
        _mdmPluginManage = [[MDMPluginManage alloc] init];
        _bridge = [MDMWebViewJsBridge shareBridge];
    }
    return self;
}

-(void)dealloc
{
    _comdQueue = nil;
    _mdmWidgetManage = nil;
    _mdmPluginManage = nil;
    _bridge = nil;
}

//设置主控制器,并初始化应用管理器
-(void)setMainControl:(UIViewController *)mainControl
{
    if (!mainControl) {
        return;
    }
    _mainControl = mainControl;
    if (!_mdmWidgetManage) {
        _mdmWidgetManage = [[MDMWidgetManage alloc] initWithViewControl:mainControl];
    }
}

#pragma mark - MDMEngineWebViewDelegate

//webview开始加载的代理处理
- (void) webViewDidStartLoad:(MDMWidget*)theWidget theWebView:(MDMWebView*) theWebView
{

}

//webview加载完成的代理处理
- (void) webViewDidFinishLoad:(MDMWidget*)theWidget  theWebView:(MDMWebView*) theWebView
{
//    NSHTTPCookieStorage *cookieJar = [NSHTTPCookieStorage sharedHTTPCookieStorage];
//    for (NSHTTPCookie *cookie in [cookieJar cookies]) {
//        NSLog(@"cookie:%@", cookie);
//    }
}

//webview加载失败的代理处理
- (void) webView:(MDMWebView*) theWebView curWidget:(MDMWidget*)theWidget didFailLoadWithError:(NSError*)error
{
    NSString* message = [NSString stringWithFormat:@"警告:页面载入失败: %@", [error localizedDescription]];
    NSLog(@"%@", message);
}

//webview请求时的代理处理
- (BOOL) webView:(MDMWebView*) theWebView curWidget:(MDMWidget*)theWidget shouldStartLoadWithRequest:(NSURLRequest*)request
{
    NSURL* url = [request URL];
    BOOL isMDMCmd = [[url scheme] isEqualToString:MDM_PREFIX_JSCOMMAND];
    
    if (!isMDMCmd) {
        NSString* strUrl = [url absoluteString];
        NSRange range = [strUrl rangeOfString:@".app"];
        if (range.location!=NSNotFound) {
            strUrl = [strUrl substringFromIndex:range.location+range.length];
        }
        
        NSLog(@"加载页面: %@", strUrl);
    }
    
    if (isMDMCmd) {

        NSArray* components = [[url absoluteString] componentsSeparatedByString:@":"];
        if ([components count] > 1 && [(NSString*)[components objectAtIndex:0] isEqualToString:MDM_PREFIX_JSCOMMAND]) {
            //清除JS队列中已经被接收的命令
            [_bridge webView:theWebView withJavaScript:@"tmb.queue.commands.shift();"];
            
            NSString* urlCommand = (NSString*)[components objectAtIndex:1];
            
            if (urlCommand && urlCommand.length) {
                
                [_comdQueue enqueueCmdBatch:urlCommand webView:theWebView widget:theWidget];
            }
        }
        
        return NO;
    }
    else if ([url isFileURL])
    {
        return YES;
    }
    else if ([[url scheme] isEqualToString:@"tel"])
    {
        return YES;
    }
    else if ([[url scheme] isEqualToString:@"http"])
    {
        return YES;
    }
    else if ([[url scheme] isEqualToString:@"about"])
    {
        return NO;
    }
    else if ([[url scheme] isEqualToString:@"mailto"])
    {
        return YES;
    }
    else
    {
        NSLog(@"AppDelegate::shouldStartLoadWithRequest: Received Unhandled URL %@", url);
        
        if ([[UIApplication sharedApplication] canOpenURL:url])
        {
            [[UIApplication sharedApplication] openURL:url];
        }
        else
        {
            //[[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:CDVPluginHandleOpenURLNotification object:url]];
        }
        
        return NO;
    }
    
    return YES;
}



@end
