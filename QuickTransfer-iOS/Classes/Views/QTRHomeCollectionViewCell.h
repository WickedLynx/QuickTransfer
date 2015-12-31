//
//  QTRHomeCollectionViewCell.h
//  QuickTransfer
//
//  Created by Tarun Yadav on 24/11/15.
//  Copyright © 2015 Laughing Buddha Software. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface QTRHomeCollectionViewCell : UICollectionViewCell

@property(nonatomic, strong) UIImageView *connectedDeviceImage;
@property(nonatomic, strong) UILabel *connectedDeviceName;

-(void)setIconImageByName:(NSString *)devicePlatformName;

@end
