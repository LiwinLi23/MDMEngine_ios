//
//  MDMAppDelegate.m
//  MDMEngine
//
//  Created by 李华林 on 15/1/20.
//  Copyright (c) 2015年 李华林. All rights reserved.

/**************************************************************************************************/
/*                                      修改日志                                                    */
/*修改日期：2015年5月20日                                                                            */
/*修改人员：李华林                                                                                   */
/*修改内容：1、增加cookie缓存配置                                                                     */
/*        2、app启动保存本次的启动时间                                                                */
/*        3、app启动提交上次使用时间，以及崩溃日志                                                      */
/**************************************************************************************************/
/*修改日期：2015年6月16日                                                                            */
/*修改人员：李华林                                                                                   */
/*修改内容：1、增加- (void)application: didReceiveRemoteNotification: fetchCompletionHandler:方法,接收*/
/*           百度推送消息                                                                           */
/*        2、取消后台运行10分钟机制,进后台直接统计使用时间                                                */
/**************************************************************************************************/

/**************************************************************************************************/
/*修改日期：2015年6月16日                                                                            */
/*修改人员：李华林                                                                                   */
/*修改内容：1、增加- (void)application: didReceiveRemoteNotification: fetchCompletionHandler:方法,接收*/
/*           百度推送消息                                                                           */
/*        2、取消后台运行10分钟机制,进后台直接统计使用时间                                                */
/**************************************************************************************************/

#import "MDMAppDelegate.h"
#import "MDMNavigationController.h"
#import "MDMViewController.h"
#import "MDMDefine.h"
#import "MDM.h"
#import "MDMUltil.h"

#import "dlfcn.h"

@interface MDMAppDelegate()
{
    MDMEngine* _engine;
    BOOL _isStatistics;
    __block UIBackgroundTaskIdentifier identifier;
}
@property (nonatomic, strong) NSMutableArray* arrServPlugin;  //系统服务插件

@end

@implementation MDMAppDelegate
@synthesize window,arrServPlugin;


-(void)getServPluginInstance
{
    NSArray* arrServPluginClassName = [[MDMEngine shareEngine].mdmPluginManage getServPluginsClassName];

    for (NSString* className in arrServPluginClassName) {
        
        id pluginObj = [[MDMEngine shareEngine].mdmPluginManage getPluginInstance:className];
        if (pluginObj) {
            [arrServPlugin addObject:pluginObj];
        }
    }
}

-(id)init
{
    self = [super init];
    
    if (self != nil) {
        //配置cookie henry
        [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookieAcceptPolicy:NSHTTPCookieAcceptPolicyAlways];
        
        //初始化引擎
        _isStatistics = YES;
        _engine = [MDMEngine shareEngine];
        arrServPlugin = [[NSMutableArray alloc] init];
        [self getServPluginInstance];
        
        //设置统计开始时间
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setObject:[self getCurrentTime] forKey:@"statisticsStartTime"];
    }
    return self;
}

- (void)performToServPlugin:(SEL)aSelector withObject:(id)obj waitUntilDone:(BOOL)wait
{
    if (arrServPlugin && [arrServPlugin count]) {
        
        for (MDMPlugin* pluginObj in arrServPlugin) {
            
            if ([pluginObj respondsToSelector:aSelector]) {
                [pluginObj performSelectorOnMainThread:aSelector withObject:obj waitUntilDone:wait];
            }
        }
    }
}
#pragma mark -
#pragma mark 获取当前时间
- (NSString *)getCurrentTime
{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"YYYY-MM-dd HH:mm:ss"];
    NSString *dateTime = [formatter stringFromDate:[NSDate date]];
    return dateTime;
}

#pragma mark -
#pragma mark 崩溃日志收集处理
void UncaughtExceptionHandler(NSException *exception) {
    NSArray *arr = [exception callStackSymbols];//得到当前调用栈信息
    NSString *reason = [exception reason];//非常重要，就是崩溃的原因
    NSString *name = [exception name];//异常类型
    
    NSString *crashLogInfo = [NSString stringWithFormat:@"exception type : %@ \n crash reason : %@ \n call stack info : %@", name, reason, arr];

    //统计本次崩溃日志
    NSMutableArray *list = [[NSMutableArray alloc] initWithObjects:crashLogInfo, nil];
    [[MDMStatisticsPlugin sharedInstance] setCrashLog:list];
}

#pragma mark -
#pragma mark 启动完成处理

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{    
    NSSetUncaughtExceptionHandler(&UncaughtExceptionHandler);//henry 崩溃日志统计
    
    [self performToServPlugin:NSSelectorFromString(@"didFinishLaunchingWithOptions:")
                   withObject:launchOptions
                waitUntilDone:NO];

    MDMViewController* viewController = [[MDMViewController alloc] init];

    MDMNavigationController* nav = [[MDMNavigationController alloc] initWithRootViewController:viewController];
    [MDMUltil setNavigationBarColor:nav color:[UIColor purpleColor]];
    
    //设置主控制器
    _engine.mainControl = nav;
    
    window = [[UIWindow alloc]initWithFrame:[UIScreen mainScreen].bounds];
    window.autoresizesSubviews = YES;

    window.rootViewController = nav;
    [window makeKeyAndVisible];
    
//    [application setStatusBarHidden:NO];
    //提交上次使用时间
    [[MDMStatisticsPlugin sharedInstance] submitLastStatistics];
    //提交崩溃日志
    [[MDMStatisticsPlugin sharedInstance] submitCrashLog];
    return YES;
}

#pragma mark -
#pragma mark 跳转处理

- (NSArray *)getAllURLSchemes
{
    __block NSMutableArray *AppIds = [[NSMutableArray alloc] initWithCapacity:0];
    NSString *pathPlist = [[NSBundle mainBundle] pathForResource:@"Info" ofType:@"plist"];
    NSDictionary *content = [[NSDictionary alloc] initWithContentsOfFile:pathPlist];
    NSArray *URLSchemes = [content objectForKey:@"CFBundleURLTypes"];
    
    [URLSchemes enumerateObjectsUsingBlock:^(id obj,NSUInteger idx,BOOL *stop){
        if ([obj isKindOfClass:[NSDictionary class]]) {
            NSArray *lists = [obj objectForKey:@"CFBundleURLSchemes"];
            for (NSString *appId in lists) {
                [AppIds addObject:appId];
            }
        }
    }];
//    NSLog(@"all url schemes:%@",AppIds);
    return AppIds;
}

#pragma mark -
#pragma mark 分享相关
- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url
{
//    NSLog(@"+++++++++url:%@",url);
    return NO;
}
- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    NSLog(@"url:%@,sourceApplication:%@",url,sourceApplication);
    for (NSString *appId in [self getAllURLSchemes]) {
        if ([[url absoluteString] hasPrefix:appId]) {
            return [[MDMEngine shareEngine].mdmPluginManage application:application openURL:url sourceApplication:sourceApplication annotation:annotation];
        }
    }
    return  NO;
}
/**
 这里处理新浪微博SSO授权进入新浪微博客户端后进入后台，再返回原来应用
 */
- (void)applicationDidBecomeActive:(UIApplication *)application
{
    [[MDMEngine shareEngine].mdmPluginManage applicationDidBecomeActive:application];
    //设置统计开始时间
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[self getCurrentTime] forKey:@"statisticsStartTime"];
}

#pragma mark -
#pragma mark 推送相关
// 在 iOS8 系统中，还需要添加这个方法。通过新的 API 注册推送服务
- (void)application:(UIApplication *)application didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings {
    
    [self performToServPlugin:NSSelectorFromString(@"didRegisterUserNotificationSettings:")
                   withObject:application
                waitUntilDone:NO];
}

- (void)application:(UIApplication *)app didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    
    [self performToServPlugin:NSSelectorFromString(@"didRegisterForRemoteNotificationsWithDeviceToken:")
                   withObject:deviceToken
                waitUntilDone:NO];
}

- (void)application:(UIApplication *)app didFailToRegisterForRemoteNotificationsWithError:(NSError *)err {
    
    [self performToServPlugin:NSSelectorFromString(@"didFailToRegisterForRemoteNotificationsWithError:")
                   withObject:err
                waitUntilDone:NO];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    
    NSLog(@"receive remote notification:%@",userInfo);
    [self performToServPlugin:NSSelectorFromString(@"didReceiveRemoteNotification:")
                   withObject:userInfo
                waitUntilDone:NO];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
    [self performToServPlugin:NSSelectorFromString(@"fetchCompletionHandler:")
                   withObject:userInfo
                waitUntilDone:NO];
    completionHandler(UIBackgroundFetchResultNewData);
}
//- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification
//{
//    [self performToServPlugin:NSSelectorFromString(@"didReceiveLocalNotification:")
//                   withObject:notification
//                waitUntilDone:NO];
//}
#pragma mark -
#pragma mark 状态相关

- (void)applicationWillResignActive:(UIApplication *)application {

}

- (void)applicationDidEnterBackground:(UIApplication *)application {
//    identifier = [[UIApplication sharedApplication]beginBackgroundTaskWithExpirationHandler:^(){
//        //程序在10分钟内未被系统关闭或者强制关闭，则程序会调用此代码块，可以在这里做一些保存或者清理工作
//        if (identifier != UIBackgroundTaskInvalid) {
//            [[UIApplication sharedApplication] endBackgroundTask:identifier];
//            identifier = UIBackgroundTaskInvalid;
//            _isStatistics = NO;
//            
//            //统计本次APP的使用时间
//            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
//            NSMutableArray *list = [[NSMutableArray alloc] initWithObjects:@{@"startTime":[defaults objectForKey:@"statisticsStartTime"],@"endTime":[self getCurrentTime]}, nil];
//            [[MDMStatisticsPlugin sharedInstance] setStatistics:list];
//        }
//    }];
    //统计本次APP的使用时间
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSMutableArray *list = [[NSMutableArray alloc] initWithObjects:@{@"startTime":[defaults objectForKey:@"statisticsStartTime"],@"endTime":[self getCurrentTime]}, nil];
    [[MDMStatisticsPlugin sharedInstance] setStatistics:list];
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
//    if (_isStatistics) {
//        [[UIApplication sharedApplication] endBackgroundTask:identifier];
//        identifier = UIBackgroundTaskInvalid;
//    } else {
//        _isStatistics = YES;
//        
//        //提交上次使用时间
//        [[MDMStatisticsPlugin sharedInstance] submitLastStatistics];
//    }
}

- (void)applicationWillTerminate:(UIApplication *)application {
    //统计本次APP的使用时间
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSMutableArray *list = [[NSMutableArray alloc] initWithObjects:@{@"startTime":[defaults objectForKey:@"statisticsStartTime"],@"endTime":[self getCurrentTime]}, nil];
    [[MDMStatisticsPlugin sharedInstance] setStatistics:list];
    
    // 清除TMP目录
    NSFileManager* fileMgr = [[NSFileManager alloc] init];
    NSError* __autoreleasing err = nil;
    NSString* tempDirectoryPath = NSTemporaryDirectory();
    NSDirectoryEnumerator* directoryEnumerator = [fileMgr enumeratorAtPath:tempDirectoryPath];
    NSString* fileName = nil;
    BOOL result;
    
    while ((fileName = [directoryEnumerator nextObject])) {
        NSString* filePath = [tempDirectoryPath stringByAppendingPathComponent:fileName];
        result = [fileMgr removeItemAtPath:filePath error:&err];
        if (!result && err) {
            NSLog(@"Failed to delete: %@ (error: %@)", filePath, err);
        }
    }
}

@end
