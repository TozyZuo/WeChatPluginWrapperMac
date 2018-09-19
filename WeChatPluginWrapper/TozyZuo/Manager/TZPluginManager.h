//
//  TZPluginManager.h
//  WeChatPluginWrapper
//
//  Created by TozyZuo on 2018/9/17.
//  Copyright © 2018年 TozyZuo. All rights reserved.
//

#import "TZManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface TZPluginManager : TZManager
<NSApplicationDelegate>
- (void)registerAppLifecycleWithClass:(Class<TZManagerProtocol, NSApplicationDelegate>)class;
@end

NS_ASSUME_NONNULL_END
