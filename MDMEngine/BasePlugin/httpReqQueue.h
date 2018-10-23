//
//  httpReqQueue.h
//  MDMEngine
//
//  Created by 李华林 on 15/9/14.
//  Copyright (c) 2015年 李华林. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "httpBaseOperation.h"
#import "httpReqObject.h"

@interface httpReqQueue : NSObject

@property (strong, nonatomic, readonly) httpReqObject *httpSender;
@property (strong) NSString *(^cacheKeyFilter)(NSURL *url);

+ (httpReqQueue *)sharedManager;
- (id<httpBaseOperation>)requestWithURL:(NSURL *)url
                           headerFields:(NSDictionary*)headerFields
                                   data:(NSData *)bodydata
                              completed:(httpReqObjectCompletedBlock)completedBlock;
- (void)cancelAll;
- (BOOL)isRunning;

@end
