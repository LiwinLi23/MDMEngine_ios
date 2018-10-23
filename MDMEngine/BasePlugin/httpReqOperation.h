//
//  httpReqOperation.h
//  MDMEngine
//
//  Created by 李华林 on 15/9/14.
//  Copyright (c) 2015年 李华林. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "httpBaseOperation.h"
#import "httpReqObject.h"

typedef enum
{
    httpWithGet,
    httpWithPost,
} httpRequestMethod;

@interface httpReqOperation : NSOperation<httpBaseOperation>

@property (strong, nonatomic, readonly) NSURLRequest *request;
//@property (assign, nonatomic, readonly) httpReqOperation options;
@property (assign, nonatomic, readwrite) httpRequestMethod httpMethod;

- (id)initWithRequest:(NSURLRequest *)request queue:(dispatch_queue_t)queue completed:(void (^)(NSDictionary *headerFields,NSData *, NSError *, BOOL))completedBlock cancelled:(void (^)())cancelBlock;

@end
