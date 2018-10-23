//
//  MMDMComdQueue.m
//  MDMEngine
//
//  Created by 李华林 on 14/11/28.
//  Copyright (c) 2014年 李华林. All rights reserved.
//
//  JS到OBJ-C端的命令队列和线程安全处理

#import <UIKit/UIKit.h>
#include <objc/message.h>
#import "MDMComdQueue.h"
#import "NSMutableArray+QueueAdditions.h"
#import "MDM.h"

static const double MAX_EXECUTION_TIME = .008;  //线程超时时间

@interface MDMComdQueue () {
    NSInteger _lastCommandQueueFlushRequestId;
    NSMutableArray* _queue;                     //命令队列
    NSTimeInterval _startExecutionTime;
}
@end

@implementation MDMComdQueue

-(id)init
{
    self = [super init];
    if (self != nil) {
        _queue = [[NSMutableArray alloc] init];
    }
    return self;
}

-(void)dealloc
{
    _queue = nil;
}

- (BOOL)currentlyExecuting
{
    return _startExecutionTime > 0;
}

- (void)enqueueCmdBatch:(NSString*)urlCmd webView:(MDMWebView*)webview widget:(MDMWidget*)wgt;
{
    if ([urlCmd length] > 0) {
        NSDictionary* commandBatchHolder = [[NSDictionary alloc] initWithObjectsAndKeys:
                                            urlCmd, MDM_CMD_QUEUE_URMCMD,
                                            webview,MDM_CMD_QUEUE_WEBVIEW,
                                            wgt,    MDM_CMD_QUEUE_WIDGET,nil];
        
        [_queue addObject:commandBatchHolder];
        [self executePending];
    }
}

//执行命令
- (BOOL)execute:(NSDictionary*)cmdDict;
{
    NSString* strUrlCmd = [cmdDict objectForKey:MDM_CMD_QUEUE_URMCMD];
    
    if (!strUrlCmd)
        return NO;
    
    MDMInvokedUrlComd* command = [MDMInvokedUrlComd commandFromUrl:strUrlCmd];
    
    NSString* strMsg = @"";
    if ((command.className == nil) || (command.methodName == nil)) {
        MDMSystemAlert( @"插件或方法不存在！");
        return NO;
    }
    
    MDMPlugin* pluginObj = [[MDMEngine shareEngine].mdmPluginManage getPluginInstance:command.className];
    
    if (!([pluginObj isKindOfClass:[MDMPlugin class]])) {
        if ([MDMStatisticsPlugin sharedInstance].isDebug) {
            NSString *logs = [NSString stringWithFormat:@"没有找到%@插件，请仔细阅读开发文档!",command.pluginName];
            [[MDMStatisticsPlugin sharedInstance] sendDebugLog:logs];
        } else {
            strMsg = [NSString stringWithFormat:@"没有找到%@插件，请检查plugin.xml配置是否正确!",command.pluginName];
            MDMSystemAlert(strMsg);
        }
        
        return NO;
    }
    
    //设置插件所属关系数据
    pluginObj.curWebView = [cmdDict objectForKey:MDM_CMD_QUEUE_WEBVIEW];
    pluginObj.curWidget  = [cmdDict objectForKey:MDM_CMD_QUEUE_WIDGET];
    
    BOOL retVal = YES;
    
    NSString* methodName = [NSString stringWithFormat:@"%@:", command.methodName];
    
    //
    if ([pluginObj respondsToSelector:NSSelectorFromString(methodName)])
    {
        NSString* strParam = @"";
        for (NSString* param in command.arguments)
        {
            strParam = [strParam stringByAppendingString:param];
            strParam = [strParam stringByAppendingString:@","];
        }
        if (strParam.length>1)
        {
            strParam = [strParam substringToIndex:(strParam.length-1)];
        }
        
        [pluginObj performSelectorOnMainThread:NSSelectorFromString(methodName)  withObject:command.arguments waitUntilDone:NO];
        if ([MDMStatisticsPlugin sharedInstance].isDebug) {
            NSString *logs = [NSString stringWithFormat:@"%@.%@(%@)",command.pluginName,command.methodName,strParam];
            [[MDMStatisticsPlugin sharedInstance] sendDebugLog:logs];
        } else {
            NSLog(@"执行:%@.%@(%@)",command.pluginName,command.methodName,strParam);
        }
    }
    else
    {
        strMsg = [NSString stringWithFormat:@"插件类'%@'的方法'%@'没有找到",command.className,command.methodName];
        retVal = NO;
        if ([MDMStatisticsPlugin sharedInstance].isDebug) {
            NSString *logs = [NSString stringWithFormat:@"%@",strMsg];
            [[MDMStatisticsPlugin sharedInstance] sendDebugLog:logs];
        } else {
            MDMSystemAlert(strMsg);
        }
    }
    
    //
//    SEL normalSelector = NSSelectorFromString(methodName);
//    if ([pluginObj respondsToSelector:normalSelector]) {
//
//        NSString* strParam = @"";
//        for (NSString* param in command.arguments) {
//            strParam = [strParam stringByAppendingString:param];
//            strParam = [strParam stringByAppendingString:@","];
//        }
//        if (strParam.length>1) {
//            strParam = [strParam substringToIndex:(strParam.length-1)];
//        }
//        NSLog(@"执行:%@.%@(%@)",command.pluginName,command.methodName,strParam);
//        
//        ((void (*)(id, SEL, id))objc_msgSend)(pluginObj, normalSelector, command.arguments);
//        
//    } else {
//        strMsg = [NSString stringWithFormat:@"插件类'%@'的方法'%@'没有找到",command.className,command.methodName];
//        MDMSystemAlert(strMsg);
//        retVal = NO;
//    }
    
    return retVal;
}

- (void)executePending
{
    if (_startExecutionTime > 0) {
        return;
    }
    @try {
        _startExecutionTime = [NSDate timeIntervalSinceReferenceDate];
        
        while ([_queue count] > 0) {
            NSMutableArray* commandBatchHolder = _queue;
            NSMutableArray* commandBatch = nil;
            @synchronized(commandBatchHolder) {//保护队列，防止其它访问_queue
                if ([commandBatchHolder count] == 0) {
                    break;
                }
                commandBatch = commandBatchHolder;
            }
            
            while ([commandBatch count] > 0) {
                @autoreleasepool {
                    NSDictionary* cmdDict = [commandBatch dequeue];
                    [self execute:cmdDict];
                }
                if (([_queue count] > 0) && ([NSDate timeIntervalSinceReferenceDate] - _startExecutionTime > MAX_EXECUTION_TIME)) {
                    [self performSelector:@selector(executePending) withObject:nil afterDelay:0];
                    return;
                }
            }
        }
    }
    @finally {
        _startExecutionTime = 0;
    }
}

@end
