//
//  MDMWidgetPlugin.m
//  MDMEngine
//
//  Created by 李华林 on 14/12/10.
//  Copyright (c) 2014年 李华林. All rights reserved.
//

#import "MDMWidgetPlugin.h"
#import "MDMEngine.h"
#import "MDMWidgetManage.h"
#import "MDMWebView.h"

@implementation MDMWidgetPlugin


/*******************************************************************************
 接口调用：tmbWidget.startWidget(inWgtId,inAnimiId,inCallback,inInfo,animDuration)
 方法说明：加载一个新的widget。
 参数说明：
    // inWgtId：widget的APPID。
    // inAnimiId：widget载入时的动画id，详见常量表的Window Animi ID。
    // inCallback：加载新的widget结束时的回调函数，可为空。
    // inInfo：加载新的widget时，传给新widget的信息，在新widget中获取此Widget的info见tmbWidget.getOpenerInfo函数,可为空。
    // animDuration:动画持续时长，单位为毫秒，默认250毫秒.
 Callback方法：
    // tmbWidget.cbStartWidget(opId,dataType,data)
    // opId: 操作ID。在此函数中不起作用，可忽略。
    // dataType: 返回数据的数据类型为整形(值为2)。
    // data: 返回的数据，0为成功，1为失败，2为不存在此widget。
 *******************************************************************************/
-(void)startWidget:(NSMutableArray*)arguments
{
    NSString* widgetId    = JSGetArgmForString([arguments objectAtIndex:0]);
    NSInteger animationId = [JSGetArgmForNumber([arguments objectAtIndex:1])  integerValue];
    NSString* callback    = JSGetArgmForString([arguments objectAtIndex:2]);
    NSString* openerInfo  = JSGetArgmForString([arguments objectAtIndex:3]);
    NSInteger duration    = [JSGetArgmForNumber([arguments objectAtIndex:4])  integerValue];
    CGFloat animationDuration = duration / 1000.0f;
    
   [[MDMEngine shareEngine].mdmWidgetManage startWidgetWithId:widgetId
                                                   openerInfo:openerInfo
                                                     callback:callback
                                                  animationId:animationId
                                                     duration:animationDuration];
    
    
}

/*******************************************************************************
 接口调用：tmbWidget.finishWidget(inResultInfo)
 方法说明：退出当前widget。
 参数说明：
    // inResultInfo：结束此widget时，把消息传递给opener，若Awidget开启Bwidget，Bwidget结束时，传回给Awidget的信息。
 Callback方法：无
 *******************************************************************************/
-(void)finishWidget:(NSMutableArray*)arguments
{
    NSLog(@"call tmbWidget.finishWidget");

    NSString* resultInfo = JSGetArgmForString([arguments objectAtIndex:0]);
    self.curWebView.widget.resultInfo = resultInfo;
    [[MDMEngine shareEngine].mdmWidgetManage quitSubWidgetViewWithAnimation:0 duration:0.25f];
}

/*******************************************************************************
 接口调用：tmbWidget.removeWidget(inWgtId)
 方法说明：删除一个widget。
 参数说明：
    // inWgtId：widget的appid。
 Callback方法：
    // tmbWidget.cbRemoveWidget(opId,dataType,data)
 　　// opId: 操作ID，在此函数中不起作用，可忽略
 　　// dataType: 返回数据的数据类型为整形(值为2)
 　　// data: 返回的数据。0为成功，1为失败
 *******************************************************************************/
-(void)removeWidget:(NSMutableArray*)arguments
{
    NSString* widgetId = JSGetArgmForString([arguments objectAtIndex:0]);
    

    if ([self.curWebView.widget isSubWidget] == NO &&
        (([MDMEngine shareEngine].mdmWidgetManage.subWidget!=nil &&
          [[MDMEngine shareEngine].mdmWidgetManage.subWidget.widgetId isEqualToString:widgetId]==NO) ||
         [MDMEngine shareEngine].mdmWidgetManage.subWidget==nil))
    {
        // 在主widget上执行且当前子widget不是要删除的widget
        NSString* pluginPath = [NSString stringWithFormat:@"plugin/%@", widgetId];
        NSString* subWidgetPath = [self.curWebView.widget.rootPath stringByAppendingPathComponent:pluginPath];
        
        NSFileManager* fileMgr = [NSFileManager defaultManager];
        BOOL isPath = NO;
        BOOL isPathExist = [fileMgr fileExistsAtPath:subWidgetPath isDirectory:&isPath];
        BOOL success = NO;
        if (isPathExist && isPath)
        {
            success = [fileMgr removeItemAtPath:subWidgetPath error:nil];
        }
        
        if (success)
        {
            [self setJsCallback:@"tmbWidget.cbRemoveWidget" opId:0 dataType:1 data:@"0"];
        }
        else
        {
            [self setJsCallback:@"tmbWidget.cbRemoveWidget" opId:0 dataType:1 data:@"1"];
        }
    }
    else
    {
        [self setJsCallback:@"tmbWidget.cbRemoveWidget" opId:0 dataType:1 data:@"1"];
    }
}

/*******************************************************************************
 接口调用：tmbWidget.isWidgetInstalled(inWgtId)
 方法说明：查询某指定的子widget是否已经安装。
 参数说明：
    // inWgtId：widget的appid。
 Callback方法：
    // tmbWidget.cbIsWidgetInstalled(opId,dataType,data)
 　　// opId:操作ID，在此函数中不起作用，可忽略
 　　// dataType: 返回数据的数据类型为整形(值为2)
 　　// data：返回的数据，0为已经安装，1为未安装
 *******************************************************************************/
-(void)isWidgetInstalled:(NSMutableArray*)arguments
{
    NSString* widgetId = JSGetArgmForString([arguments objectAtIndex:0]);
    BOOL isInstalled = [MDMWidget isSubWidgetInstalled:widgetId];
    
    NSString* strRet = isInstalled ? @"0" : @"1";
    
    [self setJsCallback:@"tmbWidget.cbIsWidgetInstalled" opId:0 dataType:1 data:strRet];
}

/*******************************************************************************
 接口调用：tmbWidget.installWidget(inWgtId,inPkgPath)
 方法说明：安装子widget。
 参数说明：
    // inWgtId：widget的appid。
    // inPkgPath: widget的安装包，zip格式压缩
 Callback方法：
    // tmbWidget.cbInstallWidget(opId,dataType,data)
 　　// opId:操作ID，在此函数中不起作用，可忽略
 　　// dataType: 返回数据的数据类型为整形(值为2)
 　　// data：返回的数据，0为成功，1为失败
 *******************************************************************************/
-(void)installWidget:(NSMutableArray*)arguments
{
    NSLog(@"call tmbWidget.installWidget");

}

/*******************************************************************************
 接口调用：tmbWidget.loadApp(inAppInfo,inFilter,inDataInfo)
 方法说明：根据相关信息启动一个第三方应用。
 参数说明：
    // inAppInfo：启动第三方应用的必须信息，在android上为第三方应用的action(字符串类型,如：android.intent.action.VIEW)；在iphone上为第三方应用在设备上注册的scheme，如：http://www.baidu.com;。
 　　// inFilter：过滤条件，即要传递给第三方应用数据的MimeType，如text/html等，*为任意类型。此参数在IOS上不起作用。
 　　// inDataInfo：传递给第三方应用的数据。比如：调用UC浏览器打开http://www.sohu.com此参数在IOS上不起作用。
 Callback方法：无
 *******************************************************************************/
-(void)loadApp:(NSMutableArray*)arguments
{
    int argc = (int)[arguments count];
    NSString *dataInfo  = (argc>2) ? [arguments objectAtIndex:2] : nil;
    if (dataInfo) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:dataInfo]];
    }
}

/*******************************************************************************
 接口调用：tmbWidget.getWidgetInfo()
 方法说明：获取子widget的相关信息。
 参数说明：无
 Callback方法：
    // tmbWidget.cbGetWidgetInfo(opId,dataType,data)
 　　// opId:操作ID，在此函数中不起作用，可忽略
 　　// dataType: 返回数据的数据类型为整形(值为2)
 　　// data：返回的数据，JSON格式：{"name":"IceCityHRB","appId":"11122976","updateurl":"","description":"","icon":"icon.png","version":"00.00.0000"}
 *******************************************************************************/
-(void)getWidgetInfo:(NSMutableArray*)arguments
{
    NSLog(@"call tmbWidget.getWidgetInfo");

}

/*******************************************************************************
 接口调用：tmbWidget.getOpenerInfo()
 方法说明：获取opener传入此widget的相关信息。
 参数说明：无
 Callback方法：
    // tmbWidget.cbGetOpenerInfo(opId,dataType,data)
 　　// opId:操作ID，在此函数中不起作用，可忽略
 　　// dataType: 返回数据的数据类型为整形(值为2)
 　　// data：返回的数据，此widget的opener通过startWidget函数打开此widget时传入的任意值
 *******************************************************************************/
-(void)getOpenerInfo:(NSMutableArray*)arguments
{
    NSLog(@"call tmbWidget.getOpenerInfo");

}
@end
