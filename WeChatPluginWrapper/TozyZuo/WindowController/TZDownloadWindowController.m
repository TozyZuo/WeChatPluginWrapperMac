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

@interface TKVersionManager : NSObject
+ (instancetype)shareManager;
- (void)downloadPluginProgress:(void (^)(NSProgress *downloadProgress))downloadProgressBlock completionHandler:(void (^)(NSString *filePath, NSError * _Nullable error))completionHandler;
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
    self.progressView.doubleValue = 0;
    self.titleLabel.stringValue = @"";
    [self setupInstallBtnTitle:@"取消"];

    __block BOOL noCallBack = YES;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (noCallBack) {
            self.titleLabel.stringValue = @"下载中，请稍后...";
            self.progressView.hidden = YES;
        }
    });
    NSMutableSet *typeSet = [[NSMutableSet alloc] init];
    [self downloadPluginFromTypes:self.types.mutableCopy progress:^(NSProgress *downloadProgress, TZPluginType type)
    {
        noCallBack = NO;
        self.progressView.minValue = 0;
        self.progressView.maxValue = downloadProgress.totalUnitCount / 1024.0;
        self.progressView.doubleValue = downloadProgress.completedUnitCount  / 1024.0;
        CGFloat currentCount = downloadProgress.completedUnitCount / 1024.0 / 1024.0;
        CGFloat totalCount = downloadProgress.totalUnitCount / 1024.0 / 1024.0;
        self.progressLabel.stringValue = [NSString stringWithFormat:@"%.2lf MB / %.2lf MB", currentCount, totalCount];
        [typeSet addObject:@(type)];
        self.titleLabel.stringValue = [NSString stringWithFormat:@"正在下载更新[%lu/%lu]…", typeSet.count, self.types.count];
    } completion:^(NSDictionary<NSNumber *,NSString *> * _Nonnull result, TZDownloadState state) {
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
                       progress:(nullable void (^)(NSProgress *progress, TZPluginType type))progress
                     completion:(nullable void (^)(NSDictionary<NSNumber *,NSString *> * _Nonnull result, TZDownloadState state))completion
{
    NSNumber *oneType = types.firstObject;
    [types removeObject:oneType];
//    [types removeObjectAtIndex:0];

    if (oneType) {
        switch (oneType.pluginTypeValue) {
            case TZPluginTypeWrapper:
            {
                [self downloadWrapperWithProgress:^(NSProgress *p) {
                    if (progress) {
                        TZInvokeBlockInMainThread(^{
                            progress(p, TZPluginTypeWrapper);
                        })
                    }
                } completion:^(NSString *filePath, NSError * _Nullable error) {
                    if (error) {
                        if (error.code == NSURLErrorCancelled) {
                            self.downloadState = TZDownloadStateCancel;
                            if (completion) {
                                TZInvokeBlockInMainThread(^{
                                    completion(self.result, TZDownloadStateCancel);
                                })
                            }
                        } else {
                            self.downloadState = TZDownloadStateError;
                            if (completion) {
                                TZInvokeBlockInMainThread(^{
                                    completion(self.result, TZDownloadStateError);
                                })
                            }
                        }
                    } else {

                        self.result[oneType] = filePath;

                        if (types.count) {
                            [self downloadPluginFromTypes:types progress:progress completion:completion];
                        } else {
                            self.downloadState = TZDownloadStateFinish;
                            if (completion) {
                                TZInvokeBlockInMainThread(^{
                                    completion(self.result, TZDownloadStateFinish);
                                })
                            }
                        }
                    }
                }];
            }
                break;
            case TZPluginTypeTKkk:
            {
                [self downloadTKWithProgress:^(NSProgress *p) {
                    if (progress) {
                        TZInvokeBlockInMainThread(^{
                            progress(p, TZPluginTypeTKkk);
                        })
                    }
                } completion:^(NSString *filePath, NSError * _Nullable error) {
                    if (error) {
                        if (error.code == NSURLErrorCancelled) {
                            self.downloadState = TZDownloadStateCancel;
                            if (completion) {
                                TZInvokeBlockInMainThread(^{
                                    completion(self.result, TZDownloadStateCancel);
                                })
                            }
                        } else {
                            self.downloadState = TZDownloadStateError;
                            if (completion) {
                                TZInvokeBlockInMainThread(^{
                                    completion(self.result, TZDownloadStateError);
                                })
                            }
                        }
                    } else {

                        self.result[oneType] = filePath;

                        if (types.count) {
                            [self downloadPluginFromTypes:types progress:progress completion:completion];
                        } else {
                            self.downloadState = TZDownloadStateFinish;
                            if (completion) {
                                TZInvokeBlockInMainThread(^{
                                    completion(self.result, TZDownloadStateFinish);
                                })
                            }
                        }
                    }
                }];
            }
                break;
            // @other plugin
            default:
                break;
        }
    } else {
        self.downloadState = TZDownloadStateFinish;
        if (completion) {
            TZInvokeBlockInMainThread(^{
                completion(self.result, TZDownloadStateFinish);
            })
        }
    }
}

- (void)downloadWrapperWithProgress:(nullable void (^)(NSProgress *progress))progress completion:(void (^)(NSString *filePath, NSError * _Nullable error))completion
{
    NSString *pluginPath = [NSString stringWithFormat:@"%@/WeChatPluginWrapperMac-master", NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).lastObject];
    NSString *pluginZipPath = [NSString stringWithFormat:@"%@.zip", pluginPath];

    NSFileManager *fileManager = NSFileManager.defaultManager;
    [fileManager removeItemAtPath:pluginPath error:nil];
    [fileManager removeItemAtPath:pluginZipPath error:nil];

    [[objc_getClass("TKHTTPManager") shareManager] downloadWithUrlString:@"https://github.com/TozyZuo/WeChatPluginWrapperMac/archive/master.zip" toDirectoryPah:NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).lastObject progress:progress completionHandler:completion];
}

- (void)downloadTKWithProgress:(nullable void (^)(NSProgress *progress))progress completion:(void (^)(NSString *filePath, NSError * _Nullable error))completion
{
    [[objc_getClass("TKVersionManager") shareManager] downloadPluginProgress:progress completionHandler:completion];
}

- (void)setupInstallBtnTitle:(NSString *)text
{
    self.installButton.title = text;

    CGFloat stringWidth = [text widthWithFont:self.installButton.font];
    self.installButton.width = stringWidth + 40;
    self.installButton.x = 430 - stringWidth - 40;
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

        [self downloadPlugin];
    }
}

- (void)cancel
{
    [[objc_getClass("TKHTTPManager") shareManager] cancelDownload];
//    [[objc_getClass("TKVersionManager") shareManager] cancelDownload];
}

@end
