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
        _connectedDeviceImageLocal.frame = CGRectZero;
        [_connectedDeviceImageLocal setTranslatesAutoresizingMaskIntoConstraints:NO];
        _connectedDeviceImageLocal.layer.masksToBounds = YES;
        _connectedDeviceImageLocal.layer.cornerRadius = 40.0f;
        [_connectedDeviceImageLocal setBackgroundColor:[UIColor colorWithRed:85.f/255.f green:85.f/255.f blue:85.f/255.f alpha:1.00f]];
        
//        UIImageView *connectedDeviceImageIcon = [[UIImageView alloc]init];
//        connectedDeviceImageIcon.frame = CGRectMake(25.0f, 10.0f, 50.0f, 50.0f);
//        [connectedDeviceImageIcon setContentMode:UIViewContentModeScaleAspectFit];
    

        
        UILabel *_connectedDeviceNameLocal = [[UILabel alloc]initWithFrame:CGRectZero];
        [_connectedDeviceNameLocal setTranslatesAutoresizingMaskIntoConstraints:NO];
//        [_connectedDeviceNameLocal setFont:[UIFont systemFontOfSize:13.0f]];
        [_connectedDeviceNameLocal setFont:[UIFont fontWithName:@"SanFranciscoText-Light" size:13]];
        _connectedDeviceNameLocal.numberOfLines = 2;
        _connectedDeviceNameLocal.textAlignment = NSTextAlignmentCenter;
        _connectedDeviceNameLocal.textColor = [UIColor whiteColor];
        
        [self.contentView addSubview:_connectedDeviceImageLocal];
        [self.contentView addSubview:_connectedDeviceNameLocal];
        //[self.contentView addSubview:connectedDeviceImageIcon];
        
        self.connectedDeviceImage = _connectedDeviceImageLocal;
        self.connectedDeviceName = _connectedDeviceNameLocal;
       // self.connectedDeviceImageIcon = connectedDeviceImageIcon;
        
        
        NSDictionary *views = NSDictionaryOfVariableBindings(_connectedDeviceImageLocal,_connectedDeviceNameLocal);
        
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[_connectedDeviceImageLocal(==80)]" options:0 metrics:0 views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[_connectedDeviceNameLocal(==90)]" options:0 metrics:0 views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[_connectedDeviceImageLocal(==80)]" options:0 metrics:0 views:views]];
        
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-80-[_connectedDeviceNameLocal]" options:0 metrics:0 views:views]];
        
        
        
        
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
    
//    _connectedDeviceImageIcon.image = [UIImage imageNamed:@"iphoneicon"];
    [_connectedDeviceImage setImage:[UIImage imageNamed:@"iphoneicon"]];
    NSLog(@"lol");
}
    
@end
