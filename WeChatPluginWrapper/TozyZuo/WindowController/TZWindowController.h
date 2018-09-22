//
//  TZWindowController.h
//  WeChatPluginWrapper
//
//  Created by TozyZuo on 2018/9/18.
//  Copyright © 2018年 TozyZuo. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSWindowController (Action)
- (void)show;
@end

@interface TZWindowController : NSWindowController
+ (instancetype)sharedWindowController;
@end

NS_ASSUME_NONNULL_END
