//
//  MDMWidgetManage.h
//  MDMEngine
//
//  Created by 李华林 on 14/11/28.
//  Copyright (c) 2014年 李华林. All rights reserved.
//
//  管理所有子应用（应用：表示一个具体的窗口，在这里我们使用Widget来表示）
//

#import <Foundation/Foundation.h>
#import "MDMWidget.h"

@interface MDMWidgetManage : NSObject

@property (nonatomic, strong) MDMWidget* rootWidget;        //根应用
@property (nonatomic, strong) MDMWidget* subWidget;         //子应用
@property (nonatomic, strong) MDMWidget* currentWidget;     //当前应用

//初始化应用管理器，viewControl为需要承载应用的viewControl
-(MDMWidgetManage*)initWithViewControl:(UIViewController*) viewControl;

//初使化root应用
- (BOOL)initRootWidget;

//打开root应用
- (BOOL)openRootWidget;

//启动应用窗口
- (BOOL)startWidgetWithId:(NSString *)widgetId openerInfo:(NSString *)openerInfo callback:(NSString *)callback animationId:(NSUInteger)animationId duration:(CGFloat)animationDuration;

//进入应用窗口
- (void)enterSubWidgetViewWithAnimation:(NSUInteger)animationId duration:(CGFloat)animationDuration;

//退出应用窗口
- (void)quitSubWidgetViewWithAnimation:(NSUInteger)animationId duration:(CGFloat)animationDuration;

@end
