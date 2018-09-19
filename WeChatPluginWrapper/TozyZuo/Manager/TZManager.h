//
//  TZManager.h
//  WeChatPluginWrapper
//
//  Created by TozyZuo on 2018/9/17.
//  Copyright © 2018年 TozyZuo. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@protocol TZManagerProtocol <NSObject>
+ (instancetype)sharedManager;
@end

@interface TZManager : NSObject
<TZManagerProtocol>
@end

NS_ASSUME_NONNULL_END
