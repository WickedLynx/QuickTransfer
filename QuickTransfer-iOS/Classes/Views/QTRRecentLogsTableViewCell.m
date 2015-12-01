//
//  QTRRecentLogsTableViewCell.m
//  QuickTransfer
//
//  Created by Tarun Yadav on 30/11/15.
//  Copyright © 2015 Laughing Buddha Software. All rights reserved.
//

#import "QTRRecentLogsTableViewCell.h"

@implementation QTRRecentLogsTableViewCell



- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {

        
        self.fileNameLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        self.fileNameLabel.textColor = [UIColor blackColor];
        [self.fileNameLabel setTranslatesAutoresizingMaskIntoConstraints:NO];
        self.fileNameLabel.textAlignment = NSTextAlignmentLeft;
        self.fileNameLabel.font = [UIFont fontWithName:@"Arial" size:12.0f];
        
        self.userNameLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        self.userNameLabel.textColor = [UIColor blackColor];
        [self.userNameLabel setTranslatesAutoresizingMaskIntoConstraints:NO];
        self.userNameLabel.textAlignment = NSTextAlignmentLeft;
        self.userNameLabel.font = [UIFont fontWithName:@"Arial" size:10.0f];

        self.fileSizeLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        self.fileSizeLabel.textColor = [UIColor blackColor];
        [self.fileSizeLabel setTranslatesAutoresizingMaskIntoConstraints:NO];
        self.fileSizeLabel.textAlignment = NSTextAlignmentRight;
        self.fileSizeLabel.font = [UIFont fontWithName:@"Arial" size:12.0f];

        self.currentStatusLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        self.currentStatusLabel.textColor = [UIColor blackColor];
        [self.currentStatusLabel setTranslatesAutoresizingMaskIntoConstraints:NO];
        self.currentStatusLabel.textAlignment = NSTextAlignmentRight;
        self.currentStatusLabel.font = [UIFont fontWithName:@"Arial" size:10.0f];

        
        [self addSubview:self.fileNameLabel];
        [self addSubview:self.userNameLabel];
        [self addSubview:self.fileSizeLabel];
        [self addSubview:self.currentStatusLabel];
        
        NSDictionary *views = NSDictionaryOfVariableBindings(_fileNameLabel, _userNameLabel, _fileSizeLabel, _currentStatusLabel );
        
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-46-[_fileNameLabel]-0-[_fileSizeLabel]-16-|" options:0 metrics:0 views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-46-[_userNameLabel]-0-[_currentStatusLabel]-16-|" options:0 metrics:0 views:views]];
        //[self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-100-[_fileSizeLabel]-16-|" options:0 metrics:0 views:views]];
        //[self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-100-[_currentStatusLabel]-16-|" options:0 metrics:0 views:views]];

        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-3-[_fileNameLabel]-0-[_userNameLabel]-5-|" options:0 metrics:0 views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-4-[_fileSizeLabel]-0-[_currentStatusLabel]-5-|" options:0 metrics:0 views:views]];

        
    }
    return self;
}


@end
