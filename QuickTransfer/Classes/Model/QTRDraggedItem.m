//
//  QTRDraggedItem.m
//  QuickTransfer
//
//  Created by Harshad on 25/11/15.
//  Copyright © 2015 Laughing Buddha Software. All rights reserved.
//

#import "QTRDraggedItem.h"

@implementation QTRDraggedItem

- (instancetype)initWithFileURL:(NSURL *)fileURL isDirectory:(BOOL)isDirectory {
    self = [super init];
    if (self != nil) {
        _fileURL = fileURL;
        _isDirectory = isDirectory;
    }

    return self;
}

@end
