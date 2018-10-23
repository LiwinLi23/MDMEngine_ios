//
//  NSMutableArray+QueueAdditions.h
//  MDMEngine
//
//  Created by 李华林 on 14/12/2.
//  Copyright (c) 2014年 李华林. All rights reserved.
//
//  支持队列的NSMutableArray扩展类
//

#import <Foundation/Foundation.h>

@interface NSMutableArray (QueueAdditions)

- (id)pop;
- (id)queueHead;
- (id)dequeue;
- (void)enqueue:(id)obj;

@end
