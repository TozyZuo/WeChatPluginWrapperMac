//
//  TZVersionManager.m
//  WeChatPluginWrapper
//
//  Created by TozyZuo on 2018/9/17.
//  Copyright © 2018年 TozyZuo. All rights reserved.
//

#import "TZVersionManager.h"
#import "TZPluginManager.h"
#import "TZConfigManager.h"
#import "TZDownloadWindowController.h"
#import <CaptainHook/CaptainHook.h>
#import <objc/runtime.h>


#pragma mark - Declare TK

@interface NSObject (WeChatHook)
+ (void)checkPluginVersion;
@end

@interface TKVersionManager : NSObject
+ (instancetype)shareManager;
- (void)checkVersionFinish:(void (^)(NSUInteger status, NSString *message))finish;
@end

@interface TKRemoteControlManager : NSObject
+ (NSString *)executeShellCommand:(NSString *)msg;
@end

#pragma mark - Hook TK

CHDeclareClass(NSObject)
CHOptimizedClassMethod0(self, void, NSObject, checkPluginVersion)
{

}

CHConstructor {
    CHLoadLateClass(NSObject);
    CHClassHook0(NSObject, checkPluginVersion);
}

#pragma mark -

@interface TZVersionManager ()
<NSApplicationDelegate>
@end

@implementation TZVersionManager

+ (void)load
{
    [TZPluginManager.sharedManager registerAppLifecycleWithClass:self];
}

#pragma mark Private

- (void)checkUpdates
{
    [self checkWrapperUpdateWithCompletion:^(BOOL hasUpdate, NSString *message) {
        if (hasUpdate) {
            [self showUpdateMessage:message type:TZPluginTypeWrapper];
        } else {
            [self checkTKUpdateWithCompletion:^(BOOL hasUpdate, NSString *message) {
                if (hasUpdate) {
                    [self showUpdateMessage:[@"微信小助手更新:\n\n" stringByAppendingString:message] type:TZPluginTypeTKkk];
                } else {
                    // TODO other plugin
                }
            }];
        }
    }];
}

- (void)checkWrapperUpdateWithCompletion:(void (^)(BOOL, NSString *))completion
{
    if (completion) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSDictionary *localInfo = TZConfigManager.sharedManager.localInfoPlist;
            NSDictionary *remoteInfo = TZConfigManager.sharedManager.remoteInfoPlist;
            NSString *localBundle = localInfo[@"CFBundleShortVersionString"];
            NSString *remoteBundle = remoteInfo[@"CFBundleShortVersionString"];

            dispatch_async(dispatch_get_main_queue(), ^{
                if (![localBundle isEqualToString:remoteBundle]) {
                    completion(YES, remoteInfo[@"versionInfo"]);
                } else {
                    completion(NO, nil);
                }
            });
        });
    }
}

- (void)checkTKUpdateWithCompletion:(void (^)(BOOL, NSString *))completion
{
    if (completion) {
        [[objc_getClass("TKVersionManager") shareManager] checkVersionFinish:^(NSUInteger status, NSString *message)
         {
             if (status == 1) {
                 completion(YES, message);
             } else {
                 completion(NO, nil);
             }
         }];
    }
}

- (void)showUpdateMessage:(NSString *)message type:(TZPluginType)type
{
    NSAlert *alert = [[NSAlert alloc] init];
    [alert addButtonWithTitle:@"安装更新"];
    [alert addButtonWithTitle:@"不再提示"];
    [alert addButtonWithTitle:@"取消"];
    [alert setMessageText:@"检测到新版本！主要内容：👇"];
    [alert setInformativeText:message ?: @""];
    NSModalResponse respose = [alert runModal];

    if (respose == NSAlertFirstButtonReturn) {
        [TZDownloadWindowController.sharedWindowController downloadWithPluginType:type completion:^(NSString * _Nonnull filePath)
         {
             [self downloadCompletedWithType:type filePath:filePath];
         }];
    } else if (respose == NSAlertSecondButtonReturn) {
        TZConfigManager.sharedManager.forbidCheckingUpdate = YES;
    }
}

- (void)downloadCompletedWithType:(TZPluginType)type filePath:(NSString *)filePath
{
    NSString *directoryName = [filePath stringByDeletingLastPathComponent];
    NSString *fileName = [[filePath lastPathComponent] stringByDeletingPathExtension];
    NSString *cmdString = @"";
    switch (type) {
        case TZPluginTypeWrapper:
            cmdString = [NSString stringWithFormat:@"cd %@ && unzip -n %@.zip && ./%@/Other/Install.sh && rm -rf ./%@ && rm -rf ./%@.zip && killall WeChat && sleep 2s && open %@",directoryName, fileName, fileName, fileName, fileName, NSBundle.mainBundle.bundlePath];
            break;
        case TZPluginTypeTKkk:
            cmdString = [NSString stringWithFormat:@"cd %@ && unzip -n %@.zip && cp -r ./%@/Other/Products/Debug/WeChatPlugin.framework %@/Contents/MacOS/ && rm -rf ./%@ && rm -rf ./%@.zip && killall WeChat && sleep 2s && open %@",directoryName, fileName, fileName, NSBundle.mainBundle.bundlePath, fileName, fileName, NSBundle.mainBundle.bundlePath];
            break;
        default:
            break;
    }
    [objc_getClass("TKRemoteControlManager") executeShellCommand:cmdString];
}

#pragma mark NSApplicationDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
    if (!TZConfigManager.sharedManager.forbidCheckingUpdate) {
        [self checkUpdates];
    }
}

@end
