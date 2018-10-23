//
//  ModalAlert.h
//  LS
//
//  Created by Jian Chen on 8/11/12.
//  Copyright (c) 2012 Temobi. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ModalAlert : NSObject

+(void) modalAlertWithTitle:(NSString*)title Message:(NSString*)message andButton:(NSString *)button;
+(NSUInteger) modalConfirmWithTitle:(NSString*)title Message:(NSString*)message andButtons:(NSObject*)buttons;
+(NSUInteger) modalPromptWithTitle:(NSString*)title Message:(NSString*)message Value:(NSMutableString*)value andButtons:(NSObject*)buttons;

+(BOOL) ask:(NSString *) question;
+(BOOL) confirm:(NSString *) statement;
@end
