//
//  MDMWindowPlugin.m
//  MDMEngine
//
//  Created by 李华林 on 14/12/10.
//  Copyright (c) 2014年 李华林. All rights reserved.
//

#import "MDMWindowPlugin.h"
#import "MDMWebView.h"
#import "MDMWidget.h"
#import "ModalAlert.h"
#import "MDMAppDelegate.h"


@interface MDMWindowPlugin()
@property (nonatomic, strong) UIWebView* actionSheetHandler;
@end

@implementation MDMWindowPlugin

@synthesize toastView;
@synthesize toastLabel;
@synthesize toastIndicator;
@synthesize toastTimer;

@synthesize actionSheet;
@synthesize actionSheetHandler;

-(void)dealloc
{
    self.toastView = nil;
    self.toastLabel = nil;
    self.toastIndicator = nil;
    self.toastTimer = nil;
    
    self.actionSheet = nil;
    self.actionSheetHandler = nil;
}

//获取主窗口，避免在头和底部执行而造成的执行窗口错误
-(MDMWebView*)getMainView
{
    MDMWebView* comWebView = self.curWebView;
    
    while (([comWebView.windowByName compare:MDM_WindowByName_Common] != NSOrderedSame) ||
           ([comWebView isKindOfClass:[MDMWebView class]] == NO)) {
        
        comWebView = (MDMWebView*)[self.curWebView superview];
    }
    
    return comWebView;
}

#pragma mark - Main Window
/*******************************************************************************
 接口调用：tmbWindow.open(inWndName,inDataType,inData,inAnimID,inWidth,inHeight,inFlag,animDuration)
 方法说明：主窗口函数，open一个新的窗口，在『主+辅』的窗口机制中，这个方法必须在Main中执行；在辅窗口中需要触发此方法，必须借助tmbWindow.evaluateScript实现，既在当前窗口的主窗口中执行一个JS方法。
 参数说明：
 　　// inWndName: 窗口的名字。可为空，不可命名为"root"。当Window栈中已经存在名为inWindowName的window时，open函数将直接跳转至此window，并用此window执行相关操作。
 　　// inDataType: 指定窗口载入的数据的类型,0表示url方式载入；1表示html内容方式载入，2表示既有url方式，又有html内容方式
 　　// inData:载入数据
 　　// inAnimID: 动画ID，查看常量表的Window Animi ID
 　　// inWidth: 窗口宽度。接受不含小数的整数,百分数,可为空,默认为屏幕的宽度
 　　// inHeight: 窗口高度。接受不含小数的整数,百分数,可为空,默认为屏幕的高度
 　　// inFlag: 详见常量表中Window Flags，如果此窗口有多重功能，即对应有多个Window Flags中的值，那么此参数可写为"1|2|4",或者"7"(1+2+4)
 　　// animDuration:动画持续时长，单位为毫秒，默认250毫秒
 Callback方法：无
 *******************************************************************************/
-(void)open:(NSMutableArray*)arguments
{
    NSString* windowName    = JSGetArgmForString([arguments objectAtIndex:0]);
    NSInteger dataType      = [JSGetArgmForNumber([arguments objectAtIndex:1])  integerValue];
    NSString* urlData       = JSGetArgmForString([arguments objectAtIndex:2]);
   // NSInteger* inAnimateId   = JSGetArgmForString([arguments objectAtIndex:3]);
    NSInteger width         = [JSGetArgmForNumber([arguments objectAtIndex:4])  integerValue];
    NSInteger height        = [JSGetArgmForNumber([arguments objectAtIndex:5])  integerValue];
   // NSInteger flag          = [JSGetArgmForNumber([arguments objectAtIndex:6])  integerValue];
    //NSInteger animateDuration = [JSGetArgmForNumber([arguments objectAtIndex:7])  integerValue];
    
   // NSString* data = [urlData stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];

    MDMWebView *execWebView = [self getMainView];
    if (execWebView.widget != nil)
    {
        CGRect viewFrame = [[UIScreen mainScreen] applicationFrame];
        CGRect frame = CGRectMake(viewFrame.origin.x,
                                  viewFrame.origin.y,
                                  (width==0) ? viewFrame.size.width : width,
                                  (height==0) ? viewFrame.size.height : height);
        
        [execWebView.widget openWindow:windowName
                                  withData:urlData
                               ofType:dataType
                                frame:frame
                          animationId:0
                             duration:0.25f
                                 flag:0];
    }
}

/*******************************************************************************
 接口调用：tmbWindow.close(inAnimId)
 方法说明：主窗口函数，关闭当前处于屏幕上的window，非当前屏幕上的窗口不能调用此函数，在『主+辅』的窗口机制中，需在主窗口中执行。
 参数说明：
 　　// inAnimId: 动画ID，空值时为无动画，-1时表示Open时指定动画的方向动画，动画ID请查看常量表的Window Animi ID
 Callback方法：无
 *******************************************************************************/
-(void)close:(NSMutableArray*)arguments
{
    MDMWebView *execWebView = [self getMainView];
    
    if (execWebView.widget && !execWebView.widget.isSwitchingView) {
        
        [execWebView.widget closeWebView];
    }
}

/*******************************************************************************
 接口调用：tmbWindow.evaluateScript(inWindowName,inType,inScript)
 方法说明：主窗口函数，根据inWindowName指定窗口执行JS脚本，在『主+辅』的窗口机制中，inWindowName为空时，表示当前窗口，通过指定inType的值，来确定是在主窗口中，还是在辅窗口中执行JS脚本。
 参数说明：
 　　// inWindowName：window的名称，可为空，为空时默认为当前窗口
 　　// inType：窗口的类 型（0表示窗口的main部分，1表示窗口的top部分，2表示窗口的bottom部分）
 　　// inScript：js脚本内容。
 Callback方法：无
 *******************************************************************************/
-(void)evaluateScript:(NSMutableArray*)arguments
{
    NSString* windowName = JSGetArgmForString([arguments objectAtIndex:0]);
    NSInteger type =  [JSGetArgmForNumber([arguments objectAtIndex:1])  integerValue];
    NSString* script = JSGetArgmForString([arguments objectAtIndex:2]);
    if (windowName==nil || script==nil)
        return;
    
    MDMWebView *execWebView = self.curWebView;
    if ([windowName length]>0)
    {
        execWebView = [(self.curWebView).widget webViewWithName:windowName];
    }
    else
    {
        execWebView = [self getMainView];
    }
    
    if (execWebView && [execWebView isKindOfClass:[MDMWebView class]])
    {
        NSString* res = nil;
        switch(type)
        {
            case WindowTypeNormal:
            {
                res = [execWebView stringByEvaluatingJavaScriptFromString:script];
                break;
            }
                
            case WindowTypeTop:
            {
                if (execWebView.headerView)
                    res = [execWebView.headerView stringByEvaluatingJavaScriptFromString:script];
                break;
            }
                
            case WindowTypeBottom:
            {
                if (execWebView.footerView)
                    res = [execWebView.footerView stringByEvaluatingJavaScriptFromString:script];
                break;
            }
        }
    }
}

#pragma mark - Slibing Window
/*******************************************************************************
 接口调用：tmbWindow.openSlibing(inType,inDataType,inUrl,inData,inWidth,inHeight)
 方法说明：辅窗口函数，在『主+辅』的窗口机制中，一个Window可拆分成三部分：主窗口Main和两个辅助窗口Top和Bottom。在UI上Main,Top,Bottom是平级的，在数据结构上，Top和Bottom是平级的，它们都属于Main的辅窗口。Top和Bottom不能单独显示，它们的加载必须由Main来驱动。每次使用tmbWindow.open打开一个新的window时都会初始化一个Main,每个window都有一个name属性，用来标识此window，每个window（无论是主窗口还是辅窗口）都有一个type属性，用来标识此窗口的类型（Main,Top,Bottom）。应用初始化时会初始化一个根window,此window的name为root，根window不能被关闭。
 参数说明：
 　　// inType：窗口的类型。不能为0（0表示窗口的main部分，1表示窗口的top部分，2表示窗口的bottom部分）
 　　// inDataType：要加载的数据类型，0表示url方式载入；1表示html内容方式载入，2表示既有url方式，又有html内容方式
 　　// inUrl：加载的url，可为空
 　　// inData：加载的数据，可为空
 　　// inWidth：窗口宽度。接受不含小数的整数,百分数,可为空,默认为屏幕的宽度
 　　// inHeight：窗口高度。接受不含小数的整数,百分数,可为空, 默认为屏幕的高度
 Callback方法：无
 *******************************************************************************/
-(void)openSlibing:(NSMutableArray*)arguments
{
    NSUInteger slibingType  = [JSGetArgmForNumber([arguments objectAtIndex:0])  unsignedIntegerValue];
    NSUInteger dataType     = [JSGetArgmForNumber([arguments objectAtIndex:1])  unsignedIntegerValue];
    NSString* url           = [arguments objectAtIndex:2];
    NSString* data          = [arguments objectAtIndex:3];
    CGFloat width           = [[arguments objectAtIndex:4] floatValue];
    CGFloat height          = [[arguments objectAtIndex:5] floatValue];
    
    MDMWebView *execWebView = [self getMainView];
    
    [execWebView openSlibing:slibingType
                    withDataType:dataType
                             URL:url
                            Data:data
                           Width:width
                          Height:height];
}

/*******************************************************************************
 接口调用：tmbWindow.closeSlibing(inType)
 方法说明：辅窗口函数，关闭当前window的辅窗口，非当前屏幕上的窗口不能调用此函数
 参数说明：
 　　// inType：窗口的类型。不能为0（0表示窗口的main部分，1表示窗口的top部分，2表示窗口的bottom部分）
 Callback方法：无
 *******************************************************************************/
-(void)closeSlibing:(NSMutableArray*)arguments
{
    NSInteger slibingType   = [[arguments objectAtIndex:0] integerValue];
    
    MDMWebView *execWebView = [self getMainView];
    
    [execWebView closeSlibing:slibingType];
}

/*******************************************************************************
 接口调用：tmbWindow.showSlibing(inType)
 方法说明：辅窗口函数，显示当前window的辅窗口，非当前屏幕上的窗口不能调用此函数
 参数说明：
 　　// inType：窗口的类型。不能为0（0表示窗口的main部分，1表示窗口的top部分，2表示窗口的bottom部分）
 Callback方法：无
 *******************************************************************************/
-(void)showSlibing:(NSMutableArray*)arguments
{
    NSUInteger slibingType   = [JSGetArgmForNumber([arguments objectAtIndex:0])  unsignedIntegerValue];

    MDMWebView *execWebView = [self getMainView];
    
    [execWebView showSlibing:slibingType];
}

#pragma mark - Page Navigation

/*******************************************************************************
 接口调用：tmbWindow.forward()
 方法说明：主窗口函数，当前window的history.forward()的替代方案。(当前window的history back，在手机的webkit中，存在一个Bug，当A.html跳转到B.html,B.html跳转到C.html，那么，用自带的history.back(),从C返回到B，B再返回的话，会返回到C，即陷入死循环)
 参数说明：无
 Callback方法：无
 *******************************************************************************/
-(void)forward:(NSMutableArray*)arguments
{
    MDMWebView *execWebView = [self getMainView];
    
    [execWebView goForward];
}
/*******************************************************************************
 接口调用：tmbWindow.back()
 方法说明：主窗口函数，当前window的history.back()的替代方案。(当前window的history back，在手机的webkit中，存在一个Bug，当A.html跳转到B.html,B.html跳转到C.html，那么，用自带的history.back(),从C返回到B，B再返回的话，会返回到C，即陷入死循环)
 参数说明：无
 Callback方法：无
 *******************************************************************************/
-(void)back:(NSMutableArray*)arguments
{
    MDMWebView *execWebView = [self getMainView];
    
    [execWebView goBack];
}

/*******************************************************************************
 接口调用：tmbWindow.windowForward(inAnimId,animDuration)
 方法说明：主窗口函数，在多窗口机制中，用于前进到下一个window，比如在A中tmbWindow.open了B,那么B在返回A时需要使用tmbWindow.windowBack方法，当此时要重新A前进B时，就可以使用此方法前进到B。
 参数说明：
    // inAnimId：动画ID，查看常量表的Window Animi ID
    // animDuration：动画持续时长，单位为毫秒，默认为250毫秒
 Callback方法：无
 *******************************************************************************/
-(void)windowForward:(NSMutableArray*)arguments
{
    NSLog(@"IOS not support tmbWindow.windowForward");
    
}

/*******************************************************************************
 接口调用：tmbWindow.windowBack(inAnimId,animDuration)
 方法说明：主窗口函数，在多窗口机制中，用于返回上一个window，比如在A中tmbWindow.open了B,那么B在返回A时就可以使用此方法
 参数说明：
    // inAnimId：动画ID，查看常量表的Window Animi ID
    // animDuration：动画持续时长，单位为毫秒，默认为250毫秒
 Callback方法：无
 *******************************************************************************/
-(void)windowBack:(NSMutableArray*)arguments
{
    NSLog(@"IOS not support tmbWindow.windowBack");
}

/*******************************************************************************
 接口调用：tmbWindow.goBackTo(inWndName)
 方法说明：主窗口函数，返回到指定窗口名的window。
 参数说明：
    // inWndName：要返回的窗口名（关于window名请参见tmbWindow.open，要返回到默认的第一个页面，窗口名必须为root）
 Callback方法：无
 *******************************************************************************/
-(void)goBackTo:(NSMutableArray*)arguments
{
    MDMWebView *execWebView = [self getMainView];
    
    NSString* windowName = [arguments objectAtIndex:0];
    
    if (windowName.length > 0) {
        if (execWebView.widget.isSwitchingView == NO &&
            [execWebView.windowName isEqualToString:windowName] == NO) {
            MDMWebView* newWebView = [execWebView.widget createWebViewWithName:windowName
                                                                         frame:self.curWebView.frame
                                                                   animationId:0
                                                                      duration:0.3f];
            if (newWebView) {
                [execWebView.widget showWebView:newWebView];
                [self performSelector:@selector(cbGoBack:) withObject:newWebView afterDelay:0.4f];
            }
        }
    } else {
        if (execWebView.widget.isSwitchingView == NO)
            [execWebView.widget closeWebView];
    }
}
- (void)cbGoBack:(MDMWebView*)webview
{
    NSString *tmbJsCommand = [NSString stringWithFormat:@"if (tmbWindow.cbGoBack) tmbWindow.cbGoBack();"];
    [webview stringByEvaluatingJavaScriptFromString:tmbJsCommand];
}
-(void)goBack:(NSMutableArray*)arguments
{
    MDMWebView *execWebView = [self getMainView];
    if (execWebView.widget.isSwitchingView == NO) {
        [execWebView.widget closeWebView];
    }
}
#pragma mark - Small Window
/*******************************************************************************
 接口调用：tmbWindow.alert(inTitle,inMessage,inButtonLable)
 方法说明：弹出一个只包含确定按钮的模态对话框。
 参数说明：
 　　// inTitle：对话框标题。
 　　// inMessage：对话内容。
 　　// inButtonLable：显示在确定按钮上的文字。
 Callback方法：无
 *******************************************************************************/
-(void)alert:(NSMutableArray*)arguments
{
    NSString* title = nil;
    NSString* message = nil;
    NSString* buttonLabel = nil;
    
    if (arguments.count == 3)
    {
        title       = JSGetArgmForString([arguments objectAtIndex:0]);
        message     = JSGetArgmForString([arguments objectAtIndex:1]);
        buttonLabel = JSGetArgmForString([arguments objectAtIndex:2]);
       
    }
    else if (arguments.count == 1)
    {
        message     = JSGetArgmForString([arguments objectAtIndex:0]);
    }
    
    if (buttonLabel == nil)
        buttonLabel = @"确定";
    
    if (title == nil)
        title = @"提示";
    
    [ModalAlert modalAlertWithTitle:title Message:message andButton:buttonLabel];
    [self.curWebView becomeFirstResponder];
}
/*******************************************************************************
 接口调用：tmbWindow.confirm(inTitle,inMessage,inButtonLables)
 方法说明：弹出一个至少包含一个至多包含3个按钮的模态对话框。
 参数说明：
 　　// inTitle：对话框标题。
 　　// inMessage：对话内容。
 　　// inButtonLables：显示在按钮上的文字的集合（数组形式）。
 Callback方法：
    // tmbWindow.cbConfirm(opId,dataType,data)
 　　// opId:操作ID，在此函数中不起作用，可忽略
 　　// dataType: 返回数据的数据类型为整形(值为0)
 　　// data：返回的数据，用户点击的按钮索引(数组的索引)
 *******************************************************************************/
-(void)confirm:(NSMutableArray*)arguments
{
    NSString* title         = JSGetArgmForString([arguments objectAtIndex:0]);
    NSString* message       = JSGetArgmForString([arguments objectAtIndex:1]);
    NSString* buttonLabels  = JSGetArgmForString([arguments objectAtIndex:2]);
    NSArray* arrBtnLab = [buttonLabels componentsSeparatedByString:@","];
    
    NSUInteger buttonIndex = [ModalAlert modalConfirmWithTitle:title Message:message andButtons:arrBtnLab];
    NSString* strBtnIndex = [NSString stringWithFormat:@"%ld",(unsigned long)buttonIndex];
    
    [self setJsCallback:@"tmbWindow.cbConfirm" opId:0 dataType:0 data:strBtnIndex];
}

/*******************************************************************************
 接口调用：tmbWindow.prompt(inTitle,inMessage,inDefaultValue，inButtonLables)
 方法说明：弹出一个包含两个按钮且带输入框的模态对话框。
 参数说明：
 　　// inTitle：对话框标题。
 　　// inMessage：对话内容。
    // inDefaultValue：输入框的默认值。
 　　// inButtonLables: 显示在按钮上的文字的集合（数组形式）
 Callback方法：
 // tmbWindow.cbPrompt(opId,dataType,data)
 　　// opId:操作ID，在此函数中不起作用，可忽略
 　　// dataType: 返回数据的数据类型为整形(值为0)
 　　// data：返回的数据，返回用户点击模态对话框上的按钮索引及输入框中的值,格式为{"num":"0"," value":"xxx"}
 *******************************************************************************/
-(void)prompt:(NSMutableArray*)arguments
{
    NSString* title         = JSGetArgmForString([arguments objectAtIndex:0]);
    NSString* message       = JSGetArgmForString([arguments objectAtIndex:1]);
    NSString* text          = JSGetArgmForString([arguments objectAtIndex:2]);
    NSObject* buttonLabels  = (NSObject*)[arguments objectAtIndex:3];
    
    NSMutableString* value = [[NSMutableString alloc] initWithString:text];
    NSUInteger buttonIndex = [ModalAlert modalPromptWithTitle:title Message:message Value:value andButtons:buttonLabels];
    NSString* strData = [NSString stringWithFormat:@"{\"num\":\"%ld\",\"value\":\"%@\"}",(unsigned long)buttonIndex,value];
    
    [self setJsCallback:@"tmbWindow.cbPrompt" opId:0 dataType:0 data:strData];
}

/*******************************************************************************
 接口调用：tmbWindow.actionSheet(inTitle,inCancel,inButtonLables)
 方法说明：弹出一个包含一组选择按钮的对话框。对话框从设备屏幕底部自下而上弹出，并且最终停靠在屏幕底部。取消按钮也属于按钮组的一部分，因此，返回的按钮索引将大于等于0，小于等于inButtonLables的长度。
 参数说明：
 　　// inTitle：对话框标题。
 　　// inCancel：显示在取消按钮上的文本。
 　　// inButtonLables：选择按钮组的文本内容，数组形式。
 Callback方法：
    // tmbWindow.cbActionSheet(opId,dataType,data)
 　　// opId:操作ID，在此函数中不起作用，可忽略
 　　// dataType: 返回数据的数据类型为整形(值为0)
 　　// data：返回的数据，用户点击的按钮索引
 *******************************************************************************/
-(void)actionSheet:(NSMutableArray*)arguments
{
    NSString* title         = JSGetArgmForString([arguments objectAtIndex:0]);
    NSString* cancelButton  = JSGetArgmForString([arguments objectAtIndex:1]);
    NSString* strLabels     = JSGetArgmForString([arguments objectAtIndex:2]);
    NSArray* buttonLabels   = [strLabels componentsSeparatedByString:@","];
    
    self.actionSheetHandler = self.curWebView;
    
    UIActionSheet* sheet = [[UIActionSheet alloc] initWithTitle:title delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
    for(NSUInteger i=0; i<buttonLabels.count; i++)
        [sheet addButtonWithTitle:[buttonLabels objectAtIndex:i]];
    [sheet addButtonWithTitle:cancelButton];
    
    if (self.actionSheet)
        self.actionSheet = nil;
    [sheet showInView:self.actionSheetHandler];
//    如果使用showFromRect:inView必须要指明RECT，由于API没有这个参数，因此会造成iPad不显示
//    [sheet showFromRect:self.actionSheetHandler.bounds inView:self.actionSheetHandler animated:YES];

}
- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (self.actionSheetHandler != nil)
    {
        NSString* strIndex = [NSString stringWithFormat:@"%ld",(unsigned long)buttonIndex];
        [self setJsCallback:@"tmbWindow.cbActionSheet" opId:0 dataType:0 data:strIndex];
        self.actionSheetHandler = nil;
    }
}

/*******************************************************************************
 接口调用：tmbWindow.toast(inType,inLocation,inMsg,inDuration)
 方法说明：弹出一个非模态的消息提示框,可指定位置。
 参数说明：
 　　// inType：消息提示框显示的模式：0为没有进度条模式；1为有进度条模式。
 　　// inLocation：消息提示框在手机屏幕显示的位置。输入1-9之外的值，默认为5
    //      inLocation值	位置
    //      1	LEFT_TOP
    //      2	TOP
    //      3	RIGHT_TOP
    //      4	LEFT
    //      5	MIDDLE
    //      6	RIGHT
    //      7	BOTTOM_LEFT
    //      8	BOTTOM
    //      9	RIGHT_BOTTOM
    // inMsg：要提示的内容
    // inDuration: 提示框存在时间，小于等于零或者为空时，提示框一直存在，不自动关闭。
 Callback方法：无
 *******************************************************************************/
-(void)toast:(NSMutableArray*)arguments
{
    
    #define TOAST_VIEW_INTERVAL_X   10
    #define TOAST_VIEW_INTERVAL_Y   10
    #define MIN_TOAST_VIEW_WIDTH    120
    #define MIN_TOAST_VIEW_HEIGHT   80

    if (arguments.count<4) {
        MDMJSAlert(@"tmbWindow.toast:参数不正确!");
        return;
    }
    
    NSUInteger type         =  [JSGetArgmForNumber([arguments objectAtIndex:0])  unsignedIntegerValue];
    NSString* msg           =  JSGetArgmForString([arguments objectAtIndex:2]);
    float duration          =  [JSGetArgmForNumber([arguments objectAtIndex:3]) floatValue];
    
    if (self.toastView==nil)
    {
        UIView* view = [[UIView alloc] init];
        [view setBackgroundColor:[UIColor blackColor]];
        [view setAlpha:.8];
        view.layer.cornerRadius = 6;
        view.layer.masksToBounds = YES;
        
        // indicator
        UIActivityIndicatorView *indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        self.toastIndicator = indicator;
        
        // label
        UILabel* label = [[UILabel alloc] init];
        [label setFont:[UIFont systemFontOfSize:13]];
        [label setBackgroundColor:[UIColor clearColor]];
        [label setTextColor:[UIColor whiteColor]];
        [label setTextAlignment:NSTextAlignmentCenter];
        self.toastLabel = label;
        [view addSubview:label];
        self.toastView = view;
    }
    
    // 根据输入的msg参数计算显示窗口的大小
    CGSize textSize = [msg sizeWithFont:[self.toastLabel font]];
    int textWidth = textSize.width + 2 * TOAST_VIEW_INTERVAL_X;
    int width  = (textWidth > MIN_TOAST_VIEW_WIDTH) ? textWidth : MIN_TOAST_VIEW_WIDTH;
    int height = MIN_TOAST_VIEW_HEIGHT;
    
    CGRect appRect = [self.curWebView frame];
    int x = (appRect.size.width - width) / 2;
    int y = (appRect.size.height - height) / 2;
    self.toastView.frame = CGRectMake(x, y, width, height);
    NSLog(@"appRect:%@",NSStringFromCGRect(appRect));
    NSLog(@"toastView:%@",NSStringFromCGRect(self.toastView.frame));
    [self.toastLabel setText:msg];
    
    self.toastIndicator.center = CGPointMake(self.toastView.bounds.size.width/2, 30);
    self.toastView.hidden = NO;
    
    MDMAppDelegate *app = (MDMAppDelegate *)[UIApplication sharedApplication].delegate;
    
    [app.window addSubview:self.toastView];

    if (type != 0)
    {
        [self.toastView addSubview:self.toastIndicator];
        [self.toastIndicator startAnimating];
        
        self.toastLabel.frame = CGRectMake(TOAST_VIEW_INTERVAL_X, height-40, width-2*TOAST_VIEW_INTERVAL_X, 40);
    }
    else
    {
        self.toastLabel.frame = CGRectMake(TOAST_VIEW_INTERVAL_X, (height-textSize.height)/2, width-2*TOAST_VIEW_INTERVAL_X, textSize.height);
    }
    
    if (duration > 0)
    {
        CGFloat fDuration = duration / 1000.0;
        self.toastTimer = [NSTimer scheduledTimerWithTimeInterval:fDuration target:self selector:@selector(onToastTimer) userInfo:nil repeats:NO];
    }
    
    return;
}

-(void) onToastTimer
{
    if (self.toastView){
        
        [self.toastIndicator stopAnimating];
        [self.toastView removeFromSuperview];
        toastView = nil;
    }
    return;
}
/*******************************************************************************
 接口调用：tmbWindow.closeToast()
 方法说明：关闭提示框。
 参数说明：无
 Callback方法：无
 *******************************************************************************/
-(void)closeToast:(NSMutableArray*)arguments
{
    [self onToastTimer];
}

#pragma mark - Popover Window
/*******************************************************************************
 接口调用：tmbWindow.preOpenStart()
 方法说明：开始popOver(浮动窗口)的预加载。即一个窗口中需要有多个浮动窗口，可以让这些浮动窗口预先加
 载出来。其执行过程：A窗口打开B窗口，B窗口中需要预加载多个浮动窗口。那么A窗口中执行tmbWindow.open
 时，其flag参数需要：Window Flags设置为64配合使用，即open时有此flag，B窗口方可使用
 预加载。
 参数说明：无
 Callback方法：无
 *******************************************************************************/
-(void)preOpenStart:(NSMutableArray*)arguments
{
    NSLog(@"IOS No suport tmbWindow.preOpenStart");
}

/*******************************************************************************
 接口调用：tmbWindow.preOpenFinish()
 方法说明：结束popOver(浮动窗口)的预加载。
 参数说明：无
 Callback方法：无
 *******************************************************************************/
-(void)preOpenFinish:(NSMutableArray*)arguments
{
    NSLog(@"IOS No suport tmbWindow.preOpenFinish");
}

/*******************************************************************************
 接口调用：tmbWindow.openPopover(inPopName,inDataType,inUrl,inData,inX,inY,inWidth,inHeight,inFontSize,inFlag)
 方法说明：在当前window 中Open一个浮动窗口。
 参数说明：
 　　// inPopName: 窗口的名字。不可为空。当Window中已经存在名为inPopName的浮动窗口时，openPopover函数将直接跳转至此 Popover，并用此Popover执行相关操作。
 　　// inDataType: 指定窗口载入的数据的类型。0表示url方式载入；1表示html内容方式载入，2表示既有url方式，又有html内容方式
 　　// inUrl: url类型数据.
 　　// inData: data类型数据
 　　// inX: Popover在window中的x位置。
 　　// inY: Popover在window中的y位置。
 　　// inWidth: Popover的宽度。接受不含小数的整数，可为空，为空或0时，默认为window的宽度。
 　　// inHeight: Popover的高度。接受不含小数的整数, 可为空, 为空或0时，默认为window的高度。
 　　// inFontSize: Popover的全局默认字体大小。接受不含小数的整数。
 　　// inFlag: 标记。附录常量表中Window Flags。
 Callback方法：无
 *******************************************************************************/
-(void)openPopover:(NSMutableArray*)arguments
{
    NSString* popName   = JSGetArgmForString([arguments objectAtIndex:0]);
    NSInteger dataType  = [JSGetArgmForNumber([arguments objectAtIndex:1])  integerValue];
    NSString* url       = JSGetArgmForString([arguments objectAtIndex:2]);
    NSString* data      = JSGetArgmForString([arguments objectAtIndex:3]);
    NSInteger x         = [JSGetArgmForNumber([arguments objectAtIndex:4])  integerValue];
    NSInteger y         = [JSGetArgmForNumber([arguments objectAtIndex:5])  integerValue];
    NSInteger w         = [JSGetArgmForNumber([arguments objectAtIndex:6])  integerValue];
    NSInteger h         = [JSGetArgmForNumber([arguments objectAtIndex:7])  integerValue];
    //NSInteger fontSize  = [JSGetArgmForNumber([arguments objectAtIndex:8])  integerValue];
    //NSInteger flag      = [JSGetArgmForNumber([arguments objectAtIndex:9])  integerValue];
    

    if (w == 0)
        w = [[UIScreen mainScreen] bounds].size.width;
    
    CGRect frame = CGRectMake(x, y, w, h);
    
    MDMWebView *execWebView = [self getMainView];
    
    [execWebView openPopoverWindow:popName withDataType:dataType URL:url Data:data AndFrame:frame];
}

/*******************************************************************************
 接口调用：tmbWindow.closePopover(inPopName)
 方法说明：关闭当前window中指定name的Popover。
 参数说明：
    // inPopName: 已打开浮动窗口的name，不可为空。
 Callback方法：无
 *******************************************************************************/
-(void)closePopover:(NSMutableArray*)arguments
{
    NSString* popName = JSGetArgmForString([arguments objectAtIndex:0]);
    
    if (popName && popName.length > 0)
    {
        [self.curWebView closePopoverWindow:popName];
    }
}

/*******************************************************************************
 接口调用：tmbWindow.setPopoverFrame(inPopName,inX,inY,inWidth,inHeight)
 方法说明：更改指定name的Popover的位置和大小。
 参数说明：
 　　// inPopName: 已打开浮动窗口的name。
 　　// inX: 新的x位置
 　　// inY: 新的y位置
 　　// inWidth: 新的宽度
 　　// inHeight: 新的高度
 Callback方法：无
 *******************************************************************************/
-(void)setPopoverFrame:(NSMutableArray*)arguments
{
    NSString* popName   = JSGetArgmForString([arguments objectAtIndex:0]);
    NSInteger x         = [JSGetArgmForNumber([arguments objectAtIndex:1])  integerValue];
    NSInteger y         = [JSGetArgmForNumber([arguments objectAtIndex:2])  integerValue];
    NSInteger w         = [JSGetArgmForNumber([arguments objectAtIndex:3])  integerValue];
    NSInteger h         = [JSGetArgmForNumber([arguments objectAtIndex:4])  integerValue];

    if (popName && popName.length>0)
    {
        UIWebView* popView = [self.curWebView.popoverWindows objectForKey:popName];
        if (popView)
        {
            CGRect frame = CGRectMake(x, y, w, h);
            [popView setFrame:frame];
        }
    }
}

/*******************************************************************************
 接口调用：tmbWindow.evaluatePopoverScript(inPopName,inPopName,inScript)
 方法说明：指定window中的名为inPopName的浮动窗口执行js脚本。
 参数说明：
 　　// inWndName: Popover所在window的名称，可为空，为空时默认为当前窗口。
 　　// inPopName: Popover的name，不可为空。
 　　// inScript: js脚本内容
 Callback方法：无
 *******************************************************************************/
-(void)evaluatePopoverScript:(NSMutableArray*)arguments
{
    NSString* windowName    = JSGetArgmForString([arguments objectAtIndex:0]);
    NSString* popName       = JSGetArgmForString([arguments objectAtIndex:1]);
    NSString* script        = JSGetArgmForString([arguments objectAtIndex:2]);
    
    MDMWebView *execWebView = [self getMainView];
    
    if (execWebView.widget!=nil)
    {
       execWebView = [execWebView.widget webViewWithName:windowName];
        
        if (execWebView!=nil && popName!=nil && popName.length>0 && script!=nil && script.length>0)
            [execWebView evaluateScript:script AtPopoverWindow:popName];
    }
}

/*******************************************************************************
 接口调用：tmbWindow.bringToFront(inPopName)
 方法说明：将当前窗口指定name的Popover显示在最上层。
 参数说明：
 　　// inPopName: Popover的name，不可为空。
 Callback方法：无
 *******************************************************************************/
-(void)bringToFront:(NSMutableArray*)arguments
{
    NSString* popName       = JSGetArgmForString([arguments objectAtIndex:0]);
    if (popName && popName.length>0)
    {
        MDMWebView *execWebView = [self getMainView];
        UIWebView* popView = [execWebView.popoverWindows objectForKey:popName];
        
        if (popView)
        {
            [execWebView bringSubviewToFront:popView];
        }
    }
}

#pragma mark - Animation methods

/*******************************************************************************
 接口调用：tmbWindow.beginAnimition()
 方法说明：开始设置Popover(浮动窗口)动画的相关参数。
 参数说明：无
 Callback方法：无
 *******************************************************************************/
-(void)beginAnimition:(NSMutableArray*)arguments
{
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDelegate:self.curWebView];
}

/*******************************************************************************
 接口调用：tmbWindow.setAnimitionDelay(inDelay)
 方法说明：设定Popover(浮动窗口)动画的延迟执行时间。
 参数说明：
    // inDelay: 延迟执行的时间。单位为毫秒。默认为0，即立即执行。
 Callback方法：无
 *******************************************************************************/
-(void)setAnimitionDelay:(NSMutableArray*)arguments
{
    int delay = [JSGetArgmForNumber([arguments objectAtIndex:0]) intValue];
    [UIView setAnimationDelay:delay/1000.0];
}

/*******************************************************************************
 接口调用：tmbWindow.setAnimitionDuration(inDuration)
 方法说明：设定Popover(浮动窗口)动画的持续时间。
 参数说明：
    // inDuration: 持续时间。单位为毫秒，大于等于0，默认为250毫秒。
 Callback方法：无
 *******************************************************************************/
-(void)setAnimitionDuration:(NSMutableArray*)arguments
{
    int duration = [JSGetArgmForNumber([arguments objectAtIndex:0]) intValue];
    [UIView setAnimationDuration:duration/1000.0];
}

/*******************************************************************************
 接口调用：tmbWindow.setAnimitionCurve(inCurve)
 方法说明：设定Popover(浮动窗口)的曲线类型。
 参数说明：
    // inCurve: 动画曲线类型，详见常量表中Window AnimCurveType。
    //      AnimaCurveNone(无运动曲线,做线性平滑运动)   0
    //      AnimaCurveEaseInOut(先加速后减速运动)   1
    //      AnimCurveEaseIn(加速运动)	2
    //      AnimCurveEaseOut(减速运动)	3
    //      AnimCurveLinear(动画线性平滑运动)	4
 Callback方法：无
 *******************************************************************************/
-(void)setAnimitionCurve:(NSMutableArray*)arguments
{
    int curve = [JSGetArgmForNumber([arguments objectAtIndex:0]) intValue];
    switch(curve)
    {
        case 1:
            [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
            break;
        case 2:
            [UIView setAnimationCurve:UIViewAnimationCurveEaseIn];
            break;
        case 3:
            [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
            break;
        case 4:
            [UIView setAnimationCurve:UIViewAnimationCurveLinear];
            break;
        case 0:
        default:
            break;
    }
}

/*******************************************************************************
 接口调用：tmbWindow.setAnimitionRepeatCount(inCurve)
 方法说明：设定Popover(浮动窗口)动画的重复次数。
 参数说明：
    // inCount: 重复次数，默认为0，即不重复。
 Callback方法：无
 *******************************************************************************/
-(void)setAnimitionRepeatCount:(NSMutableArray*)arguments
{
    int repeatCount = [JSGetArgmForNumber([arguments objectAtIndex:0]) intValue];
    [UIView setAnimationRepeatCount:repeatCount];
}

/*******************************************************************************
 接口调用：tmbWindow.setAnimitionAutoReverse(inReverse)
 方法说明：设定Popover(浮动窗口)是否在动画结束后恢复成动画前的位置或状态。
 参数说明：
    // inReverse: 是否恢复。0为false，1为true。默认为0。
 Callback方法：无
 *******************************************************************************/
-(void)setAnimitionAutoReverse:(NSMutableArray*)arguments
{
    int reverse = [JSGetArgmForNumber([arguments objectAtIndex:0]) intValue];
    [UIView setAnimationRepeatAutoreverses:((reverse!=0) ? YES : NO)];
}

/*******************************************************************************
 接口调用：tmbWindow.makeTranslation(inToX,inToY,inToZ)
 方法说明：设定Popover(浮动窗口)的Translation动画。Android上暂不支持Z轴平移
 参数说明：
 　　// inToX: 相对于当前位置的x轴方向上的平移距离，int型整数，负数或正数。
 　　// inToY: 相对于当前位置的y轴方向上的平移距离，int型整数，负数或正数。
 　　// inToZ: 相对于当前位置的z方向上的平移距离，int型整数，负数或正数。
 Callback方法：无
 *******************************************************************************/
-(void)makeTranslation:(NSMutableArray*)arguments
{
    int x = [JSGetArgmForNumber([arguments objectAtIndex:0]) intValue];
    int y = [JSGetArgmForNumber([arguments objectAtIndex:1]) intValue];
    int z = [JSGetArgmForNumber([arguments objectAtIndex:2]) intValue];
    
    self.curWebView.layer.transform = CATransform3DConcat(CATransform3DMakeTranslation(x, y, z),
                                                          self.curWebView.layer.transform);
}

/*******************************************************************************
 接口调用：tmbWindow.makeScale(inToX,inToY,inToZ)
 方法说明：设定Popover(浮动窗口)的Translation动画。Android上暂不支持Z轴平移
 参数说明：
 　　// inToX: 相对于当前大小的x轴方向上的放大倍率，大于0的float型数据。
 　　// inToY: 相对于当前大小的y轴方向上的放大倍率，大于0的float型数据。
 　　// inToZ: 相对于当前大小的z轴方向上的放大倍率，大于0的float型数据。
 Callback方法：无
 *******************************************************************************/
-(void)makeScale:(NSMutableArray*)arguments
{
    float x = [JSGetArgmForNumber([arguments objectAtIndex:0]) floatValue];
    float y = [JSGetArgmForNumber([arguments objectAtIndex:1]) floatValue];
    float z = [JSGetArgmForNumber([arguments objectAtIndex:2]) floatValue];
    
    self.curWebView.layer.transform = CATransform3DConcat(CATransform3DMakeScale(x, y, z),
                                                          self.curWebView.layer.transform);
}

/*******************************************************************************
 接口调用：tmbWindow.makeRotate(inDegrees,inToX,inToY,inToZ)
 方法说明：设定Popover(浮动窗口)的Rotate动画。目前只支持绕Z轴旋转。且android平台旋转后将会恢复原来的状态。
 参数说明：
 　　// inDegrees: 相对于当前角度的旋转度数，int型的负数或正数。
 　　// inX: 是否绕X轴旋转。0为false，1为true。
 　　// inY: 是否绕Y轴旋转。0为false，1为true。
 　　// inZ: 是否绕Z轴旋转。0为false，1为true。
 Callback方法：无
 *******************************************************************************/
-(void)makeRotate:(NSMutableArray*)arguments
{
    int degree = [JSGetArgmForNumber([arguments objectAtIndex:0]) intValue];
    int x      = [JSGetArgmForNumber([arguments objectAtIndex:1]) intValue];
    int y      = [JSGetArgmForNumber([arguments objectAtIndex:2]) intValue];
    int z      = [JSGetArgmForNumber([arguments objectAtIndex:3]) intValue];
    
    float angle = degree * M_PI / 180.0;
    
    self.curWebView.layer.transform = CATransform3DConcat(CATransform3DMakeRotation(angle, x, y, z),
                                                          self.curWebView.layer.transform);
}

/*******************************************************************************
 接口调用：tmbWindow.makeAlpha(inAlpha)
 方法说明：设定Popover(浮动窗口)的透明度。
 参数说明：
 　　// inAlpha: 相对于当alpha的值，0.0到1.0的float型数据。
 Callback方法：无
 *******************************************************************************/
-(void)makeAlpha:(NSMutableArray*)arguments
{
    float alpha = [JSGetArgmForNumber([arguments objectAtIndex:0]) floatValue];
    self.curWebView.alpha = alpha;
}

/*******************************************************************************
 接口调用：tmbWindow.commitAnimition()
 方法说明：提交已设置好相关参数的动画，当前Popover(浮动窗口)动画开始。所有参数的设置仅一次有效，动画完了后将清除。
 参数说明：无
 Callback方法：无
 *******************************************************************************/
-(void)commitAnimition:(NSMutableArray*)arguments
{
    [UIView commitAnimations];
}

#pragma mark - Other methods
-(void)getUrlQuery:(NSMutableArray*)arguments
{
    NSLog(@"IOS not support tmbWindow.getUrlQuery");
}

//tmbLog
- (void)openLog:(NSMutableArray*)arguments
{
    if ([arguments count]>1) {
        [[MDMStatisticsPlugin sharedInstance] openLog:[arguments objectAtIndex:0] mode:[[arguments objectAtIndex:1] boolValue]];
    }
}
-(void)sendLog:(NSMutableArray*)arguments
{
    NSString *strLog    = JSGetArgmForString([arguments objectAtIndex:0]);
    if ([MDMStatisticsPlugin sharedInstance].isDebug) {
        [[MDMStatisticsPlugin sharedInstance] sendDebugLog:strLog];
    } else {
        NSLog(@"----- JS LOG: %@",strLog);
    }
}
@end
