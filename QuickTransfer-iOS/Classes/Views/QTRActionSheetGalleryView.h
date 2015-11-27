//
//  QTRActionSheetGalleryView.h
//  QuickTransfer
//
//  Created by Tarun Yadav on 27/11/15.
//  Copyright © 2015 Laughing Buddha Software. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AssetsLibrary/AssetsLibrary.h>

@interface QTRActionSheetGalleryView : UIView  <UICollectionViewDelegate,UICollectionViewDataSource>
{
    ALAssetsLibrary *library;
    NSArray *imageArray;
    NSMutableArray *mutableArray;
    UICollectionView *aCollectionView;
}

-(void)allPhotosCollected:(NSArray*)imgArray;

@property (weak, nonatomic) UICollectionView *actionControllerCollectionView;

@end
