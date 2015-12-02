//
//  QTRGalleryCollectionViewCell.h
//  QuickTransfer
//
//  Created by Tarun Yadav on 26/11/15.
//  Copyright © 2015 Laughing Buddha Software. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface QTRGalleryCollectionViewCell : UICollectionViewCell

@property(nonatomic,retain) UIImageView *retrivedImage;
@property(nonatomic,retain) UIImageView *selectedImage;
@property(nonatomic,retain) UIButton *selectedButton;

@end
