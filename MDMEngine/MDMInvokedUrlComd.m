//
//  MDMInvokedUrlComd.m
//  MDMEngine
//
//  Created by 李华林 on 14/12/1.
//  Copyright (c) 2014年 李华林. All rights reserved.
//
//  解析JS发送过来的URL，转换为MDM内部需要的类型和参数
//
//  URL组合为：//插件名.方法/?参数1&参数2&参数3 (tmbSMS.send/?13800138000&您好吗)
//           具体执行的类，使用插件名来查找键值对获取

#import "MDMInvokedUrlComd.h"
#import "MDMEngine.h"
#import "MDMPluginManage.h"

@implementation MDMInvokedUrlComd

@synthesize pluginName = _pluginName;
@synthesize className = _className;
@synthesize methodName = _methodName;
@synthesize arguments = _arguments;

+(MDMInvokedUrlComd*)commandFromUrl:(NSString*)url
{
    return [[MDMInvokedUrlComd alloc] initWithUrl:url];
}

//解析JS的URL命令
-(void)parseUrl:(NSString*)url
{
    if (url && url.length > 1) {
        NSArray *components = [url componentsSeparatedByString:@"//"];
        NSLog(@"===>>>JS url:%@",url);
        if ([components count] == 2) {
            NSString* strCommand = [components objectAtIndex:1];
            
            components = [strCommand componentsSeparatedByString:@"/"];
            
            NSArray* arrComd = [[components objectAtIndex:0] componentsSeparatedByString:@"."];
            _pluginName = [arrComd objectAtIndex:0];
            _methodName = [arrComd objectAtIndex:1];
            
            //获取插件类名
            _className = [[MDMEngine shareEngine].mdmPluginManage getPluginClassName:_pluginName];
            
            //获取参数部分
            strCommand = [components objectAtIndex:1];
            
            if (strCommand && strCommand.length > 1) {
                
                arrComd = [strCommand componentsSeparatedByString:@"?"];
                
                NSArray* arrTmpArgs = [[arrComd objectAtIndex:1] componentsSeparatedByString:@"&"];
                
                for (NSString* arg in arrTmpArgs) {
                    
                    NSString* strArg = [arg stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
                    [_arguments addObject:strArg];
                }

            }else{
                _arguments = nil;
            }
            
        }
    }
}

-(id)initWithUrl:(NSString*)url
{
    self = [super init];
    if (self != nil) {
        _arguments = [[NSMutableArray alloc] init];
        [self parseUrl:url];
    }
    return self;
}

@end
