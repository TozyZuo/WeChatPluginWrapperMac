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
@property (nonatomic, assign) BOOL autoTranslateVoiceEnable;
@property (nonatomic, assign) BOOL translateMyselfVoiceEnable;
@property (nonatomic, assign) BOOL autoUpdateEnable;
@property (nonatomic, assign) BOOL updateQuietlyEnable;
@property (nonatomic, assign) BOOL forbidCheckingUpdate;

@property (nonatomic, readonly) NSString *localVersion;
@property (nonatomic, readonly) NSString *remoteVersion;
@property (nonatomic, readonly) NSString *localVersionInfo;
@property (nonatomic, readonly) NSString *remoteVersionInfo;

- (SEL)selectorForPropertySEL:(SEL)propertySEL;

@end
