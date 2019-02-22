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
#import "TZNotificationManager.h"
#import "TZDownloadWindowController.h"
#import "TZWeChatHeader.h"
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

@interface TKWeChatPluginConfig : NSObject
@property (nonatomic, copy, readonly) NSDictionary *localInfoPlist;
+ (instancetype)sharedConfig;
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
@property (nonatomic, strong) NSMutableDictionary<NSNumber *,NSString *> *result;
@end

@implementation TZVersionManager

+ (void)load
{
    [TZPluginManager.sharedManager registerAppLifecycleWithClass:self];
}

#pragma mark Private

- (void)checkUpdatesCompletion:(void (^)(NSString *message, NSArray<NSNumber *> *updateTypes))completion
{
    if (completion) {
        // clearCache
        [TZConfigManager.sharedManager clearCache];
        [[objc_getClass("TKWeChatPluginConfig") sharedConfig] setValue:nil forKey:@"romoteInfoPlist"];

        [self checkWrapperUpdateWithCompletion:^(BOOL hasUpdate, NSString *wrapperMessage)
        {
            if (hasUpdate) {
                completion(wrapperMessage, @[@(TZPluginTypeWrapper)]);
            } else {
                NSMutableArray *types = [[NSMutableArray alloc] init];
                __block NSString *messages = [wrapperMessage stringByAppendingString:@"\n\n"];
                [self checkTKUpdateWithCompletion:^(BOOL hasUpdate, NSString *message)
                {
                    if (hasUpdate) {
                        messages = [@"微信小助手更新:\n\n" stringByAppendingString:message];
                        [types addObject:@(TZPluginTypeTKkk)];
                    } else {
                        NSString *tkMessage = [[[objc_getClass("TKWeChatPluginConfig") sharedConfig] localInfoPlist][@"versionInfo"] stringByReplacingOccurrencesOfString:@"\\n" withString:@"\n"];
                        messages = [messages stringByAppendingFormat:@"微信小助手:\n\n%@\n\n", tkMessage];
                    }
                    // @other plugin

                    completion(messages, types);
                }];
            }
        }];
    }
}

- (void)checkWrapperUpdateWithCompletion:(void (^)(BOOL, NSString *))completion
{
    if (completion) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            BOOL hasUpdate = ![TZConfigManager.sharedManager.localVersion isEqualToString:TZConfigManager.sharedManager.remoteVersion];

            dispatch_async(dispatch_get_main_queue(), ^{
                if (hasUpdate) {
                    completion(YES, TZConfigManager.sharedManager.remoteVersionInfo);
                } else {
                    completion(NO, TZConfigManager.sharedManager.localVersionInfo);
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
                 completion(NO, message);
             }
         }];
    }
}

- (void)updatePluginsQuietly:(NSArray<NSNumber *> *)pluginTypes
{
    [TZDownloadWindowController.sharedWindowController downloadWithPluginTypes:pluginTypes quietly:YES completion:^(NSDictionary<NSNumber *,NSString *> * _Nonnull result, TZDownloadState state)
     {
         if (state == TZDownloadStateFinish) {
             [self.result addEntriesFromDictionary:result];
             // 下载成功，开始更新
             [self.result enumerateKeysAndObjectsUsingBlock:^(NSNumber * _Nonnull key, NSString * _Nonnull obj, BOOL * _Nonnull stop) {
                 [self downloadCompletedWithType:key.pluginTypeValue filePath:obj];
             }];
             if (!TZConfigManager.sharedManager.updateQuietlyEnable) {
                 // 通知完成
                 [TZNotificationManager.sharedManager postNotificationWithMessage:@"更新完成，重启后生效" forceDisplay:YES buttonTitle:@"立即重启" action:^(NSUserNotification * _Nonnull notification)
                  {
                      [self restartWeChat];
                  }];
             }
         } else if (state == TZDownloadStateError) {
             [self.result addEntriesFromDictionary:result];
             // 静默状态下，网络失败，就失败了
             if (!TZConfigManager.sharedManager.updateQuietlyEnable) {
                 // 通知下载错误
                 [TZNotificationManager.sharedManager postNotificationWithMessage:@"下载错误" forceDisplay:YES buttonTitle:@"重试" action:^(NSUserNotification * _Nonnull notification)
                  {
                      NSMutableArray *leftTypes = pluginTypes.mutableCopy;
                      [leftTypes removeObjectsInArray:result.allKeys];
                      [self updatePluginsQuietly:leftTypes];
                  }];
             }
         }
     }];
}

- (void)showUpdateMessage:(NSString *)message types:(NSArray<NSNumber *> *)types
{
    NSAlert *alert = [[NSAlert alloc] init];
    [alert addButtonWithTitle:@"安装更新"];
    [alert addButtonWithTitle:@"不再提示"];
    [alert addButtonWithTitle:@"取消"];
    alert.messageText = @"检测到新版本！主要内容：👇";
    alert.informativeText = message ?: @"";
    NSModalResponse respose = [alert runModal];

    if (respose == NSAlertFirstButtonReturn) {
//        NSMutableArray *t = types.mutableCopy;
//        [t addObjectsFromArray:t];
//        types = t;
        [TZDownloadWindowController.sharedWindowController downloadWithPluginTypes:types quietly:NO completion:^(NSDictionary<NSNumber *,NSString *> * _Nonnull result, TZDownloadState state)
        {
            [result enumerateKeysAndObjectsUsingBlock:^(NSNumber * _Nonnull key, NSString * _Nonnull obj, BOOL * _Nonnull stop) {
                [self downloadCompletedWithType:key.pluginTypeValue filePath:obj];
            }];

            [self restartWeChat];
        }];
    } else if (respose == NSAlertSecondButtonReturn) {
        TZConfigManager.sharedManager.forbidCheckingUpdate = YES;
    }
}

- (void)downloadCompletedWithType:(TZPluginType)type filePath:(NSString *)filePath
{
    NSString *directoryName = [filePath stringByDeletingLastPathComponent];
    NSString *fileName = [[filePath lastPathComponent] stringByDeletingPathExtension];
    NSString *WeChatPath = NSBundle.mainBundle.bundlePath;
    NSString *cmdString = @"";
    switch (type) {
        case TZPluginTypeWrapper:
        {
            cmdString = [NSString stringWithFormat:@"cd %@ && unzip -n %@.zip && ./%@/Other/Install.sh && rm -rf ./%@ && rm -rf ./%@.zip", directoryName, fileName, fileName, fileName, fileName];
            [objc_getClass("TKRemoteControlManager") executeShellCommand:cmdString];

            [self deleteTKString];
        }
            break;
        case TZPluginTypeTKkk:
        {
            cmdString = [NSString stringWithFormat:@"cd %@ && unzip -n %@.zip && cp -r ./%@/Other/Products/Debug/WeChatPlugin.framework %@/Contents/MacOS/ && rm -rf ./%@ && rm -rf ./%@.zip", directoryName, fileName, fileName, WeChatPath, fileName, fileName];
            [objc_getClass("TKRemoteControlManager") executeShellCommand:cmdString];

            [self deleteTKString];
        }
            break;
        default:
            break;
    }
}

- (void)restartWeChat
{
    [objc_getClass("TKRemoteControlManager") executeShellCommand:[NSString stringWithFormat:@"killall WeChat && sleep 2s && open %@", NSBundle.mainBundle.bundlePath]];
}

- (void)deleteTKString
{
    NSString *WeChatPath = NSBundle.mainBundle.bundlePath;
    NSString *file = [NSString stringWithFormat:@"%@/Contents/MacOS/WeChatPlugin.framework/Resources/zh-Hans.lproj/Localizable.strings", WeChatPath];
    NSMutableString *str = [NSMutableString stringWithContentsOfFile:file encoding:NSUnicodeStringEncoding error:nil];
    if ([str rangeOfString:@"TK拦截到一条撤回消息"].length) {
        [str replaceOccurrencesOfString:@"TK拦截到一条撤回消息: " withString:@"拦截到一条撤回消息: " options:0 range:NSMakeRange(0, str.length)];
        [str replaceOccurrencesOfString:@"TK正在为你免认证登录~" withString:@"正在为你免认证登录~" options:0 range:NSMakeRange(0, str.length)];
        [str writeToFile:file atomically:YES encoding:NSUnicodeStringEncoding error:nil];
    }
}

#pragma mark NSApplicationDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
    TZConfigManager *config = TZConfigManager.sharedManager;
    if (!config.forbidCheckingUpdate) {
        [self checkUpdatesCompletion:^(NSString * _Nonnull message, NSArray<NSNumber *> * _Nonnull updateTypes)
        {
            if (updateTypes.count) {
                if (config.autoUpdateEnable) {
                    self.result = [[NSMutableDictionary alloc] init];
                    if (!config.updateQuietlyEnable) {
                        // 通知下载
                        [TZNotificationManager.sharedManager postNotificationWithMessage:@"检测到新版本，开始下载" forceDisplay:YES buttonTitle:@"取消" action:^(NSUserNotification * _Nonnull notification)
                         {
                             [TZDownloadWindowController.sharedWindowController cancel];
                         }];
                    }
                    [self updatePluginsQuietly:updateTypes];
                } else {
                    [self showUpdateMessage:message types:updateTypes];
                }
            }
        }];
    }
}

@end

@implementation NSNumber (TZPluginType)

- (TZPluginType)pluginTypeValue
{
    return self.unsignedIntegerValue;
}

@end
