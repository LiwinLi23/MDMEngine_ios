#import "MDMWebView.h"
#import "MDMEngine.h"
#import "MDMWebViewJsBridge.h"

@interface MDMWebView()
@property (nonatomic, weak) id<MDMEngineWebViewDelegate> engineDelegate;
@end

@implementation MDMWebView

- (void)_init
{
    _popoverWindows = [[NSMutableDictionary alloc] initWithCapacity:3];
    _embededWindows = [[NSMutableArray alloc] initWithCapacity:3];
    self.clipsToBounds = YES;
    _windowByName = MDM_WindowByName_Common; //默认为通用窗口
    
    self.engineDelegate = [MDMEngine shareEngine];
}

- (id)init
{
    self = [super init];
    if (self)
        [self _init];
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
        [self _init];
    return self;
}

-(void)dealloc
{
    self.delegate = nil;
    [self stopLoading];

    [_popoverWindows removeAllObjects];
    _popoverWindows = nil;
    [_embededWindows removeAllObjects];
    _embededWindows = nil;
    _headerView = nil;
    _footerView = nil;
}

#pragma mark - Slibing Windows
//辅助窗口函数，用于打开头部和底部窗口,而且只能用于打开头部和底部窗口使用
-(void) openSlibing:(NSUInteger)slibingType     //窗口类型  1:头部，2底部
       withDataType:(NSUInteger)dataType        //页面载入类型
                URL:(NSString*)url              //URL地址
               Data:(NSString*)data             //数据
              Width:(CGFloat)width              //头部或底部宽
             Height:(CGFloat)height             //头部或底部高
{
    UIInterfaceOrientation interfaceOrientation = [UIApplication sharedApplication].statusBarOrientation;
    if (UIInterfaceOrientationIsLandscape(interfaceOrientation))
    {
        width = MDM_SCREEN_HEIGHT;
    }
    else
    {
        width = MDM_SCREEN_WIDTH;
    }
    
    MDMWebView* slibingView = nil;
    switch (slibingType)
    {
        case 1: //设置headerView属性
        {
            CGRect slibingRect = CGRectMake(self.frame.origin.x, 0, width, height);
            if (!self.headerView)
            {
                self.headerView = [[MDMWebView alloc] initWithFrame:slibingRect];
                self.headerView.windowByName = MDM_WindowByName_Header;
                [self addSubview:self.headerView];
            }
            else
            {
                self.headerView.frame = slibingRect;
            }
            self.headerView.delegate = self;
            [self.headerView setHidden:YES];
            slibingView = self.headerView;
            break;
        }
            
        case 2: //设置footerView属性
        {
            CGRect slibingRect = CGRectMake(self.frame.origin.x,
                                            self.frame.origin.y + self.frame.size.height - height,
                                            width, height);
            if (MDM_IOS_VERSION>=7) {
                slibingRect.origin.y -= 20;
            }
            if (!self.footerView)
            {
                self.footerView = [[MDMWebView alloc] initWithFrame:slibingRect];
                self.footerView.windowByName = MDM_WindowByName_Footer;
                [self addSubview:self.footerView];
            }
            else
            {
                self.footerView.frame = slibingRect;
            }
            self.footerView.delegate = self;
            [self.footerView setHidden:YES];
            slibingView = self.footerView;
            break;
        }
            
        default:
            return;
    }
    
    if (slibingView)  //如果创建的是顶部和顶部VIEW，则需要禁止滚动，从而固定它们.
    {
        if ([slibingView respondsToSelector:@selector(scrollView)])
        {
            ((UIScrollView *) [slibingView scrollView]).bounces = NO;
        }
        else
        {
            for (id subview in slibingView.subviews)
                if ([[subview class] isSubclassOfClass: [UIScrollView class]])
                    ((UIScrollView *)subview).bounces = NO;
        }
    }
    
    switch(dataType)
    {
        case 0: //URL方式载入模式
        {
            if (url)
            {
                NSURL* reqURL = [NSURL URLWithString:url relativeToURL:self.baseURL];
                NSURLRequest* req = [NSURLRequest requestWithURL:reqURL cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:20.0];
                [slibingView loadRequest:req];
            }
            break;
        }
            
        case 1: //HTML内容载入模式
        {
            if (data)
            {
                [slibingView loadHTMLString:data baseURL:self.baseURL];
            }
            break;
        }
            
        case 2://HTML+URL载入模式
        {
            NSError* err = nil;
            NSURL* reqURL = [NSURL URLWithString:url relativeToURL:self.baseURL];
            NSString* htmlString = [NSString stringWithContentsOfURL:reqURL encoding:NSUTF8StringEncoding error:&err];
            if (htmlString && data)
            {
                NSMutableString* mutableHtmlString = [NSMutableString stringWithString:htmlString];
                [mutableHtmlString appendString:data];
                [mutableHtmlString appendString:@"</body></html>"];
                [slibingView loadHTMLString:mutableHtmlString baseURL:reqURL];
            }
            break;
        }
    }
}

//关闭头部和底部窗口 1:头部，2底部
-(void) closeSlibing:(NSUInteger)slibingType
{
    switch(slibingType)
    {
        case 1:
        {
            if (self.headerView)
            {
                [self.headerView removeFromSuperview];
                self.headerView = nil;
            }
            break;
        }
            
        case 2:
        {
            if (self.footerView)
            {
                [self.footerView removeFromSuperview];
                self.footerView = nil;
            }
            break;
        }
    }
}

//显示头部和底部窗口 1:头部，2底部
-(void) showSlibing:(NSUInteger)slibingType
{
    switch(slibingType)
    {
        case 1:
        {
            if (_headerView)
            {
                [_headerView setHidden:NO];
                [self bringSubviewToFront:_headerView];
                
                [self stringByEvaluatingJavaScriptFromString:@"if(window.tmbOnshow) window.tmbOnshow(1);"];
            }
            break;
        }
        
        case 2:
        {
            if (_footerView)
            {
                [_footerView setHidden:NO];
                [self bringSubviewToFront:_footerView];
                
                [self stringByEvaluatingJavaScriptFromString:@"if(window.tmbOnshow) window.tmbOnshow(2);"];
            }
            break;
        }
    }
}

#pragma mark - popover Windows

-(MDMWebView*) popoverWindowWithName:(NSString *)name
{
    if (name && name.length>0)
    {
        if (!self.popoverWindows)
            self.popoverWindows = [[NSMutableDictionary alloc] initWithCapacity:3];
        
        MDMWebView* theWebView = [self.popoverWindows objectForKey:name];
        if (theWebView == nil)
        {
            theWebView = [[MDMWebView alloc] init];
            theWebView.viewController = self.viewController;
            theWebView.widget = self.widget;
            theWebView.delegate = theWebView;
            theWebView.windowName = name;
            theWebView.windowType = kWindowTypePopover;
            self.engineDelegate   = [MDMEngine shareEngine];
            [self.popoverWindows setObject:theWebView forKey:name];
        }
        return theWebView;
    }
    else
    {
        return nil;
    }
}

//在当前WINDOW中打开一个浮动窗口
-(void) openPopoverWindow:(NSString *)popName withDataType:(NSUInteger)dataType URL:(NSString *)url Data:(NSString *)data AndFrame:(CGRect)frame
{
    MDMWebView* popoverWindow = [self popoverWindowWithName:popName];
    if (popoverWindow)
    {
        popoverWindow.delegate = self;
        
        // 设置背景透明
        popoverWindow.backgroundColor = [UIColor clearColor];
        [popoverWindow setOpaque:NO];
        
        [self addSubview:popoverWindow];
        
        popoverWindow.frame = frame;
        
        // 禁止滚动
        if ([popoverWindow respondsToSelector:@selector(scrollView)])
        {
            ((UIScrollView *) [popoverWindow scrollView]).bounces = NO;
        }
        else
        {
            for (id subview in popoverWindow.subviews)
                if ([[subview class] isSubclassOfClass:[UIScrollView class]])
                    ((UIScrollView *)subview).bounces = NO;
        }
        
        switch(dataType)
        {
            case 0: // url方式载入
            {
                if (url)
                {
                    NSRange range;
                    NSString* fullURL = nil;
                    range = [url rangeOfString:@"://"];
                    if (range.location != NSNotFound) {
                        fullURL = [NSString stringWithString:url];
                    }
                    else {
                        NSString* baseURLPath = [self.baseURL path];
                        range = [baseURLPath rangeOfString:@".htm"];
                        if (range.location != NSNotFound)
                            baseURLPath = [baseURLPath stringByDeletingLastPathComponent];
                        
                        fullURL = [NSString stringWithFormat:@"file://localhost/%@/%@", baseURLPath, url];
                    }
                    
                    NSLog(@"full URL: %@", fullURL);
                    
                    NSURL* reqURL = [NSURL URLWithString:[fullURL stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
                    NSLog(@"open popover, full url: %@", [reqURL absoluteString]);
                    
                    NSURLRequest* req = [NSURLRequest requestWithURL:reqURL cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:20.0];
                    
                    [popoverWindow loadRequest:req];
                }
                break;
            }
                
            case 1: // html内容方式载入
            {
                if (data)
                {
                    [popoverWindow loadHTMLString:data baseURL:self.baseURL];
                }
                break;
            }
                
            case 2: // 既有url方式，又有html内容方式
            {
                NSError* err = nil;
                NSURL* reqURL = [NSURL URLWithString:url relativeToURL:self.baseURL];
                NSLog(@"popover request url: %@", [reqURL absoluteString]);
                NSString* htmlString = [NSString stringWithContentsOfURL:reqURL encoding:NSUTF8StringEncoding error:&err];
                if (htmlString && data)
                {
                    NSMutableString* mutableHtmlString = [NSMutableString stringWithString:htmlString];
                    [mutableHtmlString appendString:data];
                    [mutableHtmlString appendString:@"</body></html>"];
                    [popoverWindow loadHTMLString:mutableHtmlString baseURL:self.baseURL];
                }
                break;
            }
        }
    }
}

//关闭指定的浮动窗口
-(void) closePopoverWindow:(NSString *)popName
{
    MDMWebView* popoverWindow = nil;
    if (self.popoverWindows) {
        popoverWindow = [self.popoverWindows objectForKey:popName];
    }
    //当前窗体没有就到父窗体去查询是否有这个POPOVER
    if (popoverWindow==nil && self.superview && [self.superview isKindOfClass:[MDMWebView class]]) {
        MDMWebView* parentView = (MDMWebView *)(self.superview);
        popoverWindow = [parentView.popoverWindows objectForKey:popName];
    }
    
    if (popoverWindow)
    {
        [popoverWindow removeFromSuperview];
        [self.popoverWindows removeObjectForKey:popName];
    }
}

//在指定的浮动窗口中执行JS脚本
-(void) evaluateScript:(NSString *)script AtPopoverWindow:(NSString *)popName
{
    MDMWebView* popoverWindow = [self popoverWindowWithName:popName];
    if (popoverWindow)
    {
        [popoverWindow stringByEvaluatingJavaScriptFromString:script];
    }
}

#pragma mark - Embeded Windows
//添加其它窗口
- (void)addEmbededWindow:(UIView *)embededWindow
{
    if (embededWindow)
    {
        [_embededWindows addObject:embededWindow];
        [self addSubview:embededWindow];
    }
}

//移除其它窗口
- (void)removeEmbededWindow:(UIView *)embededWindow
{
    if (embededWindow)
    {
        [_embededWindows removeObject:embededWindow];
        [embededWindow removeFromSuperview];
    }
}

#pragma mark - CAAnimationDelegate

//动画开始
- (void)animationDidStart:(CAAnimation *)anim
{
    NSLog(@"%@: animation start!, %@", self.windowName, NSStringFromCGRect(self.frame));
    
    [self stringByEvaluatingJavaScriptFromString:@"if(tmbWindow.onAnimationStart) tmbWindow.onAnimationStart();"];
}

//动画结束
- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag
{
    NSLog(@"%@: animation finished!, %@", self.windowName, NSStringFromCGRect(self.frame));
    
    [self stringByEvaluatingJavaScriptFromString:@"if(tmbWindow.onAnimationFinish) tmbWindow.onAnimationFinish();"];
}

#pragma mark UIWebViewDelegate

- (void) webViewDidStartLoad:(UIWebView*)theWebView
{
    //传递消息给engine进一步处理
    SEL sentAction = @selector(webViewDidStartLoad:theWebView:);
    if(_engineDelegate && [_engineDelegate respondsToSelector:sentAction])
    {
        [self.engineDelegate webViewDidStartLoad:self.widget theWebView:self];
    }
    return;
}

- (void) webViewDidFinishLoad:(UIWebView*)theWebView
{
    //注入JS桥接
    [[MDMWebViewJsBridge shareBridge] webViewWithBaseBridge:theWebView];
    //注入JS API
    [[MDMWebViewJsBridge shareBridge] webViewWithPluginAPI:theWebView];
    
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    
    // 通知js框架web内容调入完成
    if (theWebView)
    {
        if (theWebView == self.headerView)
        {
            [self stringByEvaluatingJavaScriptFromString:@"if(window.tmbOnload) window.tmbOnload(1);"];
        }
        else if (theWebView == self.footerView)
        {
            [self stringByEvaluatingJavaScriptFromString:@"if(window.tmbOnload) window.tmbOnload(2);"];
        }
        else
        {
            [theWebView stringByEvaluatingJavaScriptFromString:@"if(window.tmbOnload) window.tmbOnload(0);"];
        }
    }
    
    //通知engine进一步处理web页面载入事件
    SEL sentAction = @selector(webViewDidFinishLoad:theWebView:);
    if(_engineDelegate && [_engineDelegate respondsToSelector:sentAction])
    {
        [self.engineDelegate webViewDidFinishLoad:self.widget theWebView:(MDMWebView*)theWebView];
    }
    return;
}

- (void) webView:(UIWebView*)theWebView didFailLoadWithError:(NSError*)error
{
    if ([error code] != NSURLErrorCancelled)
    {
        NSString* errMsg = @"提示";
        if (theWebView == self.headerView)
        {
            errMsg = @"头部载入出错";
        }
        else if (theWebView == self.footerView)
        {
            errMsg = @"底部载入出错";
        }
        else
        {
            errMsg = @"浮动窗口载入出错";
        }
        
        MDMAlert(errMsg, [error localizedDescription]);
    }
    
    SEL sentAction = @selector(webView:curWidget:didFailLoadWithError:);
    if(_engineDelegate && [_engineDelegate respondsToSelector:sentAction])
    {
        [self.engineDelegate webView:(MDMWebView*)theWebView curWidget:self.widget didFailLoadWithError:error];
    }
    return;
}

- (BOOL) webView:(UIWebView*)theWebView shouldStartLoadWithRequest:(NSURLRequest*)request navigationType:(UIWebViewNavigationType)navigationType
{
    BOOL bShould   = NO;
    SEL sentAction = @selector(webView:curWidget:shouldStartLoadWithRequest:);
    if(_engineDelegate && [_engineDelegate respondsToSelector:sentAction])
    {
        bShould = [self.engineDelegate webView:(MDMWebView*)theWebView curWidget:self.widget shouldStartLoadWithRequest:request];
    }
    
    return bShould;
}
@end
