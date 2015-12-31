//
//  QTRGalleryCollectionViewCell.m
//  QuickTransfer
//
//  Created by Tarun Yadav on 26/11/15.
//  Copyright © 2015 Laughing Buddha Software. All rights reserved.
//

#import "QTRGalleryCollectionViewCell.h"

@interface QTRGalleryCollectionViewCell()

@property (nonatomic, strong) UIImageView *fetchImageView;
@property (nonatomic, strong) UIImageView *selectedImageView;
@property (nonatomic, strong) UIActivityIndicatorView *fetchImageLoader;

@end



@implementation QTRGalleryCollectionViewCell



- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
        self.fetchImageView = [[UIImageView alloc]init];
        self.selectedImageView = [[UIImageView alloc]init];
    
        self.fetchImageView.frame = self.contentView.frame;
        self.fetchImageView.layer.masksToBounds = YES;
        self.fetchImageView.contentMode = UIViewContentModeScaleAspectFill;
        
        self.selectedImageView.frame = self.contentView.frame;
        self.selectedImageView.backgroundColor = [UIColor colorWithWhite:1.0f alpha:0.4f];
        
        UIButton *selectedButton = [UIButton buttonWithType:UIButtonTypeCustom];
        UIImage *buttonCheckImage = [UIImage imageNamed:@"check"];
        
        selectedButton.frame = CGRectMake(50, 50, buttonCheckImage.size.width, buttonCheckImage.size.height);
        
        [selectedButton setImage:buttonCheckImage forState:UIControlStateNormal];
        
        selectedButton.contentMode = UIViewContentModeScaleToFill;
        [self.selectedImageView addSubview:selectedButton];
        
        [self addSubview:self.fetchImageView];
        
        self.fetchImageLoader = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        [self.fetchImageLoader setCenter:self.center];
        [self.fetchImageLoader startAnimating];
        [self addSubview:self.fetchImageLoader];

    }
    return self;
}


-(void)setSelected:(BOOL)selected {
    
    [super setSelected:selected];
    if (selected) {

        [self.fetchImageView addSubview:self.selectedImageView];
        
    }else {
        [self.selectedImageView removeFromSuperview];

    }
}

- (void)resetImage:(NSUInteger)item {
    
    self.fetchImageView.image = nil;
    [self.fetchImageLoader startAnimating];
}

- (void)setImage:(UIImage *)image fetchItem:(NSUInteger)item {
    
    self.fetchImageView.image = image;
    [self.fetchImageLoader stopAnimating];

}


@end
