//
//  MDMComdQueue.h
//  MDMEngine
//
//  Created by 李华林 on 14/11/28.
//  Copyright (c) 2014年 李华林. All rights reserved.
//
//  JS到OBJ-C端的命令队列和线程安全处理

#import <Foundation/Foundation.h>
#import "MDMInvokedUrlComd.h"

@class MDMWebView;
@class MDMWidget;

@interface MDMComdQueue : NSObject

@property (nonatomic, readonly) BOOL currentlyExecuting;    //是否正在执行

//添加命令到队列
- (void)enqueueCmdBatch:(NSString*)urlCmd webView:(MDMWebView*)webview widget:(MDMWidget*)wgt;

//执行命令
- (BOOL)execute:(NSDictionary*)cmdDict;

//线程安全处理
- (void)executePending;


@end
