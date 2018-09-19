//
//  TZWindowController.m
//  WeChatPluginWrapper
//
//  Created by TozyZuo on 2018/9/18.
//  Copyright © 2018年 TozyZuo. All rights reserved.
//

#import "TZWindowController.h"
#import <objc/runtime.h>

@interface TZWindowController ()

@end

@implementation TZWindowController

void *TZWindowControllerKey = &TZWindowControllerKey;

+ (instancetype)sharedWindowController
{
    id _controller = objc_getAssociatedObject(self, TZWindowControllerKey);
    if (!_controller) {
        _controller = [[self alloc] initWithWindowNibName:NSStringFromClass(self)];
        objc_setAssociatedObject(self, TZWindowControllerKey, _controller, OBJC_ASSOCIATION_RETAIN);
    }
    return _controller;
}

- (void)windowDidLoad {
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

@end
