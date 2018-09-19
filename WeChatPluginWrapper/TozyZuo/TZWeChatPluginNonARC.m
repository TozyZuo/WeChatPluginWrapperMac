//
//  TZWeChatPluginNonARC.m
//  WeChatPluginWrapper
//
//  Created by TozyZuo on 2018/9/17.
//  Copyright © 2018年 TozyZuo. All rights reserved.
//

#import "TZWeChatPluginNonARC.h"

id TZAddressConvert(void *address)
{
    return *((id *)address);
}

void TZModifyValue(void *valuePtr, id value)
{
    *((id *)valuePtr) = value;
}
