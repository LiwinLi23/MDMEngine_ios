//
//  MDMWebViewJsBridge.h
//  MDMEngine
//
//  Created by 李华林 on 14/11/28.
//  Copyright (c) 2014年 李华林. All rights reserved.
//
//  JS与OBJECT-C之间的桥接通信管理

#import <Foundation/Foundation.h>
#import "MDM.h"

@interface MDMWebViewJsBridge : NSObject

+(MDMWebViewJsBridge*)shareBridge;

//根据插件数据生成JS的API
-(void)generateTmbApiByPluginData:(NSDictionary*)pluginDict;

//将桥接JS注入WEBVIEW
-(void)webViewWithBaseBridge:(UIWebView*)webView;

//将插件API功能注入到WEBVIEW
-(void)webViewWithPluginAPI:(UIWebView*)webView;

//将JS写入指定的WEBVIEW
-(NSString*)webView:(UIWebView*)webView withJavaScript:(NSString*)jsString;


@end
