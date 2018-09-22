//
//  TZAboutWindowController.m
//  WeChatPluginWrapper
//
//  Created by TozyZuo on 2018/9/22.
//  Copyright © 2018年 TozyZuo. All rights reserved.
//

#import "TZAboutWindowController.h"
#import "TZConfigManager.h"

@interface TZAboutWindowController ()
@property (weak) IBOutlet NSTextView *textView;
@property (weak) IBOutlet NSTextField *versionLabel;
@end

@implementation TZAboutWindowController

- (void)windowDidLoad
{
    [super windowDidLoad];
    self.window.backgroundColor = [NSColor whiteColor];
    self.versionLabel.stringValue = TZConfigManager.sharedManager.localVersion;

    NSString *path = [[NSBundle bundleWithIdentifier:@"com.tozy.WeChatPluginWrapper"] pathForResource:@"about" ofType:@"rtfd"];
    [self.textView readRTFDFromFile:path];
    self.textView.selectable = YES;
}

@end
