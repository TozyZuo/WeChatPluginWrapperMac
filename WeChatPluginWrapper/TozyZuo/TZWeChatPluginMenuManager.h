//
//  TZWeChatPluginMenuManager.h
//  WeChatPluginWrapper
//
//  Created by TozyZuo on 2018/9/11.
//  Copyright © 2018年 TozyZuo. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface TZWeChatPluginMenuManager : NSObject
+ (instancetype)shareManager;
- (void)configMenus;
@end

NS_ASSUME_NONNULL_END
