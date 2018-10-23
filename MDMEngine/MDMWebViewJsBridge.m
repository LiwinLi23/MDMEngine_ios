//
//  MDMWebViewJsBridge.m
//  MDMEngine
//
//  Created by 李华林 on 14/11/28.
//  Copyright (c) 2014年 李华林. All rights reserved.
//
//  JS与OBJECT-C之间的桥接通信管理

#import "MDMWebViewJsBridge.h"

static MDMWebViewJsBridge *_sharedBridge = nil;

@interface MDMWebViewJsBridge()
{
    NSString* strTbmApi;
}
@end

@implementation MDMWebViewJsBridge

+(MDMWebViewJsBridge*) shareBridge
{
    @synchronized(self)
    {
        if (nil == _sharedBridge ) {
            _sharedBridge = [[self alloc] init];
        }
    }
    return _sharedBridge;
}

+(id)alloc
{
    @synchronized([MDMWebViewJsBridge class]) //线程访问加锁
    {
        NSAssert(_sharedBridge == nil, @"Attempted to allocate a second instance of a singleton.Please call +[sharedExerciseManage] method.");
        _sharedBridge  = [super alloc];
        return _sharedBridge;
    }
    return nil;
}

- (id)init
{
    self = [super init];
    if (self) {
        strTbmApi = @"";
    }
    return self;
}

-(void)dealloc
{
    _sharedBridge = nil;
}

//根据插件数据生成JS的API
-(void)generateTmbApiByPluginData:(NSDictionary*)pluginDict
{
    if (pluginDict && [pluginDict count]) {
        
        for (NSString *key in pluginDict) {
            strTbmApi = [strTbmApi stringByAppendingString:[self makePluginJsAPI:key
                                                                          method:[pluginDict[key] objectForKey:XML_MethodNode]]];
        }
    }
   
//    NSLog(@"%@\n==========================================",strTbmApi);
}

//检查是否已经注入JS桥接
- (BOOL)jsBridgeIsLoaded:(UIWebView*)webView
{
    return [[webView stringByEvaluatingJavaScriptFromString:@"typeof window.tmb"] isEqualToString:@"object"];
}

//将桥接JS注入WEBVIEW
//注意：这个JS命令采取了队列的方式来确保命令能够准确到达OBJECT-C端，当OBJE-C端收到命令后，需要清除已经执行的命令
//     使用：tmb.queue.commands.shift(); 弹出队列里的命令
//
-(void)webViewWithBaseBridge:(UIWebView*)webView;
{
    
    if ([self jsBridgeIsLoaded:webView]) {
        return;
    }
    NSString* strBaseBridge = @"";
    
    //定义TMB属性，并定义队列数组
    strBaseBridge = [strBaseBridge stringByAppendingString: @"window.tmb={queue:{commands:[],timer:null}};"];
    
    //定义EXEC执行JS函数，使用队列处理命令，并设置TIMER来循环执行命令
    strBaseBridge = [strBaseBridge stringByAppendingString: @"tmb.exec=function(){tmb.queue.commands.push(arguments);if(tmb.queue.timer==null){tmb.queue.timer=setInterval(tmb.runCommand,10)}};"];
    
    //具体执行JS命令函数，当该命令被原生系统执行后，将使用SHIFT来清除队列中已执行的命令
    strBaseBridge = [strBaseBridge stringByAppendingString: @"tmb.runCommand=function(){var arguments=tmb.queue.commands[0];if(tmb.queue.commands.length==0){clearInterval(tmb.queue.timer);tmb.queue.timer=null};"];
    strBaseBridge = [strBaseBridge stringByAppendingFormat:@"document.location='%@://'+arguments[0]};",MDM_PREFIX_JSCOMMAND];
    
    //JS参数组合
    strBaseBridge = [strBaseBridge stringByAppendingString: @"var mdmand='&';"];
    strBaseBridge = [strBaseBridge stringByAppendingString: @"function mdmParam(a){var l=a.length;var t='';if(l>0){t+='?';for(var i=0;i<l;i++){t+=encodeURIComponent(a[i]);if(i+1==l){return t};t+=mdmand}};return t};"];
    
    [self webView:webView withJavaScript:strBaseBridge];
}

//检查是否已经注入JS API
- (BOOL)jsApiIsLoaded:(UIWebView*)webView
{
    return [[webView stringByEvaluatingJavaScriptFromString:@"typeof tmbWindow"] isEqualToString:@"object"];
}

//将插件API功能注入到WEBVIEW
-(void)webViewWithPluginAPI:(UIWebView*)webView
{
    if ([self jsApiIsLoaded:webView]) {
        return;
    }
    if (strTbmApi.length > 1) {
        [self webView:webView withJavaScript:strTbmApi];
    }
}

//增加新的插件API集合
-(NSString*)makePluginJsAPI:(NSString*)strName method:(NSArray*)arrMethod;
{
    NSString* strPluginJsAPI = [NSString stringWithFormat:@"window.%@={};",strName];
    
    for (NSString* strMethod in arrMethod) {
        
        strPluginJsAPI = [strPluginJsAPI stringByAppendingString:[NSString stringWithFormat:@"%@.%@=function(){tmb.exec('%@.%@/'+mdmParam(arguments))};",strName,strMethod,strName,strMethod]];
    }
    
    return strPluginJsAPI;
}

-(NSString*)webView:(UIWebView*)webView withJavaScript:(NSString*)jsString;
{
    return [webView stringByEvaluatingJavaScriptFromString:jsString];
}


@end
