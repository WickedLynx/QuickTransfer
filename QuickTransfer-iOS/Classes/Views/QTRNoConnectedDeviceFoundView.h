//
//  QTRNoConnectedDeviceFoundView.h
//  QuickTransfer
//
//  Created by Tarun Yadav on 24/12/15.
//  Copyright © 2015 Laughing Buddha Software. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface QTRNoConnectedDeviceFoundView : UIView

@property (retain, nonatomic) UILabel *topMessageLabel;
@property (retain, nonatomic) UILabel *bottomMessageLabel;
@property (weak, nonatomic) UIButton *refreshButton;

@end
