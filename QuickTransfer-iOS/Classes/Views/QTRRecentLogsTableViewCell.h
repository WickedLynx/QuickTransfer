//
//  QTRRecentLogsTableViewCell.h
//  QuickTransfer
//
//  Created by Tarun Yadav on 30/11/15.
//  Copyright © 2015 Laughing Buddha Software. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface QTRRecentLogsTableViewCell : UITableViewCell

@property (nonatomic, strong) UILabel *fileNameLabel;
@property (nonatomic, strong) UILabel *userNameLabel;
@property (nonatomic, strong) UILabel *currentStatusLabel;
@property (nonatomic, strong) UILabel *fileSizeLabel;

@property (nonatomic ,strong) UIButton *fileStateButton;


@end
