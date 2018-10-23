//
//  httpReqObject.m
//  MDMEngine
//
//  Created by 李华林 on 15/9/14.
//  Copyright (c) 2015年 李华林. All rights reserved.
//

#import "httpReqObject.h"

static NSString *const kCompletedCallbackKey = @"completedCallbackKey";

@interface httpReqObject ()

@property (strong, nonatomic) NSOperationQueue *transmitQueue;
@property (strong, nonatomic) NSMutableDictionary *URLCallbacks;
// This queue is used to serialize the handling of the network responses of all the download operation in a single queue
@property (strong, nonatomic) dispatch_queue_t workingQueue;
@property (strong, nonatomic) dispatch_queue_t barrierQueue;

@end

@implementation httpReqObject

+ (httpReqObject *)sharedHttpObject
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
        _transmitQueue = NSOperationQueue.new;
        _transmitQueue.maxConcurrentOperationCount = 5;
        _URLCallbacks = NSMutableDictionary.new;
        _workingQueue = dispatch_queue_create("henry.httpTransmitObject", DISPATCH_QUEUE_SERIAL);
        _barrierQueue = dispatch_queue_create("henry.httpTransmitObjectBarrierQueue", DISPATCH_QUEUE_CONCURRENT);
    }
    return self;
}

- (void)dealloc
{
    [self.transmitQueue cancelAllOperations];
    //    dispatch_release(_workingQueue);
    //    dispatch_release(_barrierQueue);
}

- (void)setMaxConcurrentConnects:(NSInteger)maxConcurrentConnects
{
    _transmitQueue.maxConcurrentOperationCount = maxConcurrentConnects;
}

- (NSInteger)maxConcurrentConnects
{
    return _transmitQueue.maxConcurrentOperationCount;
}

- (id<httpBaseOperation>)httpTransmitObjectWithURL:(NSURL *)url
                                  headerFields:(NSDictionary*)headerFields
                                          data:(NSData *)bodydata
                                     completed:(httpReqObjectCompletedBlock)completedBlock
{
    __block httpReqOperation *operation;
    __weak httpReqObject *wself = self;
    
    [self addProgressCallback:completedBlock forURL:url createCallback:^
     {
         // In order to prevent from potential duplicate caching (NSURLCache + SDImageCache) we disable the cache for image requests
         NSMutableURLRequest *request = [NSMutableURLRequest.alloc initWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData timeoutInterval:15];
         request.HTTPShouldHandleCookies = NO;
         request.HTTPShouldUsePipelining = YES;
         
         if (bodydata) {
             [request setHTTPMethod:@"POST"];
             [request setHTTPBody:bodydata];
             NSLog(@"body:%@",[[NSString alloc]initWithData:bodydata encoding:NSUTF8StringEncoding]);
             
             if (headerFields) {
                 NSEnumerator *enumerator = [headerFields keyEnumerator];
                 NSString *field = nil;
                 NSString *value = nil;
                 
                 while (field = [enumerator nextObject]) {
                     value = [headerFields objectForKey:field];
                     if (value) {
                         [request addValue:value forHTTPHeaderField:field];
                     }
                 }
             }
         } else {
             [request setHTTPMethod:@"GET"];
         }

         operation = [[httpReqOperation alloc] initWithRequest:request queue:wself.workingQueue completed:^(NSDictionary *Fields,NSData *data, NSError *error, BOOL finished)
                      {
                          if (!wself)
                              return;
                          httpReqObject *sself = wself;
                          NSArray *callbacksForURL = [sself callbacksForURL:url];
                          if (finished) {
                              [sself removeCallbacksForURL:url];
                          }
                          for (NSDictionary *callbacks in callbacksForURL) {
                              httpReqObjectCompletedBlock callback = callbacks[kCompletedCallbackKey];
                              if (callback) {
                                  callback(Fields,data, error, finished);
                              }
                          }
                      }
                                                                cancelled:^
                      {
                          if (!wself)
                              return;
                          httpReqObject *sself = wself;
                          [sself callbacksForURL:url];
                          [sself removeCallbacksForURL:url];
                      }];
         operation.httpMethod = ([request.HTTPMethod isEqualToString:@"POST"] ? httpWithPost : httpWithGet);
         [wself.transmitQueue addOperation:operation];
     }];
    
    return operation;
}

- (void)addProgressCallback:(void (^)(NSDictionary *headerFields,NSData *data, NSError *, BOOL))completedBlock forURL:(NSURL *)url createCallback:(void (^)())createCallback
{
    // The URL will be used as the key to the callbacks dictionary so it cannot be nil. If it is nil immediately call the completed block with no image or data.
    if(url == nil)
    {
        if (completedBlock != nil)
        {
            completedBlock(nil,nil, nil, NO);
        }
        return;
    }
    
    dispatch_barrier_sync(self.barrierQueue, ^
                          {
                              BOOL first = NO;
                              if (!self.URLCallbacks[url]) {
                                  self.URLCallbacks[url] = NSMutableArray.new;
                                  first = YES;
                              }
                              
                              // Handle single request of simultaneous send request for the same URL
                              NSMutableArray *callbacksForURL = self.URLCallbacks[url];
                              NSMutableDictionary *callbacks = NSMutableDictionary.new;
                              if (completedBlock) {
                                  callbacks[kCompletedCallbackKey] = [completedBlock copy];
                              }
                              [callbacksForURL addObject:callbacks];
                              self.URLCallbacks[url] = callbacksForURL;
                              
                              if (first) {
                                  createCallback();
                              }
                          });
}

- (NSArray *)callbacksForURL:(NSURL *)url
{
    __block NSArray *callbacksForURL;
    dispatch_sync(self.barrierQueue, ^
                  {
                      callbacksForURL = self.URLCallbacks[url];
                  });
    return callbacksForURL;
}

- (void)removeCallbacksForURL:(NSURL *)url
{
    dispatch_barrier_async(self.barrierQueue, ^
                           {
                               [self.URLCallbacks removeObjectForKey:url];
                           });
}

@end
