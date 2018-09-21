//
//  TZWeChatPluginMenuManager.m
//  WeChatPluginWrapper
//
//  Created by TozyZuo on 2018/9/11.
//  Copyright © 2018年 TozyZuo. All rights reserved.
//

#import "TZMenuManager.h"
#import "TZConfigManager.h"
#import "TZPluginManager.h"
#import "TZVersionManager.h"
#import "TZNotificationManager.h"
#import "TZDownloadWindowController.h"
#import "TZWeChatHeader.h"
#import <objc/runtime.h>


@interface NSMenu (Action)
- (void)addItems:(NSArray *)subItems;
@end
@interface NSMenuItem (Action)
+ (NSMenuItem *)menuItemWithTitle:(NSString *)title action:(SEL)selector target:(id)target keyEquivalent:(NSString *)key state:(NSControlStateValue)state;
@end

@interface TZMenuManager ()
<NSApplicationDelegate>
@property (nonatomic, strong) NSMenuItem *timeDisplayItem;
@property (nonatomic, strong) NSMenuItem *displayWholeTimeItem;
@property (nonatomic, strong) NSMenuItem *hideWeChatTimeItem;
@property (nonatomic, strong) NSMenuItem *autoTranslateVoiceItem;
@property (nonatomic, strong) NSMenuItem *translateMyselfVoiceItem;
@end

@implementation TZMenuManager

+ (void)load
{
    [TZPluginManager.sharedManager registerAppLifecycleWithClass:self];
}

- (void)configMenus
{
    NSMenu *mainMenu = NSApp.mainMenu;
    NSMenuItem *TKkkItem = mainMenu.itemArray.lastObject;
    TKkkItem.enabled = YES;
    [mainMenu removeItem:TKkkItem];

    TZConfigManager *config = TZConfigManager.sharedManager;

    self.timeDisplayItem = [NSMenuItem menuItemWithTitle:@"显示每条消息时间" action:@selector(timeDisplayEnableAction:) target:self keyEquivalent:@"" state:config.timeDisplayEnable];

    self.displayWholeTimeItem = [NSMenuItem menuItemWithTitle:@"显示完整时间(年-月-日 时:分:秒)" action:@selector(displayWholeTimeEnableAction:) target:self keyEquivalent:@"" state:config.displayWholeTimeEnable];
    self.displayWholeTimeItem.enabled = config.timeDisplayEnable;

    self.hideWeChatTimeItem = [NSMenuItem menuItemWithTitle:@"隐藏微信原生时间" action:@selector(hideWeChatTimeEnableAction:) target:self keyEquivalent:@"" state:config.hideWeChatTimeEnable];
    self.hideWeChatTimeItem.enabled = config.timeDisplayEnable;

    self.autoTranslateVoiceItem = [NSMenuItem menuItemWithTitle:@"开启语音自动转文字" action:@selector(autoTranslateVoiceEnableAction:) target:self keyEquivalent:@"" state:config.autoTranslateVoiceEnable];

    self.translateMyselfVoiceItem = [NSMenuItem menuItemWithTitle:@"转换我发出的语音" action:@selector(translateMyselfVoiceEnableAction:) target:self keyEquivalent:@"" state:config.translateMyselfVoiceEnable];
    self.translateMyselfVoiceItem.enabled = config.translateMyselfVoiceEnable;

    NSMenu *TozyZuoMenu = [[NSMenu alloc] initWithTitle:@"消息设置"];
    TozyZuoMenu.autoenablesItems = NO;
    [TozyZuoMenu addItems:@[self.timeDisplayItem,
                            self.displayWholeTimeItem,
                            self.hideWeChatTimeItem,
                            [NSMenuItem separatorItem],
                            self.autoTranslateVoiceItem,
                            self.translateMyselfVoiceItem,
                            ]];
    NSMenuItem *TozyZuoItem = [[NSMenuItem alloc] init];
    TozyZuoItem.title = @"消息设置";
    TozyZuoItem.submenu = TozyZuoMenu;

    NSMenuItem *autoUpdateItem = [NSMenuItem menuItemWithTitle:@"自动更新" action:@selector(autoUpdateEnableAction:) target:self keyEquivalent:@"" state:config.autoUpdateEnable];
    if (config.autoUpdateEnable) {

        NSMenuItem *updateQuietlyItem = [NSMenuItem menuItemWithTitle:@"静默更新" action:[config selectorForPropertySEL:@selector(updateQuietlyEnable)] target:config keyEquivalent:@"" state:config.updateQuietlyEnable];
        updateQuietlyItem.enabled = TZNotificationManager.notificationEnable;

        NSMenu *subMenu = [[NSMenu alloc] initWithTitle:@"静默更新"];
        subMenu.autoenablesItems = NO;
        [subMenu addItem:updateQuietlyItem];
        autoUpdateItem.submenu = subMenu;
    }

    NSMenuItem *checkUpdateItem = [NSMenuItem menuItemWithTitle:@"检查更新" action:@selector(checkUpdateAction:) target:self keyEquivalent:@"" state:NSControlStateValueOff];

    NSMenuItem *aboutItem = [NSMenuItem menuItemWithTitle:@"关于插件" action:@selector(aboutAcion:) target:self keyEquivalent:@"" state:NSControlStateValueOff];

    NSMenu *newMenu = [[NSMenu alloc] initWithTitle:@"插件设置"];
    [newMenu addItems:@[TKkkItem,
                        TozyZuoItem,
                        [NSMenuItem separatorItem],
                        autoUpdateItem,
                        checkUpdateItem,
//                        aboutItem,
                        ]];
    NSMenuItem *newItem = [[NSMenuItem alloc] init];
    newItem.title = @"插件设置";
    newItem.submenu = newMenu;

    [mainMenu addItem:newItem];
}

#pragma mark - Menu Action

- (void)timeDisplayEnableAction:(NSMenuItem *)item
{
    item.state = !item.state;
    BOOL enable = item.state;
    TZConfigManager.sharedManager.timeDisplayEnable = enable;
    self.displayWholeTimeItem.enabled = enable;
    self.hideWeChatTimeItem.enabled = enable;

    MMChatsViewController *chatsViewController = [[objc_getClass("WeChat") sharedInstance] chatsViewController];
    [chatsViewController.tableView reloadData];

    MMTableView *tableView = chatsViewController.chatMessageViewController.messageTableView;
    NSIndexSet *rowIndexSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, tableView.numberOfRows)];
    [NSAnimationContext beginGrouping];
    NSAnimationContext.currentContext.duration = 0;
    [tableView noteHeightOfRowsWithIndexesChanged:rowIndexSet];
    [NSAnimationContext endGrouping];
    [tableView beginUpdates];
    [tableView reloadDataForRowIndexes:rowIndexSet columnIndexes:[NSIndexSet indexSetWithIndex:0]];
    [tableView endUpdates];
}

- (void)displayWholeTimeEnableAction:(NSMenuItem *)item
{
    item.state = !item.state;
    TZConfigManager.sharedManager.displayWholeTimeEnable = item.state;

    MMChatsViewController *chatsViewController = [[objc_getClass("WeChat") sharedInstance] chatsViewController];
    [chatsViewController.tableView reloadData];

    MMTableView *tableView = chatsViewController.chatMessageViewController.messageTableView;
    NSIndexSet *rowIndexSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, tableView.numberOfRows)];
    [tableView beginUpdates];
    [tableView reloadDataForRowIndexes:rowIndexSet columnIndexes:[NSIndexSet indexSetWithIndex:0]];
    [tableView endUpdates];
}

- (void)hideWeChatTimeEnableAction:(NSMenuItem *)item
{
    item.state = !item.state;
    TZConfigManager.sharedManager.hideWeChatTimeEnable = item.state;

    MMTableView *tableView = [[objc_getClass("WeChat") sharedInstance] chatsViewController].chatMessageViewController.messageTableView;
    NSIndexSet *rowIndexSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, tableView.numberOfRows)];
    [NSAnimationContext beginGrouping];
    NSAnimationContext.currentContext.duration = 0;
    [tableView noteHeightOfRowsWithIndexesChanged:rowIndexSet];
    [NSAnimationContext endGrouping];
}

- (void)autoTranslateVoiceEnableAction:(NSMenuItem *)item
{
    item.state = !item.state;
    BOOL enable = item.state;
    TZConfigManager.sharedManager.autoTranslateVoiceEnable = enable;
    self.translateMyselfVoiceItem.enabled = enable;

    if (enable) {
        MMTableView *tableView = [[objc_getClass("WeChat") sharedInstance] chatsViewController].chatMessageViewController.messageTableView;
        NSIndexSet *rowIndexSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, tableView.numberOfRows)];
        [tableView beginUpdates];
        [tableView reloadDataForRowIndexes:rowIndexSet columnIndexes:[NSIndexSet indexSetWithIndex:0]];
        [tableView endUpdates];
    }
}

- (void)translateMyselfVoiceEnableAction:(NSMenuItem *)item
{
    item.state = !item.state;
    BOOL enable = item.state;
    TZConfigManager.sharedManager.translateMyselfVoiceEnable = enable;

    if (enable) {
        MMTableView *tableView = [[objc_getClass("WeChat") sharedInstance] chatsViewController].chatMessageViewController.messageTableView;
        NSIndexSet *rowIndexSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, tableView.numberOfRows)];
        [tableView beginUpdates];
        [tableView reloadDataForRowIndexes:rowIndexSet columnIndexes:[NSIndexSet indexSetWithIndex:0]];
        [tableView endUpdates];
    }
}

- (void)autoUpdateEnableAction:(NSMenuItem *)item
{
    item.state = !item.state;
    TZConfigManager *config = TZConfigManager.sharedManager;
    config.autoUpdateEnable = item.state;

    if (item.state) {
        NSMenuItem *updateQuietlyItem = [NSMenuItem menuItemWithTitle:@"静默更新" action:[config selectorForPropertySEL:@selector(updateQuietlyEnable)] target:config keyEquivalent:@"" state:config.updateQuietlyEnable];

        NSMenu *subMenu = [[NSMenu alloc] initWithTitle:@"静默更新"];
        subMenu.autoenablesItems = NO;
        [subMenu addItem:updateQuietlyItem];
        item.submenu = subMenu;
    } else {
        item.submenu = nil;
    }
}

- (void)checkUpdateAction:(NSMenuItem *)item
{
    if (TZDownloadWindowController.sharedWindowController.downloadState == TZDownloadStateProgress)
    {
        NSAlert *alert = [[NSAlert alloc] init];
        alert.messageText = @"正在后台静默更新中";
        [alert runModal];
    } else {
        [TZVersionManager.sharedManager checkUpdatesCompletion:^(NSString * _Nonnull message, NSArray<NSNumber *> * _Nonnull updateTypes)
         {
             if (updateTypes.count) {
                 [TZVersionManager.sharedManager showUpdateMessage:message types:updateTypes];
             } else {

                 NSAlert *alert = [[NSAlert alloc] init];
                 alert.messageText = @"当前为最新版本！主要内容：👇";
                 alert.informativeText = message;
                 [alert runModal];
             }
         }];
    }
}

- (void)aboutAcion:(NSMenuItem *)item
{

}

#pragma mark - NSApplicationDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
    [self configMenus];
}

@end
