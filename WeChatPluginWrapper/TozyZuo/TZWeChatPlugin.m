//
//  TZWeChatPlugin.m
//  WeChatPluginWrapper
//
//  Created by TozyZuo on 2018/4/8.
//  Copyright © 2018年 TozyZuo. All rights reserved.
//

#import "TZWeChatPlugin.h"
#import "TZWeChatHeader.h"
//#import <WeChatPlugin_TKkk/WeChatPlugin.h>
//#import <WeChatPlugin_TKkk/TKHelper.h>
#import <objc/runtime.h>

static BOOL TZAddMethod(Class originalClass, SEL newMethodSelector, Class implementedClass, SEL implementedSelector)
{
    Method m = class_getInstanceMethod(implementedClass, implementedSelector);
    return class_addMethod(originalClass, newMethodSelector, method_getImplementation(m), method_getTypeEncoding(m));
}

static void tz_hookMethod(Class originalClass, SEL originalSelector, Class swizzledClass, SEL swizzledSelector) {
    Method originalMethod = class_getInstanceMethod(originalClass, originalSelector);
    Method swizzledMethod = class_getInstanceMethod(swizzledClass, swizzledSelector);
    if(originalMethod && swizzledMethod) {
        method_exchangeImplementations(originalMethod, swizzledMethod);
    }
}

static void tz_hookClassMethod(Class originalClass, SEL originalSelector, Class swizzledClass, SEL swizzledSelector) {
    Method originalMethod = class_getClassMethod(originalClass, originalSelector);
    Method swizzledMethod = class_getClassMethod(swizzledClass, swizzledSelector);
    if(originalMethod && swizzledMethod) {
        method_exchangeImplementations(originalMethod, swizzledMethod);
    }
}


@implementation NSObject (TZWeChatPlugin_MMChatMessageViewController)

- (void)tz_messageCellView:(id)arg1 didClickOnAvatarWithItem:(id)arg2
{
    [self tz_messageCellView:arg1 didClickOnAvatarWithItem:arg2];
}

- (id)MMMessageTableItem_init
{
    return [self MMMessageTableItem_init];
}

@end



@implementation NSObject (TZWeChatPlugin)

+ (void)TZWeChatPluginInit
{
    tz_hookMethod(objc_getClass("MMChatMessageViewController"), @selector(messageCellView:didClickOnAvatarWithItem:), [self class], @selector(tz_messageCellView:didClickOnAvatarWithItem:));
//    TZAddMethod(objc_getClass("MMChatMessageViewController"), @selector(messageCellView:didClickOnAvatarWithItem:), [self class], @selector(tz_messageCellView:didClickOnAvatarWithItem:));
}

@end

static void __attribute__((constructor)) initialize(void)
{
    [NSObject TZWeChatPluginInit];
}
