//
//  MDMInvokedUrlComd.h
//  MDMEngine
//
//  Created by 李华林 on 14/12/1.
//  Copyright (c) 2014年 李华林. All rights reserved.
//
//  解析JS发送过来的URL，转换为MDM内部需要的类型和参数
//
//  URL组合为：插件名.方法/?参数1&参数2&参数3 (tmbSMS.send/?13800138000&您好吗)
//           具体执行的类，使用插件名来查找键值对获取


#import <Foundation/Foundation.h>

@interface MDMInvokedUrlComd : NSObject
{
    NSString* _pluginName;  //插件名
    NSString* _className;   //类名
    NSString* _methodName;  //方法
    NSMutableArray* _arguments;    //参数
}

@property (nonatomic, readonly) NSString* pluginName;
@property (nonatomic, readonly) NSString* className;
@property (nonatomic, readonly) NSString* methodName;
@property (nonatomic, readonly) NSMutableArray* arguments;

+(MDMInvokedUrlComd*)commandFromUrl:(NSString*)strUrl;

@end
