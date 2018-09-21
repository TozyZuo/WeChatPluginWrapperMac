//
//  TZDownloadWindowController.m
//  WeChatPluginWrapper
//
//  Created by TozyZuo on 2018/9/18.
//  Copyright © 2018年 TozyZuo. All rights reserved.
//

#import "TZDownloadWindowController.h"
#import "TZVersionManager.h"
#import "TZWeChatHeader.h"
#import "TZWeChatPluginDefine.h"
#import <objc/runtime.h>

@interface NSString (Action)
- (CGFloat)widthWithFont:(NSFont *)font;
- (NSRect)rectWithFont:(NSFont *)font;
- (NSString *)substringFromString:(NSString *)fromStr;
@end

@interface TKHTTPManager : NSObject
+ (instancetype)shareManager;
- (void)downloadWithUrlString:(NSString *)urlString
               toDirectoryPah:(NSString *)directory
                     progress:(nullable void (^)(NSProgress *downloadProgress))downloadProgressBlock
            completionHandler:(nullable void (^)(NSString * filePath, NSError * _Nullable error))completionHandler;
- (void)cancelDownload;
@end


@interface TZDownloadWindowController ()
@property (weak) IBOutlet NSTextField *titleLabel;
@property (weak) IBOutlet NSButton *installButton;
@property (weak) IBOutlet NSProgressIndicator *progressView;
@property (weak) IBOutlet NSTextField *progressLabel;
@property (nonatomic, assign) TZDownloadState downloadState;
@property (nonatomic, strong) NSString *filePath;
@property (nonatomic, strong) NSArray<NSNumber *> *types;
@property (nonatomic, strong) NSMutableDictionary *result;
@property (nonatomic,  copy ) void (^completion)(NSDictionary<NSNumber *,NSString *> * _Nonnull, TZDownloadState);
@end

@implementation TZDownloadWindowController

- (void)windowDidLoad
{
    [super windowDidLoad];

    [self downloadPlugin];
}

- (IBAction)buttonAction:(NSButton *)sender
{
    switch (self.downloadState) {
        case TZDownloadStateProgress: {
            [[objc_getClass("TKHTTPManager") shareManager] cancelDownload];
            break;
        }
        case TZDownloadStateFinish: {
            if (self.completion) {
                self.completion(self.result, TZDownloadStateFinish);
            }
            break;
        }
        case TZDownloadStateCancel:
        case TZDownloadStateError: {
            [self downloadPlugin];
            break;
        }
        default:
            break;
    }
}

- (void)downloadPlugin
{
    self.downloadState = TZDownloadStateProgress;
    self.window.title = @"更新插件";
    self.titleLabel.stringValue = @"正在下载更新…";
    self.progressView.doubleValue = 0;
    [self setupInstallBtnTitle:@"取消"];

    [self downloadPluginFromTypes:self.types.mutableCopy progress:^(NSProgress *downloadProgress, TZPluginType type)
    {
        // TODO
        self.progressView.minValue = 0;
        self.progressView.maxValue = downloadProgress.totalUnitCount / 1024.0;
        self.progressView.doubleValue = downloadProgress.completedUnitCount  / 1024.0;
        CGFloat currentCount = downloadProgress.completedUnitCount / 1024.0 / 1024.0;
        CGFloat totalCount = downloadProgress.totalUnitCount / 1024.0 / 1024.0;
        self.progressLabel.stringValue = [NSString stringWithFormat:@"%.2lf MB / %.2lf MB", currentCount, totalCount];
    } completion:^(NSDictionary<NSNumber *,NSString *> * _Nonnull result, TZDownloadState state) {
        self.downloadState = state;
        if (state == TZDownloadStateFinish)
        {
            [self setupInstallBtnTitle:@"安装并重启应用"];
            self.titleLabel.stringValue = @"可以开始安装了";
        }
        else if (state == TZDownloadStateError)
        {
            self.titleLabel.stringValue = @"更新错误";
            [self setupInstallBtnTitle:@"重试"];
        }
        else if (state == TZDownloadStateCancel)
        {
            self.titleLabel.stringValue = @"已取消";
            [self setupInstallBtnTitle:@"重新下载"];
            self.progressLabel.stringValue = @"";
        }
    }];
}

- (void)downloadPluginFromTypes:(NSMutableArray<NSNumber *> *)types
                       progress:(nullable void (^)(NSProgress *downloadProgress, TZPluginType type))progress
                     completion:(nullable void (^)(NSDictionary<NSNumber *,NSString *> * _Nonnull result, TZDownloadState state))completion
{
    TZPluginType pluginType = types.firstObject.pluginTypeValue;
    [types removeObjectAtIndex:0];
    [self clearPlugin:pluginType];

    [[objc_getClass("TKHTTPManager") shareManager] downloadWithUrlString:[self downloadURLStringFromType:pluginType] toDirectoryPah:NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).lastObject progress:^(NSProgress *downloadProgress)
    {
        if (progress) {
            TZInvokeBlockInMainThread(^{
                progress(downloadProgress, pluginType);
            })
        }
    } completionHandler:^(NSString *filePath, NSError * _Nullable error) {

        if (error) {
            if (completion) {
                TZInvokeBlockInMainThread(^{
                    if (error.code == NSURLErrorCancelled) {
                        completion(self.result, TZDownloadStateCancel);
                    } else {
                        completion(self.result, TZDownloadStateError);
                    }
                })
            }
        } else {

            self.result[@(pluginType)] = filePath;

            if (types.count) {
                [self downloadPluginFromTypes:types progress:progress completion:completion];
            } else {
                if (completion) {
                    TZInvokeBlockInMainThread(^{
                        completion(self.result, TZDownloadStateFinish);
                    })
                }
            }
        }
    }];
}

- (void)setupInstallBtnTitle:(NSString *)text
{
    self.installButton.title = text;

    CGFloat stringWidth = [text widthWithFont:self.installButton.font];
    self.installButton.width = stringWidth + 40;
    self.installButton.x = 430 - stringWidth - 40;
}

- (void)clearPlugin:(TZPluginType)type
{
    NSString *pluginName = @"";
    switch (type) {
        case TZPluginTypeWrapper:
            pluginName = @"WeChatPluginWrapperMac-master";
            break;
        case TZPluginTypeTKkk:
            pluginName = @"WeChatPlugin-MacOS-master";
            break;
        default:
            break;
    }
    NSString *pluginPath = [NSString stringWithFormat:@"%@/%@", NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).lastObject, pluginName];
    NSString *pluginZipPath = [NSString stringWithFormat:@"%@.zip", pluginPath];

    NSFileManager *fileManager = [NSFileManager defaultManager];
    [fileManager removeItemAtPath:pluginPath error:nil];
    [fileManager removeItemAtPath:pluginZipPath error:nil];
}

- (NSString *)downloadURLStringFromType:(TZPluginType)type
{
    switch (type) {
        case TZPluginTypeWrapper:
            return @"https://github.com/TozyZuo/WeChatPluginWrapperMac/archive/master.zip";
        case TZPluginTypeTKkk:
            return @"https://github.com/TKkk-iOSer/WeChatPlugin-MacOS/archive/master.zip";
        default:
            return nil;
    }
}

#pragma mark - Public

- (void)downloadWithPluginTypes:(NSArray<NSNumber *> *)types quietly:(BOOL)quietly completion:(void (^)(NSDictionary<NSNumber *,NSString *> * _Nonnull, TZDownloadState))completion
{
    self.result = [[NSMutableDictionary alloc] init];
    
    if (quietly) {
        [self downloadPluginFromTypes:types.mutableCopy progress:nil completion:^(NSDictionary<NSNumber *,NSString *> * _Nonnull result, TZDownloadState state)
        {
            self.downloadState = state;
            if (completion) {
                completion(result, state);
            }
        }];
    } else {
        self.types = types;
        self.completion = completion;
        [self showWindow:self];
        [self.window center];
        [self.window makeKeyWindow];
    }
}

- (void)cancel
{
    [[objc_getClass("TKHTTPManager") shareManager] cancelDownload];
}

@end
