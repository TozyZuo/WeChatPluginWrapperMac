//
//  TZDownloadWindowController.m
//  WeChatPluginWrapper
//
//  Created by TozyZuo on 2018/9/18.
//  Copyright © 2018年 TozyZuo. All rights reserved.
//

#import "TZDownloadWindowController.h"
#import "TZWeChatHeader.h"
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


typedef NS_ENUM(NSUInteger, TZDownloadState) {
    TZDownloadStateProgress,
    TZDownloadStateFinish,
    TZDownloadStateError,
};

@interface TZDownloadWindowController ()
@property (weak) IBOutlet NSTextField *titleLabel;
@property (weak) IBOutlet NSButton *installButton;
@property (weak) IBOutlet NSProgressIndicator *progressView;
@property (weak) IBOutlet NSTextField *progressLabel;
@property (nonatomic, assign) TZDownloadState downloadState;
@property (nonatomic, strong) NSString *filePath;
@property (nonatomic, assign) TZPluginType type;
@property (nonatomic,  copy ) void (^completion)(NSString *filePath);
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
                self.completion(self.filePath);
            }
            break;
        }
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
    [self clearPlugin:self.type];

    [[objc_getClass("TKHTTPManager") shareManager] downloadWithUrlString:[self downloadURLStringFromType:self.type] toDirectoryPah:NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).lastObject progress:^(NSProgress *downloadProgress) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.progressView.minValue = 0;
            self.progressView.maxValue = downloadProgress.totalUnitCount / 1024.0;
            self.progressView.doubleValue = downloadProgress.completedUnitCount  / 1024.0;
            CGFloat currentCount = downloadProgress.completedUnitCount / 1024.0 / 1024.0;
            CGFloat totalCount = downloadProgress.totalUnitCount / 1024.0 / 1024.0;
            self.progressLabel.stringValue = [NSString stringWithFormat:@"%.2lf MB / %.2lf MB", currentCount, totalCount];
        });
    } completionHandler:^(NSString *filePath, NSError * _Nullable error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (error) {
                self.downloadState = TZDownloadStateError;
                if (error.code == NSURLErrorCancelled) {
                    self.titleLabel.stringValue = @"已取消";
                    [self setupInstallBtnTitle:@"重新下载"];
                    self.progressLabel.stringValue = @"";
                } else {
                    self.titleLabel.stringValue = @"更新错误";
                    [self setupInstallBtnTitle:@"重试"];
                }
                return;
            }
            self.downloadState = TZDownloadStateFinish;
            [self setupInstallBtnTitle:@"安装并重启应用"];
            self.titleLabel.stringValue = @"可以开始安装了";
            self.filePath = filePath;
        });
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

- (void)downloadWithPluginType:(TZPluginType)type completion:(void (^)(NSString *filePath))completion
{
    self.type = type;
    self.completion = completion;
    [self showWindow:self];
    [self.window center];
    [self.window makeKeyWindow];
}

@end
