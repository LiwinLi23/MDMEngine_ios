//
//  MDMWidgetOnePlugin.h
//  MDMEngine
//
//  Created by 李华林 on 14/12/10.
//  Copyright (c) 2014年 李华林. All rights reserved.
//

#import "MDMPlugin.h"

@interface MDMWidgetOnePlugin : MDMPlugin

-(void)getPlatform:(NSMutableArray*)arguments;
-(void)getCurrentWidgetInfo:(NSMutableArray*)arguments;
-(void)getMainWidgetId:(NSMutableArray*)arguments;
-(void)getPushMsg:(NSMutableArray*)arguments;
-(void)deletePushMsg:(NSMutableArray*)arguments;
-(void)cleanCache:(NSMutableArray*)arguments;
-(void)exit:(NSMutableArray*)arguments;
@end
