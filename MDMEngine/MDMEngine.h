//
//  MDMEngine.h
//  MDMEngine
//
//  Created by 李华林 on 14/11/28.
//  Copyright (c) 2014年 李华林. All rights reserved.
//
//  MDM引擎，统一管理应用、插件，以及所有webview的交互请求

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import "MDMViewController.h"

@class MDMWidget;
@class MDMWebView;
@class MDMWidgetManage;
@class MDMPluginManage;

//webview交互代理，通过代理的方式，在这里集中处理所有的WEB交互请求
@protocol MDMEngineWebViewDelegate <NSObject>

//webview开始加载的代理处理
- (void) webViewDidStartLoad:(MDMWidget*)theWidget theWebView:(MDMWebView*) theWebView;

//webview加载完成的代理处理
- (void) webViewDidFinishLoad:(MDMWidget*)theWidget  theWebView:(MDMWebView*) theWebView;

//webview加载失败的代理处理
- (void) webView:(MDMWebView*)theWebView curWidget:(MDMWidget*)theWidget didFailLoadWithError:(NSError*)error;

//webview请求时的代理处理
- (BOOL) webView:(MDMWebView*)theWebView curWidget:(MDMWidget*)theWidget shouldStartLoadWithRequest:(NSURLRequest*)request;
@end

@interface MDMEngine : NSObject<MDMEngineWebViewDelegate>

@property (nonatomic, weak) UIViewController*     mainControl;         //主控制器
@property (nonatomic, strong) MDMWidgetManage*      mdmWidgetManage;     //应用管理器
@property (nonatomic, strong) MDMPluginManage*      mdmPluginManage;     //插件管理器

+(MDMEngine*)shareEngine;

@end
