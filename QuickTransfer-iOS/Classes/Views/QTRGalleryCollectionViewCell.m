//
//  QTRGalleryCollectionViewCell.m
//  QuickTransfer
//
//  Created by Tarun Yadav on 26/11/15.
//  Copyright © 2015 Laughing Buddha Software. All rights reserved.
//

#import "QTRGalleryCollectionViewCell.h"

@implementation QTRGalleryCollectionViewCell

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
        
        
        UIImageView *_connectedDeviceImageLocal = [[UIImageView alloc]init];
        _connectedDeviceImageLocal.frame = CGRectMake(0, 0, 75.5f, 75.5f);
        _connectedDeviceImageLocal.layer.masksToBounds = YES;
        //_connectedDeviceImageLocal.layer.cornerRadius = 30.0f;

        self.connectedDeviceImage = _connectedDeviceImageLocal;
        
        [self addSubview:_connectedDeviceImage];

//
        
    }
    return self;
}


@end
