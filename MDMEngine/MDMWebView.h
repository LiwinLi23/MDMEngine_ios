//
//  MDMWebView.h
//  MDMEngine
//
//  Created by 李华林 on 14/11/28.
//  Copyright (c) 2014年 李华林. All rights reserved.
//
//  MDM扩展版本的WEBVIEW,并定义了三分屏和浮动窗口的实现

#import <UIKit/UIKit.h>
#import "MDMDefine.h"

@class MDMWidget;

@interface MDMWebView : UIWebView<UIWebViewDelegate>
{
    TWindowType _windowType;
}

@property (nonatomic, weak  ) UIViewController    * viewController;//MDM的viewController
@property (nonatomic, weak  ) MDMWidget           * widget;//所属应用
@property (nonatomic, assign) AnimateID           animateID;//动画类型
@property (nonatomic, copy  ) NSString            * windowName;//窗体名称
@property (nonatomic, assign) TWindowType         windowType;//窗体类型
@property (nonatomic, copy  ) NSString            * windowByName;//窗体别名

//三分屏的头部和底部VIEW
@property (nonatomic, strong) MDMWebView          * headerView;
@property (nonatomic, strong) MDMWebView          * footerView;

@property (nonatomic, strong) NSMutableDictionary * popoverWindows;// 内嵌的浮动子窗口
@property (nonatomic, strong) NSMutableArray      * embededWindows;// 内嵌的其他类型子窗口

@property (nonatomic, strong) NSURL               * baseURL;

@property (nonatomic, assign) BOOL                isBackground;//是否为后台运行

//MDM支持使用三分屏的模式构建屏幕结构，分别为主窗口+头部+底部
//辅助窗口函数，用于打开头部和底部窗口,而且只能用于打开头部和底部窗口使用
-(void) openSlibing:(NSUInteger)slibingType     //窗口类型  1:头部，2底部
       withDataType:(NSUInteger)dataType        //页面载入类型
                URL:(NSString*)url              //URL地址
               Data:(NSString*)data             //数据
              Width:(CGFloat)width              //头部或底部宽
             Height:(CGFloat)height;            //头部或底部高

//关闭头部和底部窗口 1:头部，2底部
-(void) closeSlibing:(NSUInteger)slibingType;

//显示头部和底部窗口 1:头部，2底部
-(void) showSlibing:(NSUInteger)slibingType;

//在当前WINDOW中打开一个浮动窗口
-(void) openPopoverWindow:(NSString *)popName
             withDataType:(NSUInteger)dataType
                      URL:(NSString *)url
                     Data:(NSString *)data
                 AndFrame:(CGRect)frame;

//关闭指定的浮动窗口
-(void) closePopoverWindow:(NSString *)popName;
//在指定的浮动窗口中执行JS脚本
-(void) evaluateScript:(NSString *)script AtPopoverWindow:(NSString *)popName;

//添加其它窗口
- (void)addEmbededWindow:(UIView *)embededWindow;
//移除其它窗口
- (void)removeEmbededWindow:(UIView *)embededWindow;

@end
