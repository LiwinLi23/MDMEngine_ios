//
//  httpReqObject.h
//  MDMEngine
//
//  Created by 李华林 on 15/9/14.
//  Copyright (c) 2015年 李华林. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "httpBaseOperation.h"
#import "httpReqOperation.h"

typedef void(^httpReqObjectCompletedBlock)(NSDictionary *headerField,NSData *data, NSError *error, BOOL finished);

@interface httpReqObject : NSObject

@property (assign, nonatomic) NSInteger maxConcurrentConnects;
+ (httpReqObject *)sharedHttpObject;

- (id<httpBaseOperation>)httpTransmitObjectWithURL:(NSURL *)url
                                  headerFields:(NSDictionary*)headerFields
                                          data:(NSData *)bodydata
                                     completed:(httpReqObjectCompletedBlock)completedBlock;

@end
