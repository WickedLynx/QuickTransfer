//
//  QTRGalleryCollectionViewCell.h
//  QuickTransfer
//
//  Created by Tarun Yadav on 26/11/15.
//  Copyright © 2015 Laughing Buddha Software. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface QTRGalleryCollectionViewCell : UICollectionViewCell


- (void)resetImage:(NSUInteger)item;
- (void)setImage:(UIImage *)image fetchItem:(NSUInteger)item;

@end
