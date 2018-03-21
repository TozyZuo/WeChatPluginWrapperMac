//
//  WeChatPluginWrapper.m
//  WeChatPluginWrapper
//
//  Created by TozyZuo on 2018/3/14.
//  Copyright (c) 2018年 TozyZuo. All rights reserved.
//

#import "WeChatPluginWrapper.h"
#import "WeChatPluginWrapperHeader.h"

#import "WeChat+hook.h"
#import "MMChatsTableCellView+hook.h"
#import "MMStickerMessageCellView+hook.h"

static void __attribute__((constructor)) initialize(void) {
    NSLog(@"++++++++ WeChatPlugin loaded ++++++++");
    [NSObject hookWeChat];
    [NSObject hookMMChatsTableCellView];
    [NSObject hookMMStickerMessageCellView];
}
