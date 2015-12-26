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
        
        UIImageView *connectedDeviceImage = [[UIImageView alloc]init];
        connectedDeviceImage.frame = CGRectZero;
        [connectedDeviceImage setTranslatesAutoresizingMaskIntoConstraints:NO];
        connectedDeviceImage.layer.masksToBounds = YES;
        connectedDeviceImage.layer.cornerRadius = 40.0f;
        [connectedDeviceImage setBackgroundColor:[UIColor colorWithRed:85.f/255.f green:85.f/255.f blue:85.f/255.f alpha:1.00f]];
        
        UILabel *connectedDeviceName = [[UILabel alloc]initWithFrame:CGRectZero];
        [connectedDeviceName setTranslatesAutoresizingMaskIntoConstraints:NO];
        [connectedDeviceName setFont:[UIFont fontWithName:@"SanFranciscoText-Light" size:13]];
        connectedDeviceName.numberOfLines = 2;
        connectedDeviceName.textAlignment = NSTextAlignmentCenter;
        connectedDeviceName.textColor = [UIColor whiteColor];
        
        [self.contentView addSubview:connectedDeviceImage];
        [self.contentView addSubview:connectedDeviceName];
        
        self.connectedDeviceImage = connectedDeviceImage;
        self.connectedDeviceName = connectedDeviceName;
       
        
        NSDictionary *views = NSDictionaryOfVariableBindings(connectedDeviceImage,connectedDeviceName);
        
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-10-[connectedDeviceImage(==80)]-10-|" options:0 metrics:0 views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-5-[connectedDeviceName(==90)]-5-|" options:0 metrics:0 views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[connectedDeviceImage(==80)]" options:0 metrics:0 views:views]];
        
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-80-[connectedDeviceName]" options:0 metrics:0 views:views]];
        
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
    [_connectedDeviceImage setImage:[UIImage imageNamed:imagePlatform]];
}
    
@end
