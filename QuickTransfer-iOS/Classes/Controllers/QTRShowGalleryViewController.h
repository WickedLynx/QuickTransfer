//
//  QTRShowGalleryViewController.h
//  QuickTransfer
//
//  Created by Tarun Yadav on 26/11/15.
//  Copyright © 2015 Laughing Buddha Software. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AssetsLibrary/AssetsLibrary.h>

@interface QTRShowGalleryViewController : UIViewController 
{
    ALAssetsLibrary *library;
    NSArray *imageArray;
    NSMutableArray *mutableArray;
}

-(void)allPhotosCollected:(NSArray*)imgArray;
@property(nonatomic,retain) UISegmentedControl *segmentedControl;

@property(nonatomic,retain) UIImageView *imageView;
@property (weak, nonatomic) UIButton *sendButton;



@end
