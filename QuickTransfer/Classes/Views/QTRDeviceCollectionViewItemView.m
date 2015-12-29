//
//  QTRDeviceCollectionViewItemView.m
//  QuickTransfer
//
//  Created by Harshad on 17/12/15.
//  Copyright © 2015 Laughing Buddha Software. All rights reserved.
//

#import "QTRDeviceCollectionViewItemView.h"

@implementation QTRDeviceCollectionViewItemView

- (NSImageView *)platformImageView {
    NSImageView *imageView = [self viewWithTag:101];
    [imageView unregisterDraggedTypes];
    return imageView;
}

- (NSTextField *)nameField {
    return [self viewWithTag:102];
}

@end
