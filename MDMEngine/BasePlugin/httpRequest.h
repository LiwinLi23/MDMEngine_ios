//
//  httpRequest.h
//  MDMEngine
//
//  Created by 李华林 on 15/9/14.
//  Copyright (c) 2015年 李华林. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CommonCrypto/CommonDigest.h>
#import "httpReqQueue.h"
#import "objc/runtime.h"
#import "httpBaseOperation.h"

typedef void(^httpCompletedBlock)(NSDictionary *headerFields,NSData *data, NSError *error, BOOL isFinish);

@interface httpRequest : NSObject

+ (httpRequest *)sharedInstance;

//http请求接口
- (void)httpRequest:(NSString*)url Fields:(NSDictionary*)Fields body:(id)data completed:(httpCompletedBlock)completedBlock;

@end
