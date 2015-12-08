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
        
        self.retrivedImage = [[UIImageView alloc]init];
        self.selectedImage = [[UIImageView alloc]init];
    
        self.retrivedImage.frame = self.contentView.frame;
        self.retrivedImage.layer.masksToBounds = YES;
        
        self.selectedImage.frame = self.contentView.frame;
        self.selectedImage.backgroundColor = [UIColor colorWithWhite:1.0f alpha:0.4f];
        
        self.selectedButton = [UIButton buttonWithType:UIButtonTypeCustom];
        UIImage *img = [UIImage imageNamed:@"check"];
        
        self.selectedButton.frame = CGRectMake(50, 50, img.size.width, img.size.height);
        
        [self.selectedButton setImage:img forState:UIControlStateNormal];
        [self.selectedButton setImage:img forState:UIControlStateHighlighted];
        [self.selectedButton setImage:img forState:UIControlStateSelected];
        
        self.selectedButton.contentMode = UIViewContentModeScaleToFill;
        [self.selectedImage addSubview:self.selectedButton];
        
        
        
        [self addSubview:self.retrivedImage];


        
    }
    return self;
}


-(void)setSelected:(BOOL)selected {
    
    [super setSelected:selected];
    if (selected) {
        NSLog(@"Selected..");

        [self.retrivedImage addSubview:self.selectedImage];
        
    }else {
        NSLog(@"Deselected");
        [self.selectedImage removeFromSuperview];

    }
}


@end
