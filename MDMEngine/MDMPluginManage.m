//
//  MDMPluginManage.m
//  MDMEngine
//
//  Created by 李华林 on 14/11/28.
//  Copyright (c) 2014年 李华林. All rights reserved.
//
//  分析插件配置XML，并插件管理

#import <UIKit/UIKit.h>
#import "MDMPluginManage.h"
#import "MDMDefine.h"
#import "MDMPluginConfigParser.h"
#import "MDMWebViewJsBridge.h"
#import "MDMEngine.h"

@interface MDMPluginManage ()
{
    NSLock *mTheLock;
}

@property (nonatomic, retain) NSDictionary* pluginsMap;           //插件能力池
@property (nonatomic, retain) NSMutableDictionary* pluginObjects; //插件对象容器
@property (nonatomic, readwrite, strong) NSXMLParser* pluginConfigParser;   //插件分析器

@end

@implementation MDMPluginManage

- (id)init
{
    self = [super init];
    if (self) {
        mTheLock = [[NSLock alloc] init];
        
        _pluginObjects = [[NSMutableDictionary alloc] initWithCapacity:4];
        [self parseAllPluginData];
    }
    return self;
}

-(void)dealloc
{
    mTheLock = nil;
    _pluginObjects = nil;
    _pluginConfigParser = nil;
    _pluginsMap = nil;
}

//分析所有插件数据信息
-(void)parseAllPluginData
{
     NSString* path = [[NSBundle mainBundle] pathForResource:@"plugins" ofType:@"xml"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
        MDMSystemAlert(@"找不到插件配置文件plugins.xml,请确认该文件是否存在！");
        return;
    }
    
    NSURL* url = [NSURL fileURLWithPath:path];
    _pluginConfigParser = [[NSXMLParser alloc] initWithContentsOfURL:url];
    if (_pluginConfigParser == nil) {
        NSLog(@"错误:XML分析器初始化失败");
        return;
    }
    
    MDMPluginConfigParser* delegate = [[MDMPluginConfigParser alloc] init];
    
    [_pluginConfigParser setDelegate:delegate];
    [_pluginConfigParser parse];
    
    _pluginsMap = [[NSDictionary alloc] initWithDictionary:delegate.pluginsDict];
//    NSLog(@"Plugins information:%@",_pluginsMap);
    //生成JS的API
    [[MDMWebViewJsBridge shareBridge] generateTmbApiByPluginData:_pluginsMap];
}

//获取插件的类名
-(NSString*)getPluginClassName:(NSString*)pluginName
{
    if (pluginName && pluginName.length > 0) {
        NSDictionary* pluginDict = [_pluginsMap objectForKey:pluginName];
        if (pluginDict) {
            return [pluginDict objectForKey:XML_ClassNameNode];
        }
    }
    return nil;
}

//根据类名获取插件名
-(NSString*)getPluginName:(NSString*)className
{
    if (_pluginsMap && [_pluginsMap count]) {
        
        for (NSString *key in _pluginsMap) {
            
            NSDictionary* dict = [_pluginsMap objectForKey:key];
            
            if ([className compare:[dict objectForKey:XML_ClassNameNode]] == NSOrderedSame) {
                
                return key;
            }
        }
    }
    return nil;
}

//获取插件类型
-(NSInteger)getPluginType:(NSString*)pluginName
{
    NSDictionary* dict = [_pluginsMap objectForKey:pluginName];
    NSString* strType = [dict objectForKey:XML_TypeElement];
    
    if (strType) {
        return [strType integerValue];
    }
    
    return MDM_PLUGIN_TYPE_GENERAL;
}

//注册插件
- (void)registerPlugin:(MDMPlugin*)plugin withClassName:(NSString*)className
{
    [mTheLock lock];
    plugin.viewController = [MDMEngine shareEngine].mainControl;
    [self.pluginObjects setObject:plugin forKey:className];
    [mTheLock unlock];
}


//获取插件实例
-(id)getPluginInstance:(NSString*)className
{
    if (className == nil) {
        return nil;
    }
    
    id obj = [self.pluginObjects objectForKey:className];
    if (!obj) {
        obj = [[NSClassFromString(className)alloc] init];
        if (obj != nil) {
            [self registerPlugin:obj withClassName:className];
        } else {
            
            NSString* strPlugin = [self getPluginName:className];
            
            if ([self getPluginType:strPlugin] == MDM_PLUGIN_TYPE_SERV)
                NSLog(@"警告:系统服务插件(%@)不存在!", strPlugin);
            else
                NSLog(@"警告:插件(%@)不存在!", strPlugin);
        }
    }
    return obj;
}

//获取所有服务类插件的类名数组
-(NSArray*)getServPluginsClassName
{
    NSMutableArray* arrServ = [[NSMutableArray alloc] init];
    if (_pluginsMap && [_pluginsMap count]) {
        
        for (NSString *key in _pluginsMap) {
            NSDictionary* dict = [_pluginsMap objectForKey:key];
//            NSLog(@"_______plugin info:%@",dict);
            if ([dict objectForKey:XML_TypeNode] &&
                [[dict objectForKey:XML_TypeNode] integerValue] == MDM_PLUGIN_TYPE_SERV) {
                
                [arrServ addObject:[dict objectForKey:XML_ClassNameNode]];
            }
        }
    }
    
    if (![arrServ count]) {
        arrServ = nil;
    }
    return arrServ;
}
//自动旋转插件
- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval) duration
{
    [self.pluginObjects enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        if ([obj respondsToSelector:@selector(willAnimateRotationToInterfaceOrientation:duration:)]) {
            [obj willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
        }
    }];
}
- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    BOOL result = NO;
    for (int i=0; i<[self.pluginObjects allValues].count; i++) {
        id obj = [[self.pluginObjects allValues] objectAtIndex:i];
        if ([obj respondsToSelector:@selector(application:openURL:sourceApplication:annotation:)]) {
            result = [obj application:application openURL:url sourceApplication:sourceApplication annotation:annotation];
            if (result == YES) {
                return  YES;
            }
        }
    }
    return result;
}
- (void)applicationDidBecomeActive:(UIApplication *)application
{
    [self.pluginObjects enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        if ([obj respondsToSelector:@selector(applicationDidBecomeActive:)]) {
            [obj applicationDidBecomeActive:application];
        }
    }];
}
@end
