//
//  QTRHomeCollectionViewCell.m
//  QuickTransfer
//
//  Created by Tarun Yadav on 24/11/15.
//  Copyright © 2015 Laughing Buddha Software. All rights reserved.
//

#import "QTRHomeCollectionViewCell.h"

@implementation QTRHomeCollectionViewCell

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
        UIImageView *_connectedDeviceImageLocal = [[UIImageView alloc]init];
        _connectedDeviceImageLocal.frame = CGRectMake(25, 0, 50, 60);
        _connectedDeviceImageLocal.layer.masksToBounds = YES;
        _connectedDeviceImageLocal.layer.cornerRadius = 8.0f;
        
        
        UILabel *_connectedDeviceNameLocal = [[UILabel alloc]initWithFrame:CGRectMake(0, 60, 100, 40)];
        [_connectedDeviceNameLocal setFont:[UIFont systemFontOfSize:14]];
        _connectedDeviceNameLocal.numberOfLines = 0;
        _connectedDeviceNameLocal.textAlignment = NSTextAlignmentCenter;
        _connectedDeviceNameLocal.textColor = [UIColor grayColor];

        
        [self.contentView addSubview:_connectedDeviceImageLocal];
        [self.contentView addSubview:_connectedDeviceNameLocal];
        

        
        self.connectedDeviceImage = _connectedDeviceImageLocal;
        self.connectedDeviceName = _connectedDeviceNameLocal;
        
        
        
        
    }
    return self;
}

@end
