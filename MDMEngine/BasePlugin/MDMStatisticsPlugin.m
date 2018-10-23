//
//  MDMStatisticsPlugin.m
//  MDMEngine
//
//  Created by 李华林 on 15-5-15.
//  Copyright (c) 2015年 李华林. All rights reserved.
//

#import "MDMStatisticsPlugin.h"
#import "MDMDefine.h"
#import "httpRequest.h"
#import "SRWebSocket.h"

#import <CommonCrypto/CommonDigest.h>
#include <sys/socket.h> // Per msqr
#include <sys/sysctl.h>
#include <net/if.h>
#include <net/if_dl.h>

//统计服务器地址
#define statisticsServerIP            @"120.24.162.176"
#define statisticsServerPort          @"8084"

#define kSERVICE_ROOT [NSString stringWithFormat:@"http://%@:%@/mdm/stat/",statisticsServerIP,statisticsServerPort]
#define kSERVICE_DEBUG [NSString stringWithFormat:@"ws://%@:%@/mdm/log/",statisticsServerIP,statisticsServerPort]
#define kComponentUrl(u) [NSString stringWithFormat:@"%@%@",kSERVICE_ROOT,u]
#define kComponentDebug(u) [NSString stringWithFormat:@"%@%@",kSERVICE_DEBUG,u]

//本地统计路径
#define ST_ListsDir ([NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0])
#define LSH_STATISTICS_LISTS_PATH ([ST_ListsDir stringByAppendingPathComponent:@"statisticsListsDict"])
#define LSH_ERRORLOG_LISTS_PATH ([ST_ListsDir stringByAppendingPathComponent:@"logListsDict"])

static MDMStatisticsPlugin *statisticsPlugin = nil;

@interface MDMStatisticsPlugin()<SRWebSocketDelegate>
{
    SRWebSocket *_webSocket;
    BOOL _isDebug;
    NSString *_developer;
    
//    NSMutableData *receiveData;
//    NSURL *responseUrl;
}
@end

@implementation MDMStatisticsPlugin

@synthesize isDebug = _isDebug;
@synthesize developer = _developer;

+ (MDMStatisticsPlugin *)sharedInstance
{
    static dispatch_once_t  onceToken;
    dispatch_once(&onceToken, ^{
        statisticsPlugin = [[MDMStatisticsPlugin alloc] init];
    });
    return statisticsPlugin;
}

- (id)init
{
    self = [super init];
    if (self) {
//        receiveData = [[NSMutableData alloc] init];
    }
    return self;
}
- (void)openLog:(NSString*)name mode:(BOOL)mode
{
    _isDebug = mode;
    _developer = [NSString stringWithFormat:@"%@",name];
    if (mode) {
        [self connect:_developer];
//        [self redirectSTD:STDOUT_FILENO];
//        [self redirectSTD:STDERR_FILENO];
    } else {
        if (_webSocket) {
            [self closeconnect];
        }
    }
    
}
#pragma mark -
#pragma mark 清除日志
// 清除统计列表文件
- (void)cleanStatistics
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSFileManager* fileMgr = [[NSFileManager alloc] init];
        NSError* __autoreleasing err = nil;
        BOOL result;
        result = [fileMgr removeItemAtPath:LSH_STATISTICS_LISTS_PATH error:&err];
        if (!result && err) {
            NSLog(@"Failed to delete: %@ (error: %@)", LSH_STATISTICS_LISTS_PATH, err);
        } else {
            NSLog(@"Clean statistics lists success");
        }
    });

//    [self submitCrashLog];
}
// 清除崩溃列表文件
- (void)cleanCrash
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSFileManager* fileMgr = [[NSFileManager alloc] init];
        NSError* __autoreleasing err = nil;
        BOOL result;
        result = [fileMgr removeItemAtPath:LSH_ERRORLOG_LISTS_PATH error:&err];
        if (!result && err) {
            NSLog(@"Failed to delete: %@ (error: %@)", LSH_ERRORLOG_LISTS_PATH, err);
        } else {
            NSLog(@"Clean crash lists success");
//            NSArray *testCrash = [[NSArray alloc] init];
//            NSLog(@"crash test:%@",[testCrash objectAtIndex:10]);
        }
    });
}
#pragma mark -
#pragma mark API接口
//存储崩溃日志
- (void)setCrashLog:(NSMutableArray*)arguments
{
    NSMutableArray *lists = [[NSMutableArray alloc] initWithCapacity:0];
    
    NSArray *arrLogs = [NSArray arrayWithContentsOfFile:LSH_ERRORLOG_LISTS_PATH];
    [arrLogs enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if ([obj isKindOfClass:[NSString class]]) {
            [lists addObject:obj];
        }
    }];
    [arguments enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if ([obj isKindOfClass:[NSString class]]) {
            [lists addObject:obj];
        }
    }];
//    NSLog(@"set crash list:%@",lists);
    [lists writeToFile:LSH_ERRORLOG_LISTS_PATH atomically:YES];
}
//获取崩溃日志
- (void)getCrashLog:(NSMutableArray*)arguments
{
    NSArray *arrStatistics = [NSArray arrayWithContentsOfFile:LSH_ERRORLOG_LISTS_PATH];
    if (arrStatistics) {
        [arrStatistics enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            NSLog(@"obj class:%@  value:%@",NSStringFromClass([obj class]),obj);
        }];
    }
}
//存储统计列表
-(void)setStatistics:(NSMutableArray*)arguments
{
    NSMutableArray *lists = [[NSMutableArray alloc] initWithCapacity:0];
    
    NSArray *arrStatistics = [NSArray arrayWithContentsOfFile:LSH_STATISTICS_LISTS_PATH];
    [arrStatistics enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if ([obj isKindOfClass:[NSDictionary class]]) {
            [lists addObject:obj];
        }
    }];
    [arguments enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if ([obj isKindOfClass:[NSDictionary class]]) {
            [lists addObject:obj];
        }
    }];
//    NSLog(@"set statistics list:%@",lists);
    [lists writeToFile:LSH_STATISTICS_LISTS_PATH atomically:YES];
}
//获取统计列表
-(void)getStatistics:(NSMutableArray*)arguments
{
    NSArray *arrStatistics = [NSArray arrayWithContentsOfFile:LSH_STATISTICS_LISTS_PATH];
    if (arrStatistics) {
        [arrStatistics enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            NSLog(@"obj class:%@  value:%@",NSStringFromClass([obj class]),obj);
        }];
    }
}

//向服务器提交统计
-(void)submitLastStatistics
{
    NSArray *arrStatistics = [NSArray arrayWithContentsOfFile:LSH_STATISTICS_LISTS_PATH];
    if (arrStatistics) {
        NSDictionary *body = @{@"appName" : MDM_APPID,
                               @"osVersion" : [NSString stringWithFormat:@"%@ %@",MDM_CurrentSystemName,MDM_CurrentSystemVersion],
                               @"platformType" : @(1),
                               @"phoneModel" : MDM_CurrentSystemModel,
                               @"imei" : [self imei],
                               @"appVersion" : @"2.1.0",
                               @"mdmVersion" : MDMENGINE_VERSION,
                               @"usingTimes" : arrStatistics};
        
//        NSURL *url = [NSURL URLWithString:kComponentUrl(@"app")];
//        [self sendWithUrl:url body:body];
        
        NSString *jsonString = nil;
        NSError *error;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:body
                                                           options:NSJSONWritingPrettyPrinted
                                                             error:&error];
        if (jsonData) {
            jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        }
        NSDictionary *header = @{@"Content-Type":@"application/json"};
        NSString *strBody = [NSString stringWithFormat:@"json=%@",jsonString];
        __weak MDMStatisticsPlugin *wself = self;
        [[httpRequest sharedInstance] httpRequest:kComponentUrl(@"app") Fields:header body:[strBody dataUsingEncoding:NSUTF8StringEncoding] completed:^(NSDictionary *headerFields, NSData *data, NSError *error, BOOL isFinish) {
            __strong MDMStatisticsPlugin *sself = wself;
            if (error==nil) {
                NSDictionary* obj = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
                if (obj) {
                    NSUInteger code = [[obj objectForKey:@"returnCode"] integerValue];
                    switch (code) {
                        case 200:
//                          NSLog(@"response:%@",responseUrl);
                            [sself performSelector:@selector(cleanStatistics) withObject:nil afterDelay:0.2];
                            break;
                            
                        default:
                            break;
                    }
                }
            }
        }];
    } else {
//        [self submitCrashLog];
    }
}

//向服务器提交崩溃日志
- (void)submitCrashLog
{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"YYYY-MM-dd HH:mm:ss"];
    NSString *dateTime = [formatter stringFromDate:[NSDate date]];
    
    NSArray *arrLog = [NSArray arrayWithContentsOfFile:LSH_ERRORLOG_LISTS_PATH];
    if (arrLog) {
        NSDictionary *body = @{@"appName" : MDM_APPID,
                               @"osVersion" : [NSString stringWithFormat:@"%@ %@",MDM_CurrentSystemName,MDM_CurrentSystemVersion],
                               @"platformType" : @(1),
                               @"phoneModel" : MDM_CurrentSystemModel,
                               @"imei" : [self imei],
                               @"appVersion" : @"2.1.0",
                               @"mdmVersion" : MDMENGINE_VERSION,
                               @"errorTime" : dateTime,
                               @"trace" : [arrLog componentsJoinedByString:@";"]};
        
//        NSURL *url = [NSURL URLWithString:kComponentUrl(@"errorlog")];
//        [self sendWithUrl:url body:body];
        
        NSString *jsonString = nil;
        NSError *error;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:body
                                                           options:NSJSONWritingPrettyPrinted
                                                             error:&error];
        if (jsonData) {
            jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        }
        NSDictionary *header = @{@"Content-Type":@"application/json"};
        NSString *strBody = [NSString stringWithFormat:@"json=%@",jsonString];
        __weak MDMStatisticsPlugin *wself = self;
        [[httpRequest sharedInstance] httpRequest:kComponentUrl(@"errorlog") Fields:header body:[strBody dataUsingEncoding:NSUTF8StringEncoding] completed:^(NSDictionary *headerFields, NSData *data, NSError *error, BOOL isFinish) {
            __strong MDMStatisticsPlugin *sself = wself;
            if (error==nil) {
                NSDictionary* obj = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
                if (obj) {
                    NSUInteger code = [[obj objectForKey:@"returnCode"] integerValue];
                    switch (code) {
                        case 200:
                            [sself performSelector:@selector(cleanCrash) withObject:nil afterDelay:0.2];
                            break;
                            
                        default:
                            break;
                    }
                }
            }
        }];
    }
}
- (void)connect:(NSString *)developer
{
    NSURL *url = [NSURL URLWithString:kComponentDebug(developer)];
    _webSocket.delegate = nil;
    [_webSocket close];
    
    _webSocket = [[SRWebSocket alloc] initWithURLRequest:[NSURLRequest requestWithURL:url]];
    _webSocket.delegate = self;
    [_webSocket open];
}
/*关闭连接*/
- (void)closeconnect
{
    _webSocket.delegate = nil;
    [_webSocket close];
    _webSocket = nil;
}
- (void)sendDebugLog:(NSString*)logs
{
//    ws://192.168.0.103:8080/mdm/log/{user}
    if (_webSocket) {
        [_webSocket send:logs];
    }
}

#pragma mark - SRWebSocketDelegate

- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)message
{
//    NSLog(@"receive messge form server:%@",message);
//    [receiveData appendFormat:@"%@",message];
}

- (void)webSocketDidOpen:(SRWebSocket *)webSocket
{
//    NSLog(@"websocket connect!");
}

- (void)webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error
{
//    NSLog(@"websocket Failed with error:%@",error);
    _webSocket = nil;
}

- (void)webSocket:(SRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean
{
    NSLog(@"sebsocket closed! reson:%@",reason);
    _webSocket = nil;
}
#pragma mark -
#pragma mark 获取MAC地址
- (NSString *)stringFromMD5:(NSString*)string{
    
    if(self == nil || [string length] == 0)
        return nil;
    
    const char *value = [string UTF8String];
    
    unsigned char outputBuffer[CC_MD5_DIGEST_LENGTH];
    CC_MD5(value, (uint32_t)strlen(value), outputBuffer);
    
    NSMutableString *outputString = [[NSMutableString alloc] initWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for(NSInteger count = 0; count < CC_MD5_DIGEST_LENGTH; count++){
        [outputString appendFormat:@"%02x",outputBuffer[count]];
    }
    
    return outputString;
}
- (NSString *)macaddress{
    
    int                 mib[6];
    size_t              len;
    char                *buf;
    unsigned char       *ptr;
    struct if_msghdr    *ifm;
    struct sockaddr_dl  *sdl;
    
    mib[0] = CTL_NET;
    mib[1] = AF_ROUTE;
    mib[2] = 0;
    mib[3] = AF_LINK;
    mib[4] = NET_RT_IFLIST;
    
    if ((mib[5] = if_nametoindex("en0")) == 0) {
        printf("Error: if_nametoindex error\n");
        return NULL;
    }
    
    if (sysctl(mib, 6, NULL, &len, NULL, 0) < 0) {
        printf("Error: sysctl, take 1\n");
        return NULL;
    }
    
    if ((buf = malloc(len)) == NULL) {
        printf("Could not allocate memory. error!\n");
        return NULL;
    }
    
    if (sysctl(mib, 6, buf, &len, NULL, 0) < 0) {
        printf("Error: sysctl, take 2");
        free(buf);
        return NULL;
    }
    
    ifm = (struct if_msghdr *)buf;
    sdl = (struct sockaddr_dl *)(ifm + 1);
    ptr = (unsigned char *)LLADDR(sdl);
    NSString *outstring = [NSString stringWithFormat:@"%02X:%02X:%02X:%02X:%02X:%02X",
                           *ptr, *(ptr+1), *(ptr+2), *(ptr+3), *(ptr+4), *(ptr+5)];
    free(buf);
    
    return outstring;
}
- (NSString *)imei {
    NSString *macaddress = [self macaddress];
    NSString *uniqueIdentifier = [self stringFromMD5:macaddress];
    
    return uniqueIdentifier;
}
- (void)redirectNotificationHandle:(NSNotification *)nf
{
    NSData *data = [[nf userInfo] objectForKey:NSFileHandleNotificationDataItem];
    NSString *str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    [self sendDebugLog:str];
    
    [[nf object] readInBackgroundAndNotify];
}

- (void)redirectSTD:(int )fd
{
    NSPipe * pipe = [NSPipe pipe] ;
    NSFileHandle *pipeReadHandle = [pipe fileHandleForReading] ;
    dup2([[pipe fileHandleForWriting] fileDescriptor], fd) ;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(redirectNotificationHandle:)
                                                 name:NSFileHandleReadCompletionNotification
                                               object:pipeReadHandle] ;
    [pipeReadHandle readInBackgroundAndNotify];
}
@end
