//
//  MDMPluginManage.h
//  MDMEngine
//
//  Created by 李华林 on 14/11/28.
//  Copyright (c) 2014年 李华林. All rights reserved.
//
//  分析插件配置XML，并插件管理

#import <Foundation/Foundation.h>
#import "MDMPlugin.h"

@interface MDMPluginManage : NSObject

//获取插件的类名
-(NSString*)getPluginClassName:(NSString*)pluginName;

//获取插件实例
-(id)getPluginInstance:(NSString*)className;

//获取所有服务类插件的类名数组
-(NSArray*)getServPluginsClassName;
- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval) duration;//henry
- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation;//henry
- (void)applicationDidBecomeActive:(UIApplication *)application;//henry
@end
