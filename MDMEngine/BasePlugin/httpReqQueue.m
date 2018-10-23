//
//  httpReqQueue.m
//  MDMEngine
//
//  Created by 李华林 on 15/9/14.
//  Copyright (c) 2015年 李华林. All rights reserved.
//

#import "httpReqQueue.h"
#import <objc/message.h>

@interface httpCombinedOperation : NSObject <httpBaseOperation>

@property (assign, nonatomic, getter = isCancelled) BOOL cancelled;
@property (copy, nonatomic) void (^cancelBlock)();

@end

@interface httpReqQueue ()

@property (strong, nonatomic, readwrite) httpReqObject *httpSender;
@property (strong, nonatomic) NSMutableArray *failedURLs;
@property (strong, nonatomic) NSMutableArray *runningOperations;

@end

@implementation httpReqQueue
+ (id)sharedManager
{
    static dispatch_once_t once;
    static id instance;
    dispatch_once(&once, ^{instance = self.new;});
    return instance;
}

- (id)init
{
    if ((self = [super init]))
    {
        _httpSender = [httpReqObject new];
        _failedURLs = [NSMutableArray new];
        _runningOperations = [NSMutableArray new];
    }
    return self;
}


- (NSString *)cacheKeyForURL:(NSURL *)url
{
    if (self.cacheKeyFilter)
    {
        return self.cacheKeyFilter(url);
    }
    else
    {
        return [url absoluteString];
    }
}
#pragma mark -
#pragma mark 获取网络状态
- (int)getNetWorkStates
{
    UIApplication *app = [UIApplication sharedApplication];
    NSArray *children = [[[app valueForKeyPath:@"statusBar"]valueForKeyPath:@"foregroundView"]subviews];
    
    int netType = 0;
    //获取到网络返回码(1:2G, 2:3G, 3:4G, 5:WIFI)
    for (id child in children) {
        if ([child isKindOfClass:NSClassFromString(@"UIStatusBarDataNetworkItemView")]) {
            //获取到状态栏
            netType = [[child valueForKeyPath:@"dataNetworkType"]intValue];
        }
    }
    //根据状态选择
    return netType;
}
- (id<httpBaseOperation>)requestWithURL:(NSURL *)url
                       headerFields:(NSDictionary*)headerFields
                               data:(NSData *)bodydata
                          completed:(httpReqObjectCompletedBlock)completedBlock
{
    // Very common mistake is to send the URL using NSString object instead of NSURL. For some strange reason, XCode won't
    // throw any warning for this type mismatch. Here we failsafe this error by allowing URLs to be passed as NSString.
    if ([url isKindOfClass:NSString.class])
    {
        url = [NSURL URLWithString:(NSString *)url];
    }
    
    // Prevents app crashing on argument type error like sending NSNull instead of NSURL
    if (![url isKindOfClass:NSURL.class])
    {
        url = nil;
    }
    
    __block httpCombinedOperation *operation = httpCombinedOperation.new;
    
    if (!url || !completedBlock)
    {
        if (completedBlock) completedBlock(nil,nil, nil, NO);
        return operation;
    }
    
    [self.runningOperations addObject:operation];
    
//    NSString *key = [self cacheKeyForURL:url];
    if (operation.isCancelled)
        return operation;
//    if (![self getNetWorkStates]) {
//        return operation;
//    }
    else {
        __block id<httpBaseOperation> subOperation = [self.httpSender httpTransmitObjectWithURL:url headerFields:headerFields data:bodydata completed:^(NSDictionary *headerField, NSData *data, NSError *error, BOOL finished) {
            completedBlock(headerFields,data, error, finished);
            if (error) {
                if (error.code != NSURLErrorNotConnectedToInternet
                    && error.code != NSURLErrorCancelled
                    && error.code != NSURLErrorCannotConnectToHost
                    && error.code != NSURLErrorNetworkConnectionLost
                    && error.code != NSURLErrorTimedOut) {
//                    [self.failedURLs addObject:url];
                }
            }
            if (finished) {
                [self.runningOperations removeObject:operation];
            }
        }];
        operation.cancelBlock = ^{[subOperation cancel];};
    }
    
    return operation;
}

- (void)cancelAll
{
    [self.runningOperations makeObjectsPerformSelector:@selector(cancel)];
    [self.runningOperations removeAllObjects];
}

- (BOOL)isRunning
{
    return self.runningOperations.count > 0;
}
@end

@implementation httpCombinedOperation

- (void)setCancelBlock:(void (^)())cancelBlock
{
    if (self.isCancelled)
    {
        if (cancelBlock) cancelBlock();
    }
    else
    {
        _cancelBlock = [cancelBlock copy];
    }
}

- (void)cancel
{
    self.cancelled = YES;
    if (self.cancelBlock)
    {
        self.cancelBlock();
        self.cancelBlock = nil;
    }
}

@end

