//
//  QTRDeviceDeviceCollectionViewItem.m
//  QuickTransfer
//
//  Created by Harshad on 17/12/15.
//  Copyright © 2015 Laughing Buddha Software. All rights reserved.
//

#import "QTRDeviceDeviceCollectionViewItem.h"
#import "QTRDeviceCollectionViewItemView.h"
#import "QTRUser.h"

@interface QTRDeviceDeviceCollectionViewItem ()

@end

@implementation QTRDeviceDeviceCollectionViewItem

- (void)setSelected:(BOOL)selected {
    [super setSelected:selected];
    QTRDeviceCollectionViewItemView *itemView = (QTRDeviceCollectionViewItemView *)self.view;
    if (selected) {
        [[itemView nameField] setTextColor:[NSColor colorWithRed:0.3 green:0.85 blue:0.39 alpha:1]];
    } else {
        [[itemView nameField] setTextColor:[NSColor whiteColor]];
    }
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    if ([representedObject isKindOfClass:[QTRUser class]]) {
        QTRUser *user = (QTRUser *)representedObject;
        NSString *imageName = @"MacIcon";
        if ([user.platform isEqualToString:QTRUserPlatformIOS] || [user.platform isEqualToString:QTRUserPlatformAndroid]) {
            imageName = @"iOSDevice";
        }
        NSImage *image = [NSImage imageNamed:imageName];
        QTRDeviceCollectionViewItemView *itemView = (QTRDeviceCollectionViewItemView *)self.view;
        [[itemView platformImageView] setImage:image];
    }
}



@end
