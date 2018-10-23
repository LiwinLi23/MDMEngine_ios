//
//  MDMWindowPlugin.h
//  MDMEngine
//
//  Created by 李华林 on 14/12/10.
//  Copyright (c) 2014年 李华林. All rights reserved.
//

#import "MDMPlugin.h"

enum TmbWindowType
{
    WindowTypeNormal    = 0,
    WindowTypeTop       = 1,
    WindowTypeBottom    = 2
};

enum TmbToastWindowLocation
{
    ToastWindowLocationTopLeft      = 1,
    ToastWindowLocationTop          = 2,
    ToastWindowLocationTopRight     = 3,
    ToastWindowLocationLeft         = 4,
    ToastWindowLocationMiddle       = 5,
    ToastWindowLocationRight        = 6,
    ToastWindowLocationBottomLeft   = 7,
    ToastWindowLocationBottom       = 8,
    ToastWindowLocationBottomRight  = 9
};

enum TmbWindowFlag
{
    WindowFlagNone                  = 0,    // 标记被open的window为普通window
    WindowFlagOAuth                 = 1,    // 标记被open的window为专用于OAuth验证的window
    WindowFlagObfuscation           = 2,    // 标记被open的window要加载的网页为加密的网页
    WiondowFlagReload               = 4,    // 标记被open的window无论是否已存在都将强行刷新页面
    WiondowFlagDisableCrossdomain   = 8,    // 标记被open的window当中的任何url都将调用系统浏览打开
    WiondowFlagOpaque               = 16,   // 标记被open的window当中的view为不透明的
    WiondowFlagHidden               = 32,   // 标记被open的window为隐藏的。隐藏的window不会显示到屏幕上，只存在于后台。隐藏的window不可以再调用open window
    WiondowFlagPreOpen              = 64,   // 标记被open的window将有一个或n个popOver的预加载，且只有此window中的这些popOver都加载完毕后，此window才会显示到屏幕上
    WiondowFlagEnableScale          = 128,  // 标记被open的window或popOver将支持手势缩放,且在html中，viewport的"user-scalable=no" 属性去掉
};

@interface MDMWindowPlugin : MDMPlugin<UIActionSheetDelegate>

@property(nonatomic, strong) UIView* toastView;
@property(nonatomic, strong) UILabel* toastLabel;
@property(nonatomic, strong) UIActivityIndicatorView* toastIndicator;
@property(nonatomic, strong) NSTimer* toastTimer;

@property(nonatomic, strong) UIActionSheet* actionSheet;

// main window
-(void)open:(NSMutableArray*)arguments;
-(void)close:(NSMutableArray*)arguments;
-(void)evaluateScript:(NSMutableArray*)arguments;

// slibing window
-(void)openSlibing:(NSMutableArray*)arguments;
-(void)closeSlibing:(NSMutableArray*)arguments;
-(void)showSlibing:(NSMutableArray*)arguments;

// page navigation
-(void)forward:(NSMutableArray*)arguments;
-(void)back:(NSMutableArray*)arguments;
-(void)windowForward:(NSMutableArray*)arguments;
-(void)windowBack:(NSMutableArray*)arguments;
-(void)goBackTo:(NSMutableArray*)arguments;
-(void)goBack:(NSMutableArray*)arguments;

// small window
-(void)alert:(NSMutableArray*)arguments;
-(void)confirm:(NSMutableArray*)arguments;
-(void)prompt:(NSMutableArray*)arguments;
-(void)actionSheet:(NSMutableArray*)arguments;
-(void)toast:(NSMutableArray*)arguments;
-(void)closeToast:(NSMutableArray*)arguments;

// Popover Window
-(void)preOpenStart:(NSMutableArray*)arguments;
-(void)preOpenFinish:(NSMutableArray*)arguments;
-(void)openPopover:(NSMutableArray*)arguments;
-(void)closePopover:(NSMutableArray*)arguments;
-(void)setPopoverFrame:(NSMutableArray*)arguments;
-(void)evaluatePopoverScript:(NSMutableArray*)arguments;
-(void)bringToFront:(NSMutableArray*)arguments;

// Animation methods
-(void)beginAnimition:(NSMutableArray*)arguments;
-(void)setAnimitionDelay:(NSMutableArray*)arguments;
-(void)setAnimitionDuration:(NSMutableArray*)arguments;
-(void)setAnimitionCurve:(NSMutableArray*)arguments;
-(void)setAnimitionRepeatCount:(NSMutableArray*)arguments;
-(void)setAnimitionAutoReverse:(NSMutableArray*)arguments;
-(void)makeTranslation:(NSMutableArray*)arguments;
-(void)makeScale:(NSMutableArray*)arguments;
-(void)makeRotate:(NSMutableArray*)arguments;
-(void)makeAlpha:(NSMutableArray*)arguments;
-(void)commitAnimition:(NSMutableArray*)arguments;

// other methods
-(void)getUrlQuery:(NSMutableArray*)arguments;


//tmbLog
- (void)openLog:(NSMutableArray*)arguments;
-(void)sendLog:(NSMutableArray*)arguments;

@end
