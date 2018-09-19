//
//  TZWeChatPluginDefine.h
//  WeChatPluginWrapper
//
//  Created by TozyZuo on 2018/9/19.
//  Copyright © 2018年 TozyZuo. All rights reserved.
//

#ifndef TZWeChatPluginDefine_h
#define TZWeChatPluginDefine_h


#define TZWarningIgnoreHelper0(x) #x
#define TZWarningIgnoreHelper1(x) TZWarningIgnoreHelper0(clang diagnostic ignored x)
#define TZWarningIgnoreHelper2(y) TZWarningIgnoreHelper1(#y)

#define TZWarningIgnoreEnd _Pragma("clang diagnostic pop")
#define TZWarningIgnore(x)\
_Pragma("clang diagnostic push")\
_Pragma(TZWarningIgnoreHelper2(x))

#define TZWarningIgnoreTwo(x,y)\
_Pragma("clang diagnostic push")\
_Pragma(TZWarningIgnoreHelper2(x))\
_Pragma(TZWarningIgnoreHelper2(y))

#endif /* TZWeChatPluginDefine_h */
