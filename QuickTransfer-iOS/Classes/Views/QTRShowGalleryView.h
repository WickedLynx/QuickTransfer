//
//  QTRShowGalleryView.h
//  QuickTransfer
//
//  Created by Tarun Yadav on 28/12/15.
//  Copyright © 2015 Laughing Buddha Software. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface QTRShowGalleryView : UIView

@property(nonatomic, weak) UICollectionView *galleryCollectionView;
@property(nonatomic, weak) UIButton *sendButton;
@property(nonatomic, weak) UICollectionViewFlowLayout *galleryCollectionViewLayout;

@end
