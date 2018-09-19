//
//  TZWeChatPluginConfig.h
//  WeChatDylib
//
//  Created by TozyZuo on 2018/3/29.
//  Copyright © 2018年 TozyZuo. All rights reserved.
//

#import "TZManager.h"

@interface TZConfigManager : TZManager

@property (nonatomic, assign) BOOL timeDisplayEnable;
@property (nonatomic, assign) BOOL displayWholeTimeEnable;
@property (nonatomic, assign) BOOL hideWeChatTimeEnable;
@property (nonatomic, assign) BOOL fullscreenPopGestureEnable;
@property (nonatomic, assign) BOOL autoTranslateVoiceEnable;
@property (nonatomic, assign) BOOL translateMyselfVoiceEnable;
@property (nonatomic, assign) BOOL forbidCheckingUpdate;

@property (nonatomic, readonly) NSDictionary *localInfoPlist;
@property (nonatomic, readonly) NSDictionary *remoteInfoPlist;

- (SEL)selectorForPropertySEL:(SEL)propertySEL;

@end
