//
//  TZWeChatPluginConfig.m
//  WeChatDylib
//
//  Created by TozyZuo on 2018/3/29.
//  Copyright © 2018年 TozyZuo. All rights reserved.
//

#import "TZConfigManager.h"
#import "TZWeChatPluginDefine.h"
#import <objc/runtime.h>
#import <objc/message.h>

static NSString * const kTZWeChatRemotePlistPath = @"https://github.com/TozyZuo/WeChatPluginWrapperMac/raw/master/Other/Products/Debug/WeChatPluginWrapper.framework/Versions/A/Resources/Info.plist";

static NSString *TZUserDefaultsKeyPrefix;

@interface NSObject (TZWeChatPlugin)
@property (readonly) NSArray *ignoreProperties;
@end
@implementation NSObject (TZWeChatPlugin)
- (NSArray *)ignoreProperties
{
    return nil;
}
@end

@interface TZProperty : NSObject
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *classString; // 简单解析，并未处理复杂类型
@property (nonatomic, assign) BOOL isReadOnly;
@property (nonatomic, assign) objc_property_t property;
- (instancetype)initWithProperty:(objc_property_t)property;
@end

@implementation TZProperty

- (instancetype)initWithProperty:(objc_property_t)p
{
    if (self = [super init]) {
        self.property = p;

        self.name = [NSString stringWithUTF8String:property_getName(p)];

        for (NSString *attribute in [@(property_getAttributes(p)) componentsSeparatedByString:@","]) {
            if ([attribute hasPrefix:@"T"]) {
                NSString *classString = [attribute substringFromIndex:1];
                if ([classString hasPrefix:@"@"]) {
                    classString = [classString substringWithRange:NSMakeRange(2, classString.length - 3)];
                }
                self.classString = classString;
            } else if ([attribute hasPrefix:@"R"]) {
                self.isReadOnly = YES;
            }
        }
    }
    return self;
}

@end

@interface TZObjectInfo : NSObject
@property (nonatomic, copy) NSDictionary<NSString */*name*/, TZProperty */*property*/> *propertyDictionary;
@property (nonatomic, copy) NSArray *properties;
- (instancetype)initWithObject:(NSObject *)object;
- (NSString *)classStringForProperty:(NSString *)property;
@end

@implementation TZObjectInfo

- (instancetype)initWithObject:(NSObject *)object
{
    if (self = [super init]) {

        NSMutableArray *properties = [[NSMutableArray alloc] init];
        NSMutableDictionary *propertyDictionary = [[NSMutableDictionary alloc] init];

        Class class = object.class;

        while (class != [NSObject class]) {

            objc_property_t *pList;
            unsigned count;
            pList = class_copyPropertyList(class, &count);

            for (int i = 0; i < count; i++) {

                objc_property_t p = pList[i];

                if ([object.ignoreProperties containsObject:@(property_getName(p))]) {
                    continue;
                }

                TZProperty *property = [[TZProperty alloc] initWithProperty:p];
                [properties addObject:property];
                propertyDictionary[@(property_getName(p))] = property;
            }
            free(pList);
            class = class_getSuperclass(class);
        }
        self.properties = properties.reverseObjectEnumerator.allObjects;
        self.propertyDictionary = propertyDictionary;
    }
    return self;
}

- (NSString *)classStringForProperty:(NSString *)property
{
    return self.propertyDictionary[property].classString;
}

@end

@interface TZConfigManager ()
@property (nonatomic, strong) TZObjectInfo *info;
@property (nonatomic, strong) NSDictionary *dispathMap;
@property (nonatomic, strong) NSDictionary *localInfoPlist;
@property (nonatomic, strong) NSDictionary *remoteInfoPlist;
@end
@implementation TZConfigManager

#pragma mark - Override

- (instancetype)init
{
    self = [super init];
    if (self) {
        TZUserDefaultsKeyPrefix = NSStringFromClass(self.class);
        self.info = [[TZObjectInfo alloc] initWithObject:self];
        self.dispathMap = @{@"c": NSStringFromSelector(@selector(handleBOOLInvocation:))};

        for (TZProperty *property in self.info.properties) {
            if (!property.isReadOnly) {
                [self setValue:[[NSUserDefaults standardUserDefaults] objectForKey:[TZUserDefaultsKeyPrefix stringByAppendingString:property.name]] forKey:property.name];
                [self addObserver:self forKeyPath:property.name options:NSKeyValueObservingOptionNew context:NULL];
            }
        }

    }
    return self;
}

- (NSArray *)ignoreProperties
{
    return @[@"info",
             @"dispathMap",
             @"debugDescription",
             @"description",
             @"hash",
             @"superclass",];
}

- (void)setNilValueForKey:(NSString *)key
{
    // 防止初始化崩溃
}

- (void)setValue:(id)value forUndefinedKey:(NSString *)key
{
    NSAssert(0, @"%s key:%@ value:%@ ", __PRETTY_FUNCTION__, key, value);
}

- (BOOL)respondsToSelector:(SEL)aSelector
{
    NSString *sel = NSStringFromSelector(aSelector);
    if ([sel containsString:TZUserDefaultsKeyPrefix]) {
        return YES;
    }
    return [super respondsToSelector:aSelector];
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector
{
    return [NSMethodSignature signatureWithObjCTypes:"v@:@"];
}

- (void)forwardInvocation:(NSInvocation *)anInvocation
{
    NSString *sel = self.dispathMap[[self.info classStringForProperty:[self propertyFromSelector:anInvocation.selector]]];
    if (sel) {
        TZWarningIgnore(-Warc-performSelector-leaks)
        [self performSelector:NSSelectorFromString(sel) withObject:anInvocation];
        TZWarningIgnoreEnd
    }
}

#pragma mark - Private

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
{
    [[NSUserDefaults standardUserDefaults] setObject:[self valueForKey:keyPath] forKey:[TZUserDefaultsKeyPrefix stringByAppendingString:keyPath]];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSString *)propertyFromSelector:(SEL)sel
{
    NSString *selector = NSStringFromSelector(sel);
    if ([selector containsString:TZUserDefaultsKeyPrefix]) {
        return [selector substringToIndex:selector.length - TZUserDefaultsKeyPrefix.length - 1];
    }
    return nil;
}

- (void)handleBOOLInvocation:(NSInvocation *)anInvocation
{
    void *rawValue;
    [anInvocation getArgument:&rawValue atIndex:2];

    NSMenuItem *item = (__bridge NSMenuItem *)rawValue;
    item.state = !item.state;
    [self setValue:@(item.state) forKey:[self propertyFromSelector:anInvocation.selector]];
}

#pragma mark - Public

- (NSDictionary *)localInfoPlist
{
    if (!_localInfoPlist) {
        _localInfoPlist = [NSDictionary dictionaryWithContentsOfFile:[NSBundle.mainBundle.bundlePath stringByAppendingPathComponent:@"Contents/MacOS/WeChatPluginWrapper.framework/Resources/Info.plist"]];
    }
    return _localInfoPlist;
}

- (NSDictionary *)remoteInfoPlist
{
    if (!_remoteInfoPlist) {
        _remoteInfoPlist = [NSDictionary dictionaryWithContentsOfURL:[NSURL URLWithString:kTZWeChatRemotePlistPath]];
    }
    return _remoteInfoPlist;
}

- (NSString *)localVersion
{
    return self.localInfoPlist[@"CFBundleShortVersionString"];
}

- (NSString *)remoteVersion
{
    return self.remoteInfoPlist[@"CFBundleShortVersionString"];
}

- (NSString *)localVersionInfo
{
    return self.localInfoPlist[@"versionInfo"];
}

- (NSString *)remoteVersionInfo
{
    return self.remoteInfoPlist[@"versionInfo"];
}

- (SEL)selectorForPropertySEL:(SEL)propertySEL
{
    NSString *selector = NSStringFromSelector(propertySEL);
    if (![selector containsString:TZUserDefaultsKeyPrefix]) {
        selector = [NSStringFromSelector(propertySEL) stringByAppendingFormat:@"%@:", TZUserDefaultsKeyPrefix];
    }
    return NSSelectorFromString(selector);
}

@end
