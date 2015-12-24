//
//  QTRNoConnectedDeviceFoundView.m
//  QuickTransfer
//
//  Created by Tarun Yadav on 24/12/15.
//  Copyright © 2015 Laughing Buddha Software. All rights reserved.
//

#import "QTRNoConnectedDeviceFoundView.h"

@implementation QTRNoConnectedDeviceFoundView



- (id)initWithFrame:(CGRect)aRect
{
    if ((self = [super initWithFrame:aRect])) {
        
        
        [self setBackgroundColor:[UIColor colorWithRed:55.f/255.f green:55.f/255.f blue:55.f/255.f alpha:1.00f]];
        float screenHeight = (self.frame.size.height / 3.0);
        
        
        UILabel *topLabel = [[UILabel alloc]initWithFrame:CGRectZero];
        [topLabel setTranslatesAutoresizingMaskIntoConstraints:NO];
        [topLabel setFont:[UIFont systemFontOfSize:16]];
        topLabel.numberOfLines = 1;
        topLabel.textAlignment = NSTextAlignmentCenter;
        [topLabel setText:@"There are no users online right now"];
        [topLabel setTextColor:[UIColor whiteColor]];
        [topLabel setBackgroundColor:[UIColor clearColor]];
        [self addSubview:topLabel];
        _topMessageLabel = topLabel;
        
        UILabel *bottomLabel = [[UILabel alloc]initWithFrame:CGRectZero];
        [bottomLabel setTranslatesAutoresizingMaskIntoConstraints:NO];
        [bottomLabel setFont:[UIFont systemFontOfSize:13]];
        bottomLabel.numberOfLines = 2;
        bottomLabel.textAlignment = NSTextAlignmentCenter;
        [bottomLabel setTextColor:[UIColor whiteColor]];
        [bottomLabel setText:@"Try again later, or tap on the refresh button above to see more local devices."];
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
        [button setTitle:@"Refresh" forState:UIControlStateNormal];
        [button setTranslatesAutoresizingMaskIntoConstraints:NO];
        [self addSubview:button];
        _refreshButton = button;
        
        
        NSDictionary *views = NSDictionaryOfVariableBindings(topLabel , button, bottomLabel);
        
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-32-[topLabel]-32-|" options:0 metrics:0 views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-58-[button]-58-|" options:0 metrics:0 views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-32-[bottomLabel]-32-|" options:0 metrics:0 views:views]];
        
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"V:|-%f-[button(==44)]",screenHeight] options:0 metrics:0 views:views]];
        
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"V:|-%f-[topLabel]",(screenHeight - 54)] options:0 metrics:0 views:views]];
        
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"V:|-%f-[bottomLabel]",(screenHeight + 79)] options:0 metrics:0 views:views]];
        
        
    }
    return self;
}


@end
