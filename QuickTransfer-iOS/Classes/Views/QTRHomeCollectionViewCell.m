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
        _connectedDeviceImageLocal.frame = CGRectMake(15, 0, 65, 65);
        _connectedDeviceImageLocal.layer.masksToBounds = YES;
        _connectedDeviceImageLocal.layer.cornerRadius = 32.5f;
        [_connectedDeviceImageLocal setBackgroundColor:[UIColor colorWithRed:85.f/255.f green:85.f/255.f blue:85.f/255.f alpha:1.00f]];
        
//        UIImageView *_connectedDeviceImageIconLocal = [[UIImageView alloc]init];
//        _connectedDeviceImageIconLocal.frame = CGRectMake(30.0f, 7.5f, 30.0f, 45.0f);

        
        UILabel *_connectedDeviceNameLocal = [[UILabel alloc]initWithFrame:CGRectMake(0, 60, 100, 40)];
        [_connectedDeviceNameLocal setFont:[UIFont systemFontOfSize:12]];
        _connectedDeviceNameLocal.numberOfLines = 0;
        _connectedDeviceNameLocal.textAlignment = NSTextAlignmentCenter;
        _connectedDeviceNameLocal.textColor = [UIColor whiteColor];
        
        [self.contentView addSubview:_connectedDeviceImageLocal];
        [self.contentView addSubview:_connectedDeviceNameLocal];
        //[self.contentView addSubview:_connectedDeviceImageIconLocal];
        

        
        self.connectedDeviceImage = _connectedDeviceImageLocal;
        self.connectedDeviceName = _connectedDeviceNameLocal;
        //self.connectedDeviceImageIcon = _connectedDeviceImageIconLocal;
        
        
        
        
    }
    return self;
}

-(void)setSelected:(BOOL)selected {
    
    [super setSelected:selected];
    if (selected) {
        self.connectedDeviceName.textColor = [UIColor colorWithRed:32.f/255.f green:149.f/255.f blue:242.f/255.f alpha:1.00f];
    }else {
        self.connectedDeviceName.textColor = [UIColor whiteColor];
    }
}

-(void)setIconImage:(NSString *)imagePlatform {
    
    NSString *iconImageName;
    UIImageView *iconImageView;
    
    if ([imagePlatform isEqualToString:@"Android"]) {
        iconImageName = @"android_tab";
        
    } else if ([imagePlatform isEqualToString:@"iOS"]) {
        iconImageName = @"apple_iphone";
        
    } else if ([imagePlatform isEqualToString:@"Linux"]) {
        iconImageName = @"apple_desktop";
        
    } else if ([imagePlatform isEqualToString:@"Mac"]) {
        iconImageName = @"apple_laptop";
        
    } else if ([imagePlatform isEqualToString:@"Windows"]) {
        iconImageName = @"windows_desktop";
        
    }else {
        iconImageName = @"apple_phone";
    }
    
    iconImageView = [[UIImageView alloc]initWithImage:[UIImage imageNamed:iconImageName]];
    
    if (!iconImageView.image) {
        iconImageView = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"apple_phone"]];
    }
    
    
    iconImageView.center = CGPointMake(32.5f, 32.5f);
    
    [self.connectedDeviceImage addSubview:iconImageView];
    
    
    
}
    
@end
