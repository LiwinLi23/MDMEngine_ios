//
//  MDMWidgetPlugin.h
//  MDMEngine
//
//  Created by 李华林 on 14/12/10.
//  Copyright (c) 2014年 李华林. All rights reserved.
//

#import "MDMPlugin.h"

@interface MDMWidgetPlugin : MDMPlugin


-(void)startWidget:(NSMutableArray*)arguments;
-(void)finishWidget:(NSMutableArray*)arguments;
-(void)removeWidget:(NSMutableArray*)arguments;
-(void)isWidgetInstalled:(NSMutableArray*)arguments;
-(void)installWidget:(NSMutableArray*)arguments;
-(void)loadApp:(NSMutableArray*)arguments;
-(void)getWidgetInfo:(NSMutableArray*)arguments;
-(void)getOpenerInfo:(NSMutableArray*)arguments;
@end
