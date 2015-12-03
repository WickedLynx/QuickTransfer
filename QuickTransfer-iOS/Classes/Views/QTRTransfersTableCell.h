//
//  QTRTransfersTableCell.h
//  QuickTransfer
//
//  Created by Harshad on 04/04/14.
//  Copyright (c) 2014 Laughing Buddha Software. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface QTRTransfersTableCell : UITableViewCell

- (UILabel *)titleLabel;
- (UILabel *)subtitleLabel;
- (UILabel *)fileSizeLabel;
- (UILabel *)fileStateLabel;
- (CGFloat)requiredHeightInTableView;
- (UIProgressView *)progressView;

@end
