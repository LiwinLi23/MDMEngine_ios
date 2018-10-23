//
//  MDMStatisticsPlugin.h
//  MDMEngine
//
//  Created by 李华林 on 15-5-15.
//  Copyright (c) 2015年 李华林. All rights reserved.
//

#import "MDMPlugin.h"

@interface MDMStatisticsPlugin : MDMPlugin

@property (nonatomic, readonly) BOOL isDebug;
@property (nonatomic, copy) NSString *developer;

+ (MDMStatisticsPlugin *)sharedInstance;
- (void)setStatistics:(NSMutableArray*)arguments;
- (void)getStatistics:(NSMutableArray*)arguments;
- (void)submitLastStatistics;
- (void)setCrashLog:(NSMutableArray*)arguments;
- (void)getCrashLog:(NSMutableArray*)arguments;
- (void)submitCrashLog;


//- (void)redirectSTD:(int )fd;
- (void)openLog:(NSString*)name mode:(BOOL)mode;
- (void)connect:(NSString *)developer;
- (void)closeconnect;
- (void)sendDebugLog:(NSString*)logs;
@end
