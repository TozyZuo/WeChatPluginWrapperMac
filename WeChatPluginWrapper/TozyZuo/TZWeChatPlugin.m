//
//  TZWeChatPlugin.m
//  WeChatPluginWrapper
//
//  Created by TozyZuo on 2018/4/8.
//  Copyright © 2018年 TozyZuo. All rights reserved.
//

#import "TZWeChatPlugin.h"
#import "TZWeChatHeader.h"
#import "TZWeChatPluginMenuManager.h"
#import "TZWeChatPluginConfig.h"
#import "NSDate+TZCategory.h"
#import <CaptainHook/CaptainHook.h>
#import <objc/runtime.h>

static NSString *TZTimeStringFromTime(NSTimeInterval time)
{
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:time];

    static NSDateFormatter *formatter;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        formatter = [[NSDateFormatter alloc] init];
    });

    if (date.isThisYear && ![TZWeChatPluginConfig sharedConfig].displayWholeTimeEnable)
    {
        if (date.isToday)
        {
            formatter.dateFormat = @"ahh:mm:ss";
            return [formatter stringFromDate:date];
        }
        else if (date.isYesterday)
        {
            formatter.dateFormat = @"ahh:mm:ss";
            return [NSString stringWithFormat:@"昨天 %@", [formatter stringFromDate:date]];
        }
        else if ((ABS([[NSDate date] timeIntervalSinceDate:date]) < D_WEEK))
        {
            formatter.dateFormat = @"ahh:mm:ss";
            NSString *time = [formatter stringFromDate:date];
            formatter.dateFormat = @"EEEE";
            return [NSString stringWithFormat:@"%@ %@", [formatter stringFromDate:date], time];
        }
        else
        {
            formatter.dateFormat = @"MM-dd ahh:mm:ss";
            return [formatter stringFromDate:date];
        }
    } else {
        formatter.dateFormat = @"yyyy-MM-dd ahh:mm:ss";
        return [formatter stringFromDate:date];
    }

    return [formatter stringFromDate:date];
}

CHDeclareClass(MMMessageCellView)
// 控制UI layout
CHOptimizedMethod0(self, BOOL, MMMessageCellView, showGroupChatNickName)
{
    if (TZWeChatPluginConfig.sharedConfig.timeDisplayEnable) {
        return self.messageTableItem.shouldShowGroupChatDisplayName;
    } else {
        return CHSuper0(MMMessageCellView, showGroupChatNickName);
    }
}

CHOptimizedMethod1(self, void, MMMessageCellView, populateWithMessage, id, arg1)
{
    CHSuper1(MMMessageCellView, populateWithMessage, arg1);

    if (TZWeChatPluginConfig.sharedConfig.timeDisplayEnable) {
        NSTextField *groupChatNickNameLabel = self.groupChatNickNameLabel;
        CGFloat height = groupChatNickNameLabel.height;
        [groupChatNickNameLabel sizeToFit];
        groupChatNickNameLabel.height = height;

        if (self.messageTableItem.isOrientationRight) {

            groupChatNickNameLabel.autoresizingMask = NSViewMinXMargin | NSViewMinYMargin;

            CGFloat right = self.avatarImgView.left - 10;
            // 微信自己的setRight只是改变width
            CGRect frame = groupChatNickNameLabel.frame;
            frame.origin.x = groupChatNickNameLabel.left + right - groupChatNickNameLabel.right;
            groupChatNickNameLabel.frame = frame;
        }
    }
}

CHDeclareClass(MMMessageTableItem)
// 控制文案显示
CHOptimizedMethod0(self, BOOL, MMMessageTableItem, shouldShowGroupChatDisplayName)
{
    if (TZWeChatPluginConfig.sharedConfig.timeDisplayEnable) {
        switch (self.type) {
            case 0: // other
                return YES;
            case 1: // MMTimeStampCellView
            case 2: // MMMessageTypingCellView
            case 3: // MMMacHelperGuideCellView
            case 7: // StripeMessageCellView
            default:
                break;
        }
    }
    return CHSuper0(MMMessageTableItem, shouldShowGroupChatDisplayName);
}

CHDeclareClass(MessageData)
CHOptimizedMethod0(self, NSString *, MessageData, groupChatSenderDisplayName)
{
    NSString *str = CHSuper0(MessageData, groupChatSenderDisplayName);
    if (TZWeChatPluginConfig.sharedConfig.timeDisplayEnable) {
        return [str stringByAppendingFormat:@" %@", TZTimeStringFromTime(self.msgCreateTime)];
    }
    return str;
}

CHDeclareClass(MMTimeStampCellView)
CHOptimizedClassMethod2(self, double, MMTimeStampCellView, cellHeightWithMessage, id, arg1, constrainedToWidth, double, arg2)
{
    if (TZWeChatPluginConfig.sharedConfig.timeDisplayEnable &&
        TZWeChatPluginConfig.sharedConfig.hideWeChatTimeEnable)
    {
        return -7;
    }
    return CHSuper2(MMTimeStampCellView, cellHeightWithMessage, arg1, constrainedToWidth, arg2);
}

CHDeclareClass(AppDelegate)
CHOptimizedMethod1(self, void, AppDelegate, applicationDidFinishLaunching, id, arg1)
{
    CHSuper1(AppDelegate, applicationDidFinishLaunching, arg1);
    [[TZWeChatPluginMenuManager shareManager] configMenus];
}

CHConstructor {
    CHLoadLateClass(AppDelegate);
    CHHook1(AppDelegate, applicationDidFinishLaunching);

    CHLoadLateClass(MessageData);
    CHHook0(MessageData, groupChatSenderDisplayName);

    CHLoadLateClass(MMMessageTableItem);
    CHHook0(MMMessageTableItem, shouldShowGroupChatDisplayName);

    CHLoadLateClass(MMMessageCellView);
    CHHook0(MMMessageCellView, showGroupChatNickName);
    CHHook1(MMMessageCellView, populateWithMessage);
//    CHHook0(MMMessageCellView, updateGroupChatNickName); 这个看似不错实际不行

    CHLoadLateClass(MMTimeStampCellView);
    CHClassHook2(MMTimeStampCellView, cellHeightWithMessage, constrainedToWidth);
}

#pragma mark - AutoTranslateVoice

CHDeclareClass(MMVoiceMessageCellView)
CHOptimizedMethod1(self, void, MMVoiceMessageCellView, populateWithMessage, MMMessageTableItem *, item)
{
    CHSuper1(MMVoiceMessageCellView, populateWithMessage, item);

    MessageData *message = item.message;
    if (TZWeChatPluginConfig.sharedConfig.autoTranslateVoiceEnable &&
        (TZWeChatPluginConfig.sharedConfig.translateMyselfVoiceEnable ||
         !message.isSendFromSelf) && message.m_uiVoiceToTextStatus == 0)
        /*
         m_uiVoiceToTextStatus
            0 默认态
            1 转换中，loading
            2 转换成功
            3 转换失败
         */
    {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self contextMenuTranscribe];
        });
    }
}

CHConstructor {
    CHLoadLateClass(MMVoiceMessageCellView);
    CHHook1(MMVoiceMessageCellView, populateWithMessage);
}

#pragma mark - log

CHDeclareClass(MMLogger)
CHOptimizedClassMethod6(self, void, MMLogger, logWithMMLogLevel, int, arg1, module, const char *, arg2, file, const char *, arg3, line, int, arg4, func, const char *, arg5, message, id, arg6)
{
    NSLog(@"MMLog [%s] %s %s %@", arg2, arg3, arg5, arg6);
}

CHConstructor {
    CHLoadLateClass(MMLogger);
//    CHClassHook6(MMLogger, logWithMMLogLevel, module, file, line, func, message);
}
