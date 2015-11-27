//
//  QTRRightBarButtonView.m
//  QuickTransfer
//
//  Created by Tarun Yadav on 27/11/15.
//  Copyright © 2015 Laughing Buddha Software. All rights reserved.
//

#import "QTRRightBarButtonView.h"

@implementation QTRRightBarButtonView

- (id)initWithFrame:(CGRect)aRect
{
    if ((self = [super initWithFrame:aRect])) {
    
    self.frame = CGRectMake(0.f, 0.f, 36.f, 36.f);
        
        UIBezierPath *path12 = [UIBezierPath bezierPath];
        [path12 moveToPoint:CGPointMake(12.f, 4.f)];
        [path12 addLineToPoint:CGPointMake(12.f, 23.f)];
        
        CAShapeLayer *shapeLayer12 = [CAShapeLayer layer];
        shapeLayer12.path = [path12 CGPath];
        shapeLayer12.strokeColor = [[UIColor colorWithRed:32.f/255.f green:149.f/255.f blue:242.f/255.f alpha:1.00f] CGColor];
        shapeLayer12.lineWidth = 1.0f;
        shapeLayer12.fillColor = [[UIColor clearColor] CGColor];
        [self.layer addSublayer:shapeLayer12];
        
        UIBezierPath *path11 = [UIBezierPath bezierPath];
        [path11 moveToPoint:CGPointMake(12.f, 4.f)];
        [path11 addLineToPoint:CGPointMake(5.f, 11.f)];
        
        CAShapeLayer *shapeLayer11 = [CAShapeLayer layer];
        shapeLayer11.path = [path11 CGPath];
        shapeLayer11.strokeColor = [[UIColor colorWithRed:32.f/255.f green:149.f/255.f blue:242.f/255.f alpha:1.00f] CGColor];
        shapeLayer11.lineWidth = 1.0f;
        shapeLayer11.fillColor = [[UIColor clearColor] CGColor];
        [self.layer addSublayer:shapeLayer11];
        
        
        UIBezierPath *path13 = [UIBezierPath bezierPath];
        [path13 moveToPoint:CGPointMake(12.f, 4.f)];
        [path13 addLineToPoint:CGPointMake(19.f, 11.f)];
        
        CAShapeLayer *shapeLayer13 = [CAShapeLayer layer];
        shapeLayer13.path = [path13 CGPath];
        shapeLayer13.strokeColor = [[UIColor colorWithRed:32.f/255.f green:149.f/255.f blue:242.f/255.f alpha:1.00f] CGColor];
        shapeLayer13.lineWidth = 1.0f;
        shapeLayer13.fillColor = [[UIColor clearColor] CGColor];
        [self.layer addSublayer:shapeLayer13];
        
        
        
        
        UIBezierPath *path22 = [UIBezierPath bezierPath];
        [path22 moveToPoint:CGPointMake(22.f, 28.f)];
        [path22 addLineToPoint:CGPointMake(22.f, 9.f)];
        
        CAShapeLayer *shapeLayer22 = [CAShapeLayer layer];
        shapeLayer22.path = [path22 CGPath];
        shapeLayer22.strokeColor = [[UIColor colorWithRed:32.f/255.f green:149.f/255.f blue:242.f/255.f alpha:1.00f] CGColor];
        shapeLayer22.lineWidth = 1.0f;
        shapeLayer22.fillColor = [[UIColor clearColor] CGColor];
        [self.layer addSublayer:shapeLayer22];
        
        UIBezierPath *path21 = [UIBezierPath bezierPath];
        [path21 moveToPoint:CGPointMake(22.f, 28.f)];
        [path21 addLineToPoint:CGPointMake(15.f, 21.f)];
        
        CAShapeLayer *shapeLayer21 = [CAShapeLayer layer];
        shapeLayer21.path = [path21 CGPath];
        shapeLayer21.strokeColor = [[UIColor colorWithRed:32.f/255.f green:149.f/255.f blue:242.f/255.f alpha:1.00f] CGColor];
        shapeLayer21.lineWidth = 1.0f;
        shapeLayer21.fillColor = [[UIColor clearColor] CGColor];
        [self.layer addSublayer:shapeLayer21];
        
        
        UIBezierPath *path23 = [UIBezierPath bezierPath];
        [path23 moveToPoint:CGPointMake(22.f, 28.f)];
        [path23 addLineToPoint:CGPointMake(29.f, 21.f)];
        
        CAShapeLayer *shapeLayer23 = [CAShapeLayer layer];
        shapeLayer23.path = [path23 CGPath];
        shapeLayer23.strokeColor = [[UIColor colorWithRed:32.f/255.f green:149.f/255.f blue:242.f/255.f alpha:1.00f] CGColor];
        shapeLayer23.lineWidth = 1.0f;
        shapeLayer23.fillColor = [[UIColor clearColor] CGColor];
        [self.layer addSublayer:shapeLayer23];
        


    }
    return self;
}
@end
