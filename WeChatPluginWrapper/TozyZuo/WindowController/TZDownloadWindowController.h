//
//  TZDownloadWindowController.h
//  WeChatPluginWrapper
//
//  Created by TozyZuo on 2018/9/18.
//  Copyright © 2018年 TozyZuo. All rights reserved.
//

#import "TZWindowController.h"

typedef NS_ENUM(NSUInteger, TZDownloadState) {
    TZDownloadStateFinish,
    TZDownloadStateProgress,
    TZDownloadStateCancel,
    TZDownloadStateError,
};

NS_ASSUME_NONNULL_BEGIN

@interface TZDownloadWindowController : TZWindowController
@property (nonatomic, readonly) TZDownloadState downloadState;
- (void)downloadWithPluginTypes:(NSArray<NSNumber *> *)types quietly:(BOOL)quietly completion:(void (^)(NSDictionary<NSNumber */*type*/, NSString */*filePath*/> *result, TZDownloadState state))completion;
- (void)cancel;
@end

NS_ASSUME_NONNULL_END
