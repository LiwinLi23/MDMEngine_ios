//
//  MDMWidgetOnePlugin.m
//  MDMEngine
//
//  Created by 李华林 on 14/12/10.
//  Copyright (c) 2014年 李华林. All rights reserved.

/**************************************************************************************************/
/*                                      修改日志                                                    */
/*修改日期：2015年5月22日                                                                            */
/*修改人员：李华林                                                                                   */
/*修改内容：修改getPlatform接口，将dataType由1更改为0                                                  */
/**************************************************************************************************/
/*修改日期：2015年6月03日                                                                            */
/*修改人员：李华林                                                                                   */
/*修改内容：1、实现清除缓存接口-(void)cleanCache:(NSMutableArray*)arguments,清除JS和cookie              */
/**************************************************************************************************/

#import "MDMWidgetOnePlugin.h"
#import "MDMWidget.h"
#import "JSONKit.h"

@implementation MDMWidgetOnePlugin

/*******************************************************************************
 接口调用：tmbWidgetOne.getPlatform()
 方法说明：返回当前手机平台的类型。
 参数说明：无
 Callback方法：
    // tmbWidgetOne.cbGetPlatform(opId,dataType,data)
 　　// opId:操作ID，在此函数中不起作用，可忽略
 　　// dataType: 返回数据的数据类型为整形(值为0)
 　　// data：返回的数据，当前手机平台的类型，0为IOS，1为Android
 *******************************************************************************/
-(void)getPlatform:(NSMutableArray*)arguments
{
    [self setJsCallback:@"tmbWidgetOne.cbGetPlatform" opId:0 dataType:0 data:@"0"];
}

/*******************************************************************************
 接口调用：tmbWidgetOne.getCurrentWidgetInfo()
 方法说明：返回当前手机平台的类型。
 参数说明：无
 Callback方法：
    // tmbWidgetOne.cbGetCurrentWidgetInfo(opId,dataType,data)
 　　// opId:操作ID，在此函数中不起作用，可忽略
 　　// dataType: 返回数据的数据类型为整形(值为1)
 　　// data：返回的数据，JSON格式：{"widgetId":"xxx"," appId":"xxx"," version":"xxxx"," name":"xxx"," icon":"xxx.png"}
 *******************************************************************************/
-(void)getCurrentWidgetInfo:(NSMutableArray*)arguments
{
    NSDictionary* infoDict =[[NSBundle mainBundle] infoDictionary];
    NSString* appVersion =[infoDict objectForKey:@"CFBundleShortVersionString"];
    NSString* appName =[infoDict objectForKey:@"CFBundleDisplayName"];
    NSString* appId = [infoDict objectForKey:@"CFBundleIdentifier"];
    
    
    NSString* widgetInfo = [MDMWidget getRootWidgetInfo];
    if (widgetInfo)
    {
        NSDictionary* dict = [widgetInfo objectFromJSONString];
        NSDictionary* widgetDict = [dict objectForKey:@"widget"];
        if (widgetDict)
        {
            NSMutableDictionary* respDict = [[NSMutableDictionary alloc] initWithCapacity:3];
            
            if (appId)
                [respDict setObject:appId forKey:@"appId"];
            
            NSString* widgetId = [widgetDict objectForKey:@"appId"];
            if (widgetId)
                [respDict setObject:widgetId forKey:@"widgetId"];
            
            id icon = [widgetDict objectForKey:@"icon"];
            if (icon && [icon isKindOfClass:[NSDictionary class]])
            {
                NSString* iconString = [(NSDictionary*)icon objectForKey:@"src"];
                if (iconString && [iconString isKindOfClass:[NSString class]])
                {
                    NSRange range = [iconString rangeOfString:@"\n"];
                    if (range.location != NSNotFound)
                        iconString = [iconString substringFromIndex:(range.location+range.length)];
                    
                    [respDict setObject:iconString forKey:@"icon"];
                }
            }
            
            if (appName)
                [respDict setObject:appName forKey:@"name"];
            
            if (appVersion)
                [respDict setObject:appVersion forKey:@"version"];
            
            id desc = [widgetDict objectForKey:@"description"];
            if (desc && [desc isKindOfClass:[NSDictionary class]])
            {
                NSString* descString = [(NSDictionary *)desc objectForKey:@"text"];
                if (descString && [descString isKindOfClass:[NSString class]])
                {
                    NSRange range = [descString rangeOfString:@"\n"];
                    if (range.location != NSNotFound)
                        descString = [descString substringFromIndex:(range.location+range.length)];
                    
                    [respDict setObject:descString forKey:@"description"];
                }
            }
            
            id updateURL = [widgetDict objectForKey:@"updateurl"];
            if (updateURL && [updateURL isKindOfClass:[NSDictionary class]])
            {
                NSString* urlString = [(NSDictionary *)updateURL objectForKey:@"text"];
                if (urlString && [urlString isKindOfClass:[NSString class]])
                {
                    NSRange range = [urlString rangeOfString:@"\n"];
                    if (range.location != NSNotFound)
                        urlString = [urlString substringFromIndex:(range.location+range.length)];
                    
                    [respDict setObject:urlString forKey:@"updateurl"];
                }
            }
            
            [self setJsCallback:@"tmbWidgetOne.cbGetCurrentWidgetInfo" opId:0 dataType:1 data:[respDict JSONString]];
        }
    }
}

/*******************************************************************************
 接口调用：tmbWidgetOne.getMainWidgetId()
 方法说明：获取主widget的appId。
 参数说明：无
 Callback方法：
    // tmbWidgetOne.cbGetMainWidgetId(opId,dataType,data)
 　　// opId:操作ID，在此函数中不起作用，可忽略
 　　// dataType: 返回数据的数据类型为整形(值为1)
 　　// data：返回主widget的appId
 *******************************************************************************/
-(void)getMainWidgetId:(NSMutableArray*)arguments
{
    NSDictionary* infoDict =[[NSBundle mainBundle] infoDictionary];
    NSString* appId = [infoDict objectForKey:@"CFBundleIdentifier"];
    
    [self setJsCallback:@"tmbWidgetOne.cbGetMainWidgetId" opId:0 dataType:1 data:appId];
}

/*******************************************************************************
 接口调用：tmbWidgetOne.getPushMsg()
 方法说明：获得推送消息。
 参数说明：无
 Callback方法：
    // tmbWidgetOne.cbGetPushMsg(opId,dataType,data)
 　　// opId:操作ID，在此函数中不起作用，可忽略
 　　// dataType: 返回数据的数据类型为整形(值为1)
 　　// data：返回PushMsg
 *******************************************************************************/
-(void)getPushMsg:(NSMutableArray*)arguments
{
    NSLog(@"call tmbWidgetOne.getPushMsg");

}

/*******************************************************************************
 接口调用：tmbWidgetOne.deletePushMsg(inIndex)
 方法说明：删除推送消息中的一条。
 参数说明：
    // inIndex:索引Key
 Callback方法：无
 *******************************************************************************/
-(void)deletePushMsg:(NSMutableArray*)arguments
{
    NSLog(@"call tmbWidgetOne.deletePushMsg");

}

/*******************************************************************************
 接口调用：tmbWidgetOne.cleanCache()
 方法说明：清除当前widgetOne的所有cache。
 参数说明：无
 Callback方法：
    // tmbWidgetOne.cbCleanCache(opId,dataType,data)
 　　// opId:操作ID，在此函数中不起作用，可忽略
 　　// dataType: 返回数据的数据类型为整形(值为1)
 　　// data：返回的数据，0成功或1失败
 *******************************************************************************/
-(void)cleanCache:(NSMutableArray*)arguments
{
    /************henry start***********/
   [[NSURLCache sharedURLCache] removeAllCachedResponses];
    for(NSHTTPCookie *cookie in [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookies]) {
        [[NSHTTPCookieStorage sharedHTTPCookieStorage] deleteCookie:cookie];
    }
    /************henry end***********/
   [self setJsCallback:@"tmbWidgetOne.cbCleanCache" opId:0 dataType:1 data:@"0"];
}

/*******************************************************************************
 接口调用：tmbWidgetOne.exit()
 方法说明：退出应用程序。
 参数说明：无
 Callback方法：无
 *******************************************************************************/
-(void)exit:(NSMutableArray*)arguments
{
    exit(0);
}
@end
