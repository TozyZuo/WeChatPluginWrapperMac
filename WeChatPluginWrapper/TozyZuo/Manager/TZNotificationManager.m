//
//  TZNotificationManager.m
//  WeChatPluginWrapper
//
//  Created by TozyZuo on 2018/9/21.
//  Copyright © 2018年 TozyZuo. All rights reserved.
//

#import "TZNotificationManager.h"
#import <CaptainHook/CaptainHook.h>
//#import <objc/runtime.h>


@interface _NSConcreteUserNotification : NSUserNotification
@end

CHDeclareClass(_NSConcreteUserNotification)
CHOptimizedMethod1(self, void, _NSConcreteUserNotification, setHasReplyButton, BOOL, hasReplyButton)
{
    if(!self.userInfo[@"forceDisplay"]) {
        CHSuper1(_NSConcreteUserNotification, setHasReplyButton, hasReplyButton);
    }
}

CHConstructor {
    CHLoadLateClass(_NSConcreteUserNotification);
    CHHook1(_NSConcreteUserNotification, setHasReplyButton);
}

@interface NSUserNotification (TZNotificationManager)
@property (nonatomic, assign) BOOL forceDisplay;
@property (nonatomic, strong) NSString *uuid;
@end

@implementation NSUserNotification (TZNotificationManager)

- (BOOL)forceDisplay
{
    return [self.userInfo[@"forceDisplay"] boolValue];
}

- (void)setForceDisplay:(BOOL)forceDisplay
{
    NSMutableDictionary *userInfo = [self.userInfo isKindOfClass:NSMutableDictionary.class] ? (NSMutableDictionary *)self.userInfo : self.userInfo.mutableCopy;
    userInfo[@"forceDisplay"] = @(forceDisplay);
    self.userInfo = userInfo;
}

- (NSString *)uuid
{
    return self.userInfo[@"uuid"];
}

- (void)setUuid:(NSString *)uuid
{
    NSMutableDictionary *userInfo = [self.userInfo isKindOfClass:NSMutableDictionary.class] ? (NSMutableDictionary *)self.userInfo : self.userInfo.mutableCopy;
    userInfo[@"uuid"] = uuid;
    self.userInfo = userInfo;
}

@end


@interface TZNotificationManager ()
<NSUserNotificationCenterDelegate>
@property (nonatomic, weak) id<NSUserNotificationCenterDelegate> wcDelegate;
@property (nonatomic, strong) NSMutableDictionary<NSString *, void (^)(NSUserNotification * _Nonnull)> *actions;
@end

@implementation TZNotificationManager

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.actions = [[NSMutableDictionary alloc] init];
        self.wcDelegate = [NSUserNotificationCenter defaultUserNotificationCenter].delegate;
        [NSUserNotificationCenter defaultUserNotificationCenter].delegate = self;
    }
    return self;
}

+ (BOOL)notificationEnable
{
    // TODO
    return YES;
//    return NSApp.enabledRemoteNotificationTypes & NSRemoteNotificationTypeAlert;
}

- (void)postNotificationWithMessage:(NSString *)message forceDisplay:(BOOL)forceDisplay buttonTitle:(NSString *)buttonTitle action:(void (^)(NSUserNotification * _Nonnull))action
{
    NSUserNotification *notification = [[NSUserNotification alloc] init];
    notification.informativeText = message;
    notification.userInfo = [[NSMutableDictionary alloc] init];
    notification.forceDisplay = forceDisplay;
    notification.uuid = [NSUUID UUID].UUIDString;
    notification.hasActionButton = YES;
    notification.actionButtonTitle = buttonTitle;
    [notification setValue:@YES forKey:@"_showsButtons"];
    if (action) {
        self.actions[notification.uuid] = [action copy];
    }

    [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
}

#pragma mark - NSUserNotificationCenterDelegate

- (void)userNotificationCenter:(NSUserNotificationCenter *)center didDeliverNotification:(NSUserNotification *)notification
{
    NSString *uuid = notification.uuid;

    if (uuid) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(15 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            self.actions[uuid] = nil;
        });
    } else {
        if ([self.wcDelegate respondsToSelector:_cmd]) {
            [self.wcDelegate userNotificationCenter:center didDeliverNotification:notification];
        }
    }
}

- (void)userNotificationCenter:(NSUserNotificationCenter *)center didActivateNotification:(NSUserNotification *)notification
{
    if (notification.uuid) {
        void (^action)(NSUserNotification *) = self.actions[notification.uuid];
        if (action) {
            action(notification);
        }
    } else {
        if ([self.wcDelegate respondsToSelector:_cmd]) {
            [self.wcDelegate userNotificationCenter:center didActivateNotification:notification];
        }
    }
}

- (BOOL)userNotificationCenter:(NSUserNotificationCenter *)center shouldPresentNotification:(NSUserNotification *)notification
{
    BOOL wcResult = NO;
    if ([self.wcDelegate respondsToSelector:_cmd]) {
        wcResult = [self.wcDelegate userNotificationCenter:center shouldPresentNotification:notification];
    }
    return wcResult || [notification.userInfo[@"forceDisplay"] boolValue];
}

@end
