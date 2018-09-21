//
//  TZNotificationManager.h
//  WeChatPluginWrapper
//
//  Created by TozyZuo on 2018/9/21.
//  Copyright © 2018年 TozyZuo. All rights reserved.
//

#import "TZManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface TZNotificationManager : TZManager
@property (class, readonly) BOOL notificationEnable;
- (void)postNotificationWithMessage:(NSString *)message forceDisplay:(BOOL)forceDisplay buttonTitle:(NSString *)buttonTitle action:(void(^)(NSUserNotification * notification))action;
@end

NS_ASSUME_NONNULL_END
