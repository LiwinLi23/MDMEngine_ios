//
//  MDMPluginConfigParser.h
//  MDMEngine
//
//  Created by 李华林 on 14/12/1.
//  Copyright (c) 2014年 李华林. All rights reserved.
//
//  MDM插件配置分析器

#import <Foundation/Foundation.h>

@interface MDMPluginConfigParser : NSObject<NSXMLParserDelegate>

@property (nonatomic, readonly, strong) NSMutableDictionary* pluginsDict;


@end
