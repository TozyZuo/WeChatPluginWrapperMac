//
//  TZVersionManager.h
//  WeChatPluginWrapper
//
//  Created by TozyZuo on 2018/9/17.
//  Copyright © 2018年 TozyZuo. All rights reserved.
//

#import "TZManager.h"

typedef NS_ENUM(NSUInteger, TZPluginType) {
    TZPluginTypeWrapper,
    TZPluginTypeTKkk,
};

@interface NSNumber (TZPluginType)
- (TZPluginType)pluginTypeValue;
@end

NS_ASSUME_NONNULL_BEGIN

@interface TZVersionManager : TZManager
- (void)showUpdateMessage:(NSString *)message types:(NSArray<NSNumber *> *)types;
- (void)checkUpdatesCompletion:(void (^)(NSString *message, NSArray<NSNumber *> *updateTypes))completion;
@end

NS_ASSUME_NONNULL_END
