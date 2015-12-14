//
//  QTRDeviceNotFound.m
//  QuickTransfer
//
//  Created by Tarun Yadav on 14/12/15.
//  Copyright © 2015 Laughing Buddha Software. All rights reserved.
//

#import "QTRDeviceNotFound.h"

@implementation QTRDeviceNotFound

- (id)initWithFrame:(CGRect)aRect
{
    if ((self = [super initWithFrame:aRect])) {
        
        
        
        UILabel *topLabel = [[UILabel alloc]initWithFrame:CGRectZero];
        [topLabel setTranslatesAutoresizingMaskIntoConstraints:NO];
        [topLabel setBackgroundColor:[UIColor clearColor]];
        [self addSubview:topLabel];
        _topMessageLabel = topLabel;
        
        UILabel *bottomLabel = [[UILabel alloc]initWithFrame:CGRectZero];
        [bottomLabel setTranslatesAutoresizingMaskIntoConstraints:NO];
        [bottomLabel setBackgroundColor:[UIColor clearColor]];
        [self addSubview:bottomLabel];
        _bottomMessageLabel = bottomLabel;
        
        
        
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.frame = CGRectZero;
        [[button layer]setCornerRadius:7.0f];
        [[button layer]setBorderWidth:1.0f];
        [[button layer]setBorderColor:[UIColor whiteColor].CGColor];
        [[button layer]setMasksToBounds:TRUE];
        button.clipsToBounds = YES;
        [button setTitle:@"Next" forState:UIControlStateNormal];
        [button setTranslatesAutoresizingMaskIntoConstraints:NO];
        [self addSubview:button];
        _refreshButton = button;
        
        
        NSDictionary *views = NSDictionaryOfVariableBindings(topLabel , button, bottomLabel);
        
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-30-[topLabel]-30-|" options:0 metrics:0 views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-45-[button]-45-|" options:0 metrics:0 views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-30-[bottomLabel]-30-|" options:0 metrics:0 views:views]];
    
        
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"V:[galleryUIView(==231)]-5-[cancelButton(==44)]-5-|"] options:0 metrics:0 views:views]];
        
        
    }
    return self;
}


@end
