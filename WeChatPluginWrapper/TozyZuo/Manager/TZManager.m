//
//  TZManager.m
//  WeChatPluginWrapper
//
//  Created by TozyZuo on 2018/9/17.
//  Copyright © 2018年 TozyZuo. All rights reserved.
//

#import "TZManager.h"
#import <objc/runtime.h>

@implementation TZManager

void *TZManagerKey = &TZManagerKey;

+ (instancetype)sharedManager
{
    id _manager = objc_getAssociatedObject(self, TZManagerKey);
    if (!_manager) {
        _manager = [[self alloc] init];
        objc_setAssociatedObject(self, TZManagerKey, _manager, OBJC_ASSOCIATION_RETAIN);
    }
    return _manager;
}

@end
