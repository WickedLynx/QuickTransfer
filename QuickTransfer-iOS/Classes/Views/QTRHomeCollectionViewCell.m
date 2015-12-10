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
        
        [self setBackgroundColor:[UIColor clearColor]];
        
        UIImageView *_connectedDeviceImageLocal = [[UIImageView alloc]init];
        _connectedDeviceImageLocal.frame = CGRectMake(15.0f, 0.0f, 70.0f, 70.0f);
        _connectedDeviceImageLocal.layer.masksToBounds = YES;
        _connectedDeviceImageLocal.layer.cornerRadius = 35.0f;
        [_connectedDeviceImageLocal setBackgroundColor:[UIColor colorWithRed:85.f/255.f green:85.f/255.f blue:85.f/255.f alpha:1.00f]];
        
        
        UILabel *_connectedDeviceNameLocal = [[UILabel alloc]initWithFrame:CGRectMake(10.0f, 65.0f, 80.0f, 40.0f)];
        [_connectedDeviceNameLocal setFont:[UIFont systemFontOfSize:12.0f]];
        _connectedDeviceNameLocal.numberOfLines = 0;
        _connectedDeviceNameLocal.textAlignment = NSTextAlignmentCenter;
        _connectedDeviceNameLocal.textColor = [UIColor whiteColor];
        
        [self.contentView addSubview:_connectedDeviceImageLocal];
        [self.contentView addSubview:_connectedDeviceNameLocal];
        
        self.connectedDeviceImage = _connectedDeviceImageLocal;
        self.connectedDeviceName = _connectedDeviceNameLocal;
        
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
    
    
//    NSLog(@"PlatForm Out: %@",imagePlatform);
//    
    UIImageView *iconImageView;
    
 
    
    
    
    if ([imagePlatform isEqualToString:@"Android"]) {
        iconImageView = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"android_phone"]];

        
    }
    
    if ([imagePlatform isEqualToString:@"iOS"]) {
        iconImageView = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"apple_phone"]];

        
    }
    
    if ([imagePlatform isEqualToString:@"Linux"]) {
        iconImageView = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"linux_desktop"]];

        
    }
    
    if ([imagePlatform isEqualToString:@"Mac"]) {
        iconImageView = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"apple_laptop"]];

        
    }
    
    if ([imagePlatform isEqualToString:@"Windows"]) {
        iconImageView = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"windows_desktop"]];

        
    }
    
    
    
    
    
    iconImageView.center = CGPointMake(34.5f, 32.5f);
    
    [self.connectedDeviceImage addSubview:iconImageView];
    
    
    
}
    
@end
