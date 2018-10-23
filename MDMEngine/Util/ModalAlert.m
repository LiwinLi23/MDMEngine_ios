//
//  ModalAlert.m
//  LS
//
//  Created by Jian Chen on 8/11/12.
//  Copyright (c) 2012 Temobi. All rights reserved.
//

#import "ModalAlert.h"

enum
{
    MODAL_MESSAGE_BOX_ALERT             = 0,
    MODAL_MESSAGE_BOX_CONFIRM           = 1,
    MODAL_MESSAGE_BOX_WITH_TEXTFIELD    = 2,
}MODAL_MESSAGE_BOX_TYPE;

@interface ModalAlertDelegate : NSObject <UIAlertViewDelegate>
{
	CFRunLoopRef currentLoop;
	NSUInteger index;
}
@property (readonly) NSUInteger index;

@end

@implementation ModalAlertDelegate
@synthesize index;

// Initialize with the supplied run loop
-(id) initWithRunLoop: (CFRunLoopRef)runLoop 
{
	if (self = [super init]) currentLoop = runLoop;
	return self;
}

// User pressed button. Retrieve results
-(void) alertView: (UIAlertView*)aView clickedButtonAtIndex: (NSInteger)anIndex 
{
	index = anIndex;
	CFRunLoopStop(currentLoop);
}

//- (void)alertViewCancel:(UIAlertView *)alertView
//{
//	index = 0;
//	CFRunLoopStop(currentLoop);
//}

-(void)willPresentAlertView:(UIAlertView *)alertView
{
    // 成功提示设置自定义Fream
    if (alertView.tag == MODAL_MESSAGE_BOX_WITH_TEXTFIELD)
    {
        CGRect appFrame = [[UIScreen mainScreen] applicationFrame];
        int x = (appFrame.size.width - alertView.frame.size.width) / 2;
        int y = (appFrame.size.height - alertView.frame.size.height) / 2;
        CGRect viewRect = CGRectMake(x, y, alertView.frame.size.width, alertView.frame.size.height);
        
        viewRect.origin.y -= 20;
        viewRect.size.height += 40;
        alertView.frame = viewRect;
        
        for(UIView* view in alertView.subviews)
        {
            if([view isKindOfClass:[UIButton class]] )
            {
                CGRect btnFrame = view.frame;
                btnFrame.origin.y += 40;
                view.frame = btnFrame;
            }
        }
    }
}

@end

@implementation ModalAlert

+(void) modalAlertWithTitle:(NSString *)title Message:(NSString*)message andButton:(NSString *)button
{
	CFRunLoopRef currentLoop = CFRunLoopGetCurrent();
	
	// Create Alert
	ModalAlertDelegate *madelegate = [[ModalAlertDelegate alloc] initWithRunLoop:currentLoop];
	UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title message:message delegate:madelegate cancelButtonTitle:button otherButtonTitles:nil];
	[alertView show];
	
	// Wait for response
	CFRunLoopRun();
	
	// Retrieve answer
	[alertView release];
	[madelegate release];
}

+(NSUInteger) modalConfirmWithTitle:(NSString *)title Message:(NSString*)message andButtons:(NSObject*)buttons
{
	CFRunLoopRef currentLoop = CFRunLoopGetCurrent();
	
	// Create Alert
	ModalAlertDelegate *madelegate = [[ModalAlertDelegate alloc] initWithRunLoop:currentLoop];
	UIAlertView *alertView = nil;
    
    if ([buttons isKindOfClass:[NSArray class]])
    {
        NSUInteger count = [(NSArray*)buttons count];
        if (count == 0)
            alertView = [[UIAlertView alloc] initWithTitle:title message:message delegate:madelegate cancelButtonTitle:nil otherButtonTitles:nil];
        else if (count == 1)
            alertView = [[UIAlertView alloc] initWithTitle:title message:message delegate:madelegate cancelButtonTitle:nil otherButtonTitles:(NSString*)[(NSArray*)buttons objectAtIndex:0],nil];
        else if (count == 2)
            alertView = [[UIAlertView alloc] initWithTitle:title message:message delegate:madelegate cancelButtonTitle:nil otherButtonTitles:(NSString*)[(NSArray*)buttons objectAtIndex:0],(NSString*)[(NSArray*)buttons objectAtIndex:1],nil];
        else if (count >= 3)
            alertView = [[UIAlertView alloc] initWithTitle:title message:message delegate:madelegate cancelButtonTitle:nil otherButtonTitles:(NSString*)[(NSArray*)buttons objectAtIndex:0],(NSString*)[(NSArray*)buttons objectAtIndex:1],(NSString*)[(NSArray*)buttons objectAtIndex:2],nil];
    }
    else if ([buttons isKindOfClass:[NSString class]])
    {
        alertView = [[UIAlertView alloc] initWithTitle:title message:message delegate:madelegate cancelButtonTitle:nil otherButtonTitles:(NSString*)buttons,nil];
    }
	[alertView show];
//    [alertView becomeFirstResponder];
	
	// Wait for response
	CFRunLoopRun();
	
    NSUInteger buttonIndex = madelegate.index;
    
	// Retrieve answer
//    [alertView resignFirstResponder];
	[alertView release];
	[madelegate release];
    
    return buttonIndex;
}

+(NSUInteger) modalPromptWithTitle:(NSString*)title Message:(NSString*)message Value:(NSMutableString*)value andButtons:(NSObject*)buttons
{
    CFRunLoopRef currentLoop = CFRunLoopGetCurrent();
    
    ModalAlertDelegate* delegate = [[ModalAlertDelegate alloc] initWithRunLoop:currentLoop];
    UIAlertView* alertView = nil;
    
    if ([buttons isKindOfClass:[NSArray class]])
    {
        int count = (int)[(NSArray*)buttons count];
        if (count == 0)
            alertView = [[UIAlertView alloc] initWithTitle:title message:nil delegate:delegate cancelButtonTitle:nil otherButtonTitles:nil];
        else if (count == 1)
            alertView = [[UIAlertView alloc] initWithTitle:title message:nil delegate:delegate cancelButtonTitle:nil otherButtonTitles:(NSString*)[(NSArray*)buttons objectAtIndex:0],nil];
        else if (count == 2)
            alertView = [[UIAlertView alloc] initWithTitle:title message:nil delegate:delegate cancelButtonTitle:nil otherButtonTitles:(NSString*)[(NSArray*)buttons objectAtIndex:0],(NSString*)[(NSArray*)buttons objectAtIndex:1],nil];
        else if (count >= 3)
            alertView = [[UIAlertView alloc] initWithTitle:title message:nil delegate:delegate cancelButtonTitle:nil otherButtonTitles:(NSString*)[(NSArray*)buttons objectAtIndex:0],(NSString*)[(NSArray*)buttons objectAtIndex:1],(NSString*)[(NSArray*)buttons objectAtIndex:2],nil];
    }
    else if ([buttons isKindOfClass:[NSString class]])
    {
        alertView = [[UIAlertView alloc] initWithTitle:title message:nil delegate:delegate cancelButtonTitle:nil otherButtonTitles:(NSString*)buttons,nil];
    }
    
    //CGRect frame = [alertView frame];
    UITextField *textField = [[UITextField alloc] initWithFrame:CGRectMake(27.0, 60.0, 230.0, 25.0)];
    [textField setBackgroundColor:[UIColor whiteColor]];
    textField.text = value;
    alertView.tag = MODAL_MESSAGE_BOX_WITH_TEXTFIELD;
//    [textField setPlaceholder:@"起点"];
    textField.placeholder = message;
    
    [alertView addSubview:textField];

    CGAffineTransform transfrom = CGAffineTransformMakeTranslation(0, 30); //实现对控件位置的控制
    [alertView setTransform:transfrom];
    

    [textField release];

    [alertView show];
//    [alertView becomeFirstResponder];
     
    // Wait for response
    CFRunLoopRun();
    
    NSUInteger buttonIndex = delegate.index;
    [value setString:textField.text];
    
//    [alertView resignFirstResponder];
    [alertView release];
    [delegate release];
    
    return buttonIndex;    
}

+(NSUInteger) queryWith: (NSString *)question button1: (NSString *)button1 button2: (NSString *)button2
{
	CFRunLoopRef currentLoop = CFRunLoopGetCurrent();
	
	// Create Alert
	ModalAlertDelegate *madelegate = [[ModalAlertDelegate alloc] initWithRunLoop:currentLoop];
	UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:question message:nil delegate:madelegate cancelButtonTitle:button1 otherButtonTitles:button2, nil];
	[alertView show];
	
	// Wait for response
	CFRunLoopRun();
	
	// Retrieve answer
	NSUInteger answer = madelegate.index;
	[alertView release];
	[madelegate release];
	return answer;
}

+ (BOOL) ask: (NSString *) question
{
	return	[ModalAlert queryWith:question button1: @"No" button2: @"Yes"];
}

+ (BOOL) confirm: (NSString *) statement
{
	return	[ModalAlert queryWith:statement button1: @"Cancel" button2: @"OK"];
}

@end
