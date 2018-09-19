//
//  TZWeChatPluginConfig.m
//  WeChatDylib
//
//  Created by TozyZuo on 2018/3/29.
//  Copyright © 2018年 TozyZuo. All rights reserved.
//

#import "TZConfigManager.h"
#import <objc/runtime.h>
#import <objc/message.h>

static NSString * const kTZWeChatRemotePlistPath = @"https://github.com/TozyZuo/WeChatPluginWrapperMac/raw/master/master/Other/Products/Debug/WeChatPluginWrapper.framework/Resources/Info.plist";

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

@interface TZObjectInfo : NSObject
@property (nonatomic, strong) NSArray *propertyNames;
@property (nonatomic, strong) NSDictionary *classTypeMap;
- (instancetype)initWithObject:(NSObject *)object;
- (NSString *)classStringForProperty:(NSString *)property;
@end

@implementation TZObjectInfo

- (instancetype)initWithObject:(NSObject *)object
{
    if (self = [super init]) {

        NSMutableArray *propertyNames = [[NSMutableArray alloc] init];
        NSMutableDictionary *classTypeMap = [[NSMutableDictionary alloc] init];

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

                // propertyName
                NSString *propertyName = [NSString stringWithUTF8String:property_getName(p)];
                [propertyNames addObject:propertyName];

                // class map
                unsigned count;
                objc_property_attribute_t *attributes = property_copyAttributeList(p, &count);
                for (int i = 0; i < count; i++) {
                    if ([@(attributes[i].name) isEqualToString:@"T"]) {
                        NSString *classString = @(attributes[i].value);
                        if ([classString hasPrefix:@"@"]) {
                            classString = [classString substringWithRange:NSMakeRange(2, classString.length - 3)];
                        }
                        classTypeMap[propertyName] = classString;
                    }
                }
                free(attributes);
            }
            free(pList);
            class = class_getSuperclass(class);
        }
        self.propertyNames = propertyNames.reverseObjectEnumerator.allObjects.mutableCopy;
        self.classTypeMap = classTypeMap;
    }
    return self;
}

- (NSString *)classStringForProperty:(NSString *)property
{
    return self.classTypeMap[property];
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

        for (NSString *property in self.info.propertyNames) {
            [self setValue:[[NSUserDefaults standardUserDefaults] objectForKey:[TZUserDefaultsKeyPrefix stringByAppendingString:property]] forKey:property];
            [self addObserver:self forKeyPath:property options:NSKeyValueObservingOptionNew context:NULL];
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
        [self performSelector:NSSelectorFromString(sel) withObject:anInvocation];
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

- (SEL)selectorForPropertySEL:(SEL)propertySEL
{
    NSString *selector = NSStringFromSelector(propertySEL);
    if (![selector containsString:TZUserDefaultsKeyPrefix]) {
        selector = [NSStringFromSelector(propertySEL) stringByAppendingFormat:@"%@:", TZUserDefaultsKeyPrefix];
    }
    return NSSelectorFromString(selector);
}

@end
