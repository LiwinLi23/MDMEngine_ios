//
//  httpReqOperation.m
//  MDMEngine
//
//  Created by 李华林 on 15/9/14.
//  Copyright (c) 2015年 李华林. All rights reserved.
//

#import "httpReqOperation.h"

@interface httpReqOperation ()
{
    
}
@property (strong, nonatomic) NSMutableData *ReceiveData;

@property (copy, nonatomic) httpReqObjectCompletedBlock completedBlock;
@property (copy, nonatomic) void (^cancelBlock)();

@property (assign, nonatomic, getter = isExecuting) BOOL executing;
@property (assign, nonatomic, getter = isFinished) BOOL finished;
@property (assign, nonatomic) long long expectedSize;
@property (retain, nonatomic) NSDictionary *headerFields;
@property (strong, nonatomic) NSURLConnection *connection;
@property (assign, nonatomic) dispatch_queue_t queue;

@end

@implementation httpReqOperation

@synthesize executing = _executing;
@synthesize finished = _finished;
@synthesize httpMethod = _httpMethod;

- (id)initWithRequest:(NSURLRequest *)request queue:(dispatch_queue_t)queue completed:(void (^)(NSDictionary *headerFields,NSData *, NSError *, BOOL))completedBlock cancelled:(void (^)())cancelBlock
{
    if ((self = [super init]))
    {
        _queue = queue;
        _request = request;
        _completedBlock = [completedBlock copy];
        _cancelBlock = [cancelBlock copy];
        _executing = NO;
        _finished = NO;
    }
    return self;
}

- (void)start
{
    dispatch_async(dispatch_get_main_queue(), ^
                   {
                       if (self.isCancelled)
                       {
                           self.finished = YES;
                           [self reset];
                           return;
                       }
                       
                       self.executing = YES;
                       self.connection = [NSURLConnection.alloc initWithRequest:self.request delegate:self startImmediately:NO];
                       
                       [self.connection start];
                       
                       if (!self.connection) {
                           if (self.completedBlock) {
                               self.completedBlock(nil,nil, [NSError errorWithDomain:NSURLErrorDomain code:0 userInfo:@{NSLocalizedDescriptionKey: @"Connection can't be initialized"}], YES);
                           }
                       }
                       
                   });
}

- (void)cancel
{
    if (self.isFinished) return;
    [super cancel];
    if (self.cancelBlock) self.cancelBlock();
    
    if (self.connection) {
        [self.connection cancel];
        // As we cancelled the connection, its callback won't be called and thus won't
        // maintain the isFinished and isExecuting flags.
        if (self.isExecuting) self.executing = NO;
        if (!self.isFinished) self.finished = YES;
    }
    
    [self reset];
}

- (void)done
{
    self.finished = YES;
    self.executing = NO;
    [self reset];
}

- (void)reset
{
    dispatch_async(dispatch_get_main_queue(), ^
                   {
                       self.cancelBlock = nil;
                       self.completedBlock = nil;
                       self.connection = nil;
                   });
}

- (void)setFinished:(BOOL)finished
{
    [self willChangeValueForKey:@"isFinished"];
    _finished = finished;
    [self didChangeValueForKey:@"isFinished"];
}

- (void)setExecuting:(BOOL)executing
{
    [self willChangeValueForKey:@"isExecuting"];
    _executing = executing;
    [self didChangeValueForKey:@"isExecuting"];
}

- (BOOL)isConcurrent
{
    return YES;
}

#pragma mark NSURLConnection (delegate)

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    //    NSLog(@"response method:%d",self.httpMethod);
    if (![response respondsToSelector:@selector(statusCode)] || [((NSHTTPURLResponse *)response) statusCode] < 600) {
        NSUInteger expected = response.expectedContentLength > 0 ? (NSUInteger)response.expectedContentLength : 0;
        self.expectedSize = expected;
        
        dispatch_async(self.queue, ^
                       {
                           self.ReceiveData = [NSMutableData.alloc initWithCapacity:expected];
                           self.headerFields = [(NSHTTPURLResponse *)response allHeaderFields];
                       });
    } else {
        [self.connection cancel];
        
        if (self.completedBlock) {
            self.completedBlock(nil,nil, [NSError errorWithDomain:NSURLErrorDomain code:[((NSHTTPURLResponse *)response) statusCode] userInfo:nil], YES);
        }
        
        [self done];
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
//    NSLog(@"Received data");
    dispatch_async(self.queue, ^
                   {
                       [self.ReceiveData appendData:data];
//                       NSUInteger received = self.ReceiveData.length;
                       dispatch_async(dispatch_get_main_queue(), ^
                                      {
//                                          if (self.progressBlock) {
//                                              self.progressBlock(received, self.expectedSize);
//                                          }
                                      });
                   });
}

- (void)connectionDidFinishLoading:(NSURLConnection *)aConnection
{
    //    NSLog(@"finish loading method:%d",self.httpMethod);
    self.connection = nil;
    httpReqObjectCompletedBlock completionBlock = self.completedBlock;
    if (completionBlock)
    {
        dispatch_async(self.queue, ^
                       {
                           dispatch_async(dispatch_get_main_queue(), ^
                                          {
                                              completionBlock(self.headerFields,self.ReceiveData, nil, YES);
                                              self.completionBlock = nil;
                                              [self done];
                                          });
                       });
    }
    else
    {
        [self done];
    }
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    if (self.completedBlock) {
        self.completedBlock(nil,nil, error, YES);
    }
    
    [self done];
}

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse
{
    // Prevents caching of responses
    return nil;
}


@end
