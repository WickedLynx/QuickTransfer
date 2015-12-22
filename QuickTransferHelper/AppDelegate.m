//
//  AppDelegate.m
//  QuickTransferHelper
//
//  Created by Harshad on 22/12/15.
//  Copyright © 2015 Laughing Buddha Software. All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;
@end

@implementation AppDelegate

// Source: http://stackoverflow.com/questions/11536477/mac-os-x-start-on-launch-while-in-app-store/11561143#11561143
- (void)applicationWillFinishLaunching:(NSNotification *)notification {
    NSString *appPath = [[[[[[NSBundle mainBundle] bundlePath] stringByDeletingLastPathComponent] stringByDeletingLastPathComponent] stringByDeletingLastPathComponent] stringByDeletingLastPathComponent];
    // This string takes you from MyGreat.App/Contents/Library/LoginItems/MyHelper.app to MyGreat.App This is an obnoxious but dynamic way to do this since that specific Subpath is required
    NSString *binaryPath = [[NSBundle bundleWithPath:appPath] executablePath]; // This gets the binary executable within your main application
    [[NSWorkspace sharedWorkspace] launchApplication:binaryPath];
    [NSApp terminate:nil];
}

@end
