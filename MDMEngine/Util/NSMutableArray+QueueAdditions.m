//
//  NSMutableArray+QueueAdditions.m
//  MDMEngine
//
//  Created by 李华林 on 14/12/2.
//  Copyright (c) 2014年 李华林. All rights reserved.
//
//  支持队列的NSMutableArray扩展类
//

#import "NSMutableArray+QueueAdditions.h"

@implementation NSMutableArray (QueueAdditions)

- (id)queueHead
{
    if ([self count] == 0) {
        return nil;
    }
    return [self objectAtIndex:0];
}

- (__autoreleasing id)dequeue
{
    if ([self count] == 0) {
        return nil;
    }
    id head = [self objectAtIndex:0];
    if (head != nil) {
        [self removeObjectAtIndex:0];
    }
    return head;
}

- (id)pop
{
    return [self dequeue];
}

- (void)enqueue:(id)object
{
    [self addObject:object];
}

@end
