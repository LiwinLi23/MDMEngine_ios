//
//  MDMPluginConfigParser.m
//  MDMEngine
//
//  Created by 李华林 on 14/12/1.
//  Copyright (c) 2014年 李华林. All rights reserved.
//
//  MDM插件配置分析器
/**************************************************************************************************/
/*                                      修改日志                                                    */
/*修改日期：2015年5月19日                                                                            */
/*修改人员：李华林                                                                                   */
/*修改内容：增加统计插件到系统插件里，功能为统计APP使用时间和崩溃日志统计                                     */
/**************************************************************************************************/
/*修改日期：2015年6月15日                                                                            */
/*修改人员：李华林                                                                                   */
/*修改内容：xml解析的时候，禁止解析properties节点里的所有东西，因为里面有type节点与插件类型type节点冲突         */
/**************************************************************************************************/

#import "MDMPluginConfigParser.h"
#import "MDMDefine.h"


#define MDMPluginDict(plugName,ver,build,engine,class,author,desc)  \
[[NSMutableDictionary alloc] initWithObjectsAndKeys:\
plugName,XML_NameElement,\
ver,XML_VerElement,\
build,XML_BuildElement,\
engine,XML_EngineElement,\
class,XML_ClassNameNode,\
author,XML_AuthorNode,\
desc,XML_DescriptionNode,nil];


@interface MDMPluginConfigParser ()
{
    NSString* pluginName;
    NSString* element;
    NSMutableDictionary* tmpDict;
    BOOL isProperties;
}
@property (nonatomic, readwrite, strong) NSMutableDictionary* pluginsDict;
@end

@implementation MDMPluginConfigParser
@synthesize pluginsDict;

- (id)init
{
    self = [super init];
    if (self != nil) {
        self.pluginsDict = [[NSMutableDictionary alloc] init];
        [self loadBasePluginData];
        pluginName = nil;
        element = nil;
        tmpDict = nil;
        isProperties = NO;
    }
    return self;
}

-(void)dealloc
{
    [pluginsDict removeAllObjects];
    pluginsDict = nil;
}

//获取引擎提供的基础插件数据
-(void)loadBasePluginData
{
    //tmbWindow插件信息
    pluginsDict[@"tmbWindow"] = MDMPluginDict(@"tmbWindow", @"2.1.0", @"1", @"2.0.0", @"MDMWindowPlugin", @"李华林", @"")
    
    NSArray* arrWinMethod = [[NSArray alloc] initWithObjects:
                             @"open",
                             @"close",
                             @"evaluateScript",
                             @"openSlibing",
                             @"closeSlibing",
                             @"showSlibing",
                             @"forward",
                             @"back",
                             @"windowForward",
                             @"windowBack",
                             @"goBackTo",
                             @"goBack",
                             @"alert",
                             @"confirm",
                             @"prompt",
                             @"actionSheet",
                             @"toast",
                             @"closeToast",
                             @"preOpenStart",
                             @"preOpenFinish",
                             @"openPopover",
                             @"closePopover",
                             @"setPopoverFrame",
                             @"evaluatePopoverScript",
                             @"bringToFront",
                             @"beginAnimition",
                             @"commitAnimition",
                             @"setAnimitionDelay",
                             @"setAnimitionDuration",
                             @"setAnimitionCurve",
                             @"setAnimitionRepeatCount",
                             @"setAnimitionAutoReverse",
                             @"makeTranslation",
                             @"makeScale",
                             @"makeRotate",
                             @"makeAlpha",
                             @"getUrlQuery",
                             nil];
    
    [pluginsDict[@"tmbWindow"] setObject:arrWinMethod forKey:XML_MethodNode];
    
    //tmbWidget插件信息
    pluginsDict[@"tmbWidget"] = MDMPluginDict(@"tmbWidget", @"2.1.0", @"1", @"2.0.0", @"MDMWidgetPlugin", @"李华林", @"")
    
    NSArray* arrWidMethod = [[NSArray alloc] initWithObjects:
                             @"startWidget",
                             @"finishWidget",
                             @"removeWidget",
                             @"isWidgetInstalled",
                             @"installWidget",
                             @"loadApp",
                             @"getWidgetInfo",
                             @"getOpenerInfo",nil];
    [pluginsDict[@"tmbWidget"] setObject:arrWidMethod forKey:XML_MethodNode];
    
    //tmbWidgetOne插件信息
    pluginsDict[@"tmbWidgetOne"] = MDMPluginDict(@"tmbWidgetOne", @"2.1.0", @"1", @"2.0.0", @"MDMWidgetOnePlugin", @"李华林", @"")
    
    NSArray* arrWidOneMethod = [[NSArray alloc] initWithObjects:
                                @"getPlatform",
                                @"getCurrentWidgetInfo",
                                @"getMainWidgetId",
                                @"getPushMsg",
                                @"deletePushMsg",
                                @"cleanCache",
                                @"exit",nil];
    [pluginsDict[@"tmbWidgetOne"] setObject:arrWidOneMethod forKey:XML_MethodNode];
    
    //tmbLog插件信息
    pluginsDict[@"tmbLog"] = MDMPluginDict(@"tmbLog", @"2.1.0", @"1", @"2.0.0", @"MDMWindowPlugin", @"李华林", @"")
    
    NSArray* arrTmbLogMethod = [[NSArray alloc] initWithObjects:@"sendLog",@"openLog",nil];
    [pluginsDict[@"tmbLog"] setObject:arrTmbLogMethod forKey:XML_MethodNode];
    
    //tmbStatistics插件信息
    pluginsDict[@"tmbStatistics"] = MDMPluginDict(@"tmbLog", @"2.1.0", @"1", @"2.0.0", @"MDMWindowPlugin", @"李华林", @"")
    
    NSArray* arrTmbStatisticsMethod = [[NSArray alloc] initWithObjects:
                                       @"setStatistics",
                                       @"getStatistics",
                                       @"setCrashLog",
                                       @"getCrashLog", nil];
    [pluginsDict[@"tmbStatistics"] setObject:arrTmbStatisticsMethod forKey:XML_MethodNode];
}

- (void)parser:(NSXMLParser*)parser didStartElement:(NSString*)elementName namespaceURI:(NSString*)namespaceURI qualifiedName:(NSString*)qualifiedName attributes:(NSDictionary*)attributeDict
{
//    NSLog(@"elementName:%@,attribute:%@,qualifiedName:%@,namespaceURI:%@",elementName,attributeDict,qualifiedName,namespaceURI);
    if ([elementName isEqualToString:XML_PluginNode]) {
        
        pluginName = attributeDict[XML_NameElement];
        
        NSMutableDictionary* pluginDict = [[NSMutableDictionary alloc] init];
//        if (attributeDict[XML_TypeElement]) {
//            pluginDict[XML_TypeElement] = attributeDict[XML_TypeElement];
//        }
        if (attributeDict[XML_VerElement]) {
            pluginDict[XML_VerElement] = attributeDict[XML_VerElement];
        }
//        if (attributeDict[XML_BuildElement]) {
//            pluginDict[XML_BuildElement] = attributeDict[XML_BuildElement];
//        }
        if (attributeDict[XML_EngineElement]) {
            pluginDict[XML_EngineElement] = attributeDict[XML_EngineElement];
        }
        pluginsDict[pluginName] = pluginDict;
    }
    else if (pluginName) {
        if ((isProperties == NO)&&([elementName isEqualToString:XML_ClassNameNode] ||
            [elementName isEqualToString:XML_AuthorNode] ||
            [elementName isEqualToString:XML_DescriptionNode] ||
            [elementName isEqualToString:XML_ClassCnNameNode] ||
            [elementName isEqualToString:XML_TypeNode] ||
            [elementName isEqualToString:XML_MethodNode])) {
            
            element = elementName;
            tmpDict = pluginsDict[pluginName];
        }
        else if([elementName isEqualToString:XML_PropertiesNode]) {
            isProperties = YES;
        }
//        else if([elementName isEqualToString:XML_MethodNode]){
//            NSMutableArray* arrMethodNode = nil;
//            if (![pluginsDict[pluginName] objectForKey:XML_MethodNode]) {
//                arrMethodNode = [[NSMutableArray alloc] init];
//                [arrMethodNode addObject:attributeDict[XML_NameElement]];
//                [pluginsDict[pluginName] setObject:arrMethodNode forKey:XML_MethodNode];
//            }
//            else{
//                arrMethodNode = [pluginsDict[pluginName] objectForKey:XML_MethodNode];
//                [arrMethodNode addObject:attributeDict[XML_NameElement]];
//            }
//        }
//        else if ([elementName isEqualToString:XML_ReleaseNoteNode]) {
//            NSMutableArray* arrReleaseNode = nil;
//            if (![pluginsDict[pluginName] objectForKey:XML_ReleaseNoteNode]) {
//                arrReleaseNode = [[NSMutableArray alloc] init];
//                [arrReleaseNode addObject:attributeDict[XML_NameElement]];
//                [pluginsDict[pluginName] setObject:arrReleaseNode forKey:XML_ReleaseNoteNode];
//            }
//            else{
//                arrReleaseNode = [pluginsDict[pluginName] objectForKey:XML_MethodNode];
//                [arrReleaseNode addObject:attributeDict[XML_NameElement]];
//            }
//        }
    }
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{
    if ([elementName isEqualToString:XML_PluginNode]) {
        pluginName = nil;
        element = nil;
        tmpDict = nil;
    }
    else if ([elementName isEqualToString:XML_PropertiesNode]) {
        isProperties = NO;
    }
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string
{
    if (pluginName && tmpDict) {
        if ([element isEqualToString:XML_MethodNode]) {
            NSMutableArray* arrMethodNode = nil;
            if (![tmpDict objectForKey:XML_MethodNode]) {
                arrMethodNode = [[NSMutableArray alloc] init];
                [arrMethodNode addObject:string];
                [tmpDict setObject:arrMethodNode forKey:XML_MethodNode];
            }
            else{
                arrMethodNode = [tmpDict objectForKey:XML_MethodNode];
                [arrMethodNode addObject:string];
            }
        }
        else if ([element isEqualToString:XML_ClassNameNode]) {
            [tmpDict setObject:string forKey:XML_ClassNameNode];
        }
        else if ([element isEqualToString:XML_AuthorNode]){
            [tmpDict setObject:string forKey:XML_AuthorNode];
        }
        else if ([element isEqualToString:XML_DescriptionNode]){
            [tmpDict setObject:string forKey:XML_DescriptionNode];
        }
        else if ([element isEqualToString:XML_ClassCnNameNode]) {
            [tmpDict setObject:string forKey:XML_ClassCnNameNode];
        }
        else if ([element isEqualToString:XML_TypeNode]) {
            [tmpDict setObject:string forKey:XML_TypeNode];
//            NSLog(@"+++++++string:%@,element:%@,info:%@",string,element,tmpDict);
        }
        element = nil;
        tmpDict = nil;
    }
}
@end
