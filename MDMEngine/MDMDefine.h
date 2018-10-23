//
//  MDMDefine.h
//  MDMEngine
//
//  Created by 李华林 on 14/12/1.
//  Copyright (c) 2014年 李华林. All rights reserved.
//

#ifndef MDMEngine_MDMDefine_h
#define MDMEngine_MDMDefine_h



//当前引擎的版本和BUILD号
#define MDMENGINE_VERSION   @"2.0.0"
#define MDMENGINE_BUILD     @"1"




typedef enum
{
    // Apple NetworkStatus Compatible Names.
    cWindowAnimiIDNone=0,                               //(无动画)	0
    cWindowAnimiIDLeftToRight,                          //(由左往右推入)	1
    cWindowAnimiIDRightToLeft,                          //(由右往左推入)	2
    cWindowAnimiIDUpToDown,                             //(由上往下推入)	3
    cWindowAnimiIDDownToUp,                             //(由下往上推入)	4
    cWindowAnimiIDFadeOutFadeIn,                        //(淡入淡出)	5
    
    cWindowAnimiIDLeftFlip,                             //(左翻页,android暂不支持)	6
    cWindowAnimiIDRigthFlip,                            //(右翻页,android暂不支持)	7
    cWindowAnimiIDRipple,                               //(水波纹,android暂不支持)	8
    cWindowAnimiIDLeftToRightMoveIn,                    //(由左往右切入)	9
    cWindowAnimiIDRightToLeftMoveIn,                    //(由右往左切入)	10
    
    cWindowAnimiIDTopToBottomMoveIn,                    //(由上往下切入)	11
    cWindowAnimiIDBottomToTopMoveIn,                    //(由下往上切入)	12
    cWindowAnimiIDLeftToRightReveal,                    //(由左往右切出,close时与9对应)	13
    cWindowAnimiIDRightToLeftReveal,                    //(由右往左切出,close时与10对应)	14
    cWindowAnimiIDTopToBottomReveal,                    //(由上往下切出,close时与11对应)	15
    cWindowAnimiIDBottomToTopReveal,                    //(由下往上切出,close时与12对应)	16
} AnimateID;

typedef enum {
    kWindowTypeWindow = 0,          //普通窗体类型
    kWindowTypePopover,             //浮动窗体类型
    kWindowTypeBackground           //后台类型
}TWindowType;


//plugins.xml节点定义
#define XML_RootNode                @"mdm"//@"MDMPlugins"
#define XML_PluginNode              @"plugin"
#define XML_NameElement             @"name"
#define XML_TypeElement             @"type"
#define XML_VerElement              @"version"
#define XML_BuildElement            @"build"
#define XML_EngineElement           @"engine"
#define XML_ClassNameNode           @"className"
#define XML_MethodNode              @"method"
#define XML_CallBackNode            @"callback"
#define XML_AuthorNode              @"author"
#define XML_DescriptionNode         @"description"
/*-------------henry add define with new xml-------------*/
#define XML_ClassCnNameNode         @"cnName"
#define XML_TypeNode                @"type"
#define XML_ReleaseNoteNode         @"releaseNote"
#define XML_ItemNode                @"item"
#define XML_MethodsNode              @"methods"
#define XML_PropertiesNode          @"properties"

//插件类型
#define MDM_PLUGIN_TYPE_GENERAL     0    //普通插件
#define MDM_PLUGIN_TYPE_SERV        1    //系统服务类插件


//屏幕信息
#define MDM_SCREEN_WIDTH ([UIScreen mainScreen].bounds.size.width)
#define MDM_SCREEN_HEIGHT ([UIScreen mainScreen].bounds.size.height)

//版本信息
#define MDM_IOS_VERSION [[[UIDevice currentDevice] systemVersion] floatValue]
#define MDM_DEV_IS_IOS7 (MDM_IOS_VERSION>=7.0 && MDM_IOS_VERSION<8.0)
#define MDM_DEV_IS_IOS7_OR_LATER (MDM_IOS_VERSION>=7.0)
#define MDM_DEV_IS_IOS8 (MDM_IOS_VERSION>=8.0)
#define MDM_CurrentSystemName ([[UIDevice currentDevice] systemName])
#define MDM_CurrentSystemVersion ([[UIDevice currentDevice] systemVersion])
#define MDM_CurrentSystemModel ([[UIDevice currentDevice] model])
#define MDM_CurrentLanguage ([[NSLocale preferredLanguages] objectAtIndex:0])

#define MDM_APPID ([[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleIdentifier"])

//设备信息
#define MDM_DEV_IS_IPHONE5 ([[UIScreen mainScreen] bounds].size.height == 568)
#define MDM_DEV_IS_IPHONE6 ([[UIScreen mainScreen] bounds].size.height == 667)
#define MDM_DEV_IS_IPHONE6PLUS ([[UIScreen mainScreen] bounds].size.height == 736)
#define MDM_IS_Pad (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)

//系统目录
#define MDM_FileMag ([NSFileManager defaultManager])
#define MDM_LibraryDir ([NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0])
#define MDM_wwwBundleDir ([NSString stringWithFormat:@"%@/www", [[NSBundle mainBundle] bundlePath]])

//默认的首页文件
#define MDM_ROOT_FILE @"index.html"

//默认ROOT应用名称
#define MDM_ROOT_WindowName @"root"

//MDM后台运行WEBVIEW窗口名
#define MDM_BG_Serv @"__MDM_background_service__"

//JS命令前缀
#define MDM_PREFIX_JSCOMMAND  @"zhangcheng"

//执行命令队列里的数据信息
#define MDM_CMD_QUEUE_URMCMD    @"URLCMD"
#define MDM_CMD_QUEUE_WEBVIEW   @"WEBVIEW"
#define MDM_CMD_QUEUE_WIDGET    @"WIDGET"

//窗口别名，三分屏窗口使用
#define MDM_WindowByName_Header    @"header"
#define MDM_WindowByName_Footer    @"footer"
#define MDM_WindowByName_Common    @"common"

//获取JS传递的参数数据
#define JSGetArgmForNumber(argument) ([argument isKindOfClass:[NSNumber class]] ? argument:[argument isKindOfClass:[NSString class]]?[NSNumber numberWithDouble:[argument doubleValue]]:NULL)
#define JSGetArgmForString(argument) ([argument isKindOfClass:[NSString class]] ? argument:[argument isKindOfClass:[NSNumber class]]?[argument stringValue]:NULL)

//提示
#define MDMAlert(title,info) {UIAlertView* alert= [[UIAlertView alloc] initWithTitle:title message:info delegate:nil cancelButtonTitle:@"确认" otherButtonTitles: nil];[alert show];}

#define MDMJSAlert(info) {UIAlertView *alert=[[UIAlertView alloc] initWithTitle:@"JS调试出错" message:info delegate:nil cancelButtonTitle:@"马上修改" otherButtonTitles:nil];\
[alert show];}

#define MDMSystemAlert(info) {UIAlertView *alert=[[UIAlertView alloc] initWithTitle:@"系统错误" message:info delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil];\
[alert show];}

#endif
