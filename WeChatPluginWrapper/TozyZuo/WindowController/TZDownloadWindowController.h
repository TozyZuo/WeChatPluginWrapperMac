//
//  TZDownloadWindowController.h
//  WeChatPluginWrapper
//
//  Created by TozyZuo on 2018/9/18.
//  Copyright © 2018年 TozyZuo. All rights reserved.
//

#import "TZWindowController.h"

typedef NS_ENUM(NSUInteger, TZPluginType) {
    TZPluginTypeWrapper,
    TZPluginTypeTKkk,
};

NS_ASSUME_NONNULL_BEGIN

@interface TZDownloadWindowController : TZWindowController
- (void)downloadWithPluginType:(TZPluginType )type completion:(void (^)(NSString *filePath))completion;
@end

NS_ASSUME_NONNULL_END
