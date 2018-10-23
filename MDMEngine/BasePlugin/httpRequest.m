//
//  httpRequest.m
//  MDMEngine
//
//  Created by 李华林 on 15/9/14.
//  Copyright (c) 2015年 李华林. All rights reserved.
//

#import "httpRequest.h"

static char operationKey;
static httpRequest *httpSharedInstance = nil;

@implementation httpRequest

#pragma mark -
#pragma mark md5加密
-(NSString*)md5_32:(NSString*)input
{
    const char* str = [input UTF8String];
    unsigned  result[32];
    CC_MD5(str, (unsigned int)strlen(str), (unsigned char*)result);
    NSMutableString *ret = [NSMutableString stringWithCapacity:32];
    
    for(int i = 0; i<CC_MD5_DIGEST_LENGTH; i++) {
        [ret appendFormat:@"%02X",result[i]];
    }
    return ret;
}

#pragma mark -
#pragma mark http请求
+ (httpRequest *)sharedInstance
{
    static dispatch_once_t  onceToken;
    
    dispatch_once(&onceToken, ^{
        httpSharedInstance = [[httpRequest alloc] init];
    });
    return httpSharedInstance;
}
- (void)httpRequest:(NSString*)url Fields:(NSDictionary*)Fields body:(id)data completed:(httpCompletedBlock)completedBlock
{
    @try {
        if (url && url.length>0) {
            [self cancelCurrentHttpObjectRequest:url];
            NSURL *URL = [NSURL URLWithString:url];
            NSData *bodyData = nil;
            if ([data isKindOfClass:[NSDictionary class]]
                ||[data isKindOfClass:[NSMutableDictionary class]]) {
                NSError *error = nil;
                bodyData = [NSJSONSerialization dataWithJSONObject:data options:NSJSONWritingPrettyPrinted error: &error];
                if (error != nil) {
                    if (completedBlock) {
                        completedBlock(nil,nil,error,YES);
                    }
                    return;
                }
            }
            else if ([data isKindOfClass:[NSData class]]
                     ||[data isKindOfClass:[NSMutableData class]]) {
                bodyData = data;
            } else {
                if (completedBlock) {
                    NSString *description = NSLocalizedString(@"请求的数据格式错误", @"");
                    NSDictionary *errorDictionary = @{ NSLocalizedDescriptionKey : description};
                    NSError *error = [[NSError alloc] initWithDomain:NSPOSIXErrorDomain code:errno userInfo:errorDictionary];
                    completedBlock(nil,nil,error,YES);
                }
                return;
            }
            
            id<httpBaseOperation> operation = [[httpReqQueue sharedManager] requestWithURL:URL headerFields:Fields data:bodyData completed:^(NSDictionary *headerFields,NSData *data, NSError *error, BOOL finished) {
                if (completedBlock) {
                    completedBlock(headerFields,data,error,YES);
                }
            }];
            NSString *reqQueue = [self md5_32:url];
            objc_setAssociatedObject(reqQueue, &operationKey, operation, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }
    }
    @catch (NSException *exception) {
        NSLog(@"%s,\nNSException reason:%@",__func__,[exception reason]);
    }
    @finally {
        
    }
    
}
- (void)cancelCurrentHttpObjectRequest:(NSString*)url
{
    // Cancel in progress downloader from queue
    NSString *reqQueue = [self md5_32:url];
    id<httpBaseOperation> operation = objc_getAssociatedObject(reqQueue, &operationKey);
    if (operation)
    {
        [operation cancel];
        objc_setAssociatedObject(self, &operationKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
}

@end
