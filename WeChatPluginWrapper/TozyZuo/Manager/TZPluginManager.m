//
//  TZPluginManager.m
//  WeChatPluginWrapper
//
//  Created by TozyZuo on 2018/9/17.
//  Copyright © 2018年 TozyZuo. All rights reserved.
//

#import "TZPluginManager.h"

@interface TZPluginManager ()
@property (nonatomic, strong) NSMutableArray *appLifecycleClasses;
@end

@implementation TZPluginManager

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.appLifecycleClasses = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)registerAppLifecycleWithClass:(Class<TZManagerProtocol,NSApplicationDelegate>)class
{
    if (![self.appLifecycleClasses containsObject:class] &&
        [class conformsToProtocol:@protocol(TZManagerProtocol)] &&
        [class conformsToProtocol:@protocol(NSApplicationDelegate)])
    {
        [self.appLifecycleClasses addObject:class];
    }
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
    for (Class<TZManagerProtocol, NSApplicationDelegate> class in self.appLifecycleClasses)
    {
        [class.sharedManager applicationDidFinishLaunching:notification];
    }
}

@end
