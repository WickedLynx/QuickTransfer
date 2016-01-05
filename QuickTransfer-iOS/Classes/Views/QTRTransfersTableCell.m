//
//  QTRTransfersTableCell.m
//  QuickTransfer
//
//  Created by Harshad on 04/04/14.
//  Copyright (c) 2014 Laughing Buddha Software. All rights reserved.
//

#import "QTRTransfersTableCell.h"

@implementation QTRTransfersTableCell {

    __weak UILabel *_titleLabel;
    __weak UILabel *_subtitleLabel;
    __weak UILabel *_fileSizeLabel;
    __weak UILabel *_fileStateLabel;
    __weak UIProgressView *_progressView;

}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {

        [self setBackgroundColor:[UIColor whiteColor]];

        @autoreleasepool {
            UILabel * (^ addLabel)(CGRect, UIFont *, UIViewAutoresizing) = ^UILabel * (CGRect frame, UIFont *font, UIViewAutoresizing autoresizingMask) {

                UILabel *aLabel = [[UILabel alloc] initWithFrame:frame];
                [aLabel setFont:font];
                [aLabel setAutoresizingMask:autoresizingMask];
                [self addSubview:aLabel];

                return aLabel;
            };

            _titleLabel = addLabel(CGRectZero, [UIFont systemFontOfSize:13.0f], (UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleRightMargin));
            [_titleLabel setTextColor:[UIColor whiteColor]];
            [_titleLabel setTranslatesAutoresizingMaskIntoConstraints:NO];
            
            _subtitleLabel = addLabel(CGRectZero, [UIFont systemFontOfSize:10.0f], (UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleRightMargin));
            [_subtitleLabel setTextColor:[UIColor lightGrayColor]];
            [_subtitleLabel setTranslatesAutoresizingMaskIntoConstraints:NO];

            _fileSizeLabel = addLabel(CGRectZero, [UIFont systemFontOfSize:13.0f], (UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleRightMargin));
            [_fileSizeLabel setTextColor:[UIColor whiteColor]];
            [_fileSizeLabel setTranslatesAutoresizingMaskIntoConstraints:NO];

            _fileStateLabel = addLabel(CGRectZero, [UIFont systemFontOfSize:10.0f], (UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleRightMargin));
            [_fileStateLabel setTextColor:[UIColor lightGrayColor]];
            [_fileStateLabel setTranslatesAutoresizingMaskIntoConstraints:NO];
            
            _fileSizeLabel.textAlignment = NSTextAlignmentRight;
            _fileStateLabel.textAlignment = NSTextAlignmentRight;
            
            UIImageView *localIconImageView = [[UIImageView alloc]init];
            [localIconImageView setTranslatesAutoresizingMaskIntoConstraints:NO];
            [self addSubview:localIconImageView];
            _transferStateIconView = localIconImageView;
            
            
            
            NSDictionary *views = NSDictionaryOfVariableBindings(_titleLabel, _subtitleLabel, _fileSizeLabel, _fileStateLabel, _transferStateIconView);
            
            [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-43-[_titleLabel(==150)]" options:0 metrics:0 views:views]];
            [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-43-[_subtitleLabel(==150)]" options:0 metrics:0 views:views]];
            [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[_fileSizeLabel(==100)]-30-|" options:0 metrics:0 views:views]];
            [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[_fileStateLabel(==100)]-30-|" options:0 metrics:0 views:views]];
            [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-20-[_transferStateIconView(==11)]" options:0 metrics:0 views:views]];
            
            [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-10-[_titleLabel(==20)]-0-[_subtitleLabel]" options:0 metrics:0 views:views]];
            [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-10-[_fileSizeLabel(==20)]-0-[_fileStateLabel]" options:0 metrics:0 views:views]];
            [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-15-[_transferStateIconView(==11)]" options:0 metrics:0 views:views]];
            
            
            
            
        }
    }
    return self;
}

- (void)prepareForReuse {
    [super prepareForReuse];

    [_progressView setProgress:0.0f];
}

#pragma mark - Public methods

- (UILabel *)titleLabel {
    return _titleLabel;
}

- (UILabel *)subtitleLabel {
    return _subtitleLabel;
}

- (UILabel *)fileSizeLabel {
    return _fileSizeLabel;
}

- (UIProgressView *)progressView {
    return _progressView;
}

- (UILabel *)fileStateLabel {
    return _fileStateLabel;
}

- (CGFloat)requiredHeightInTableView {
    CGFloat requiredHeight = 0.0f;

    requiredHeight = 55.0f;
    
    return requiredHeight;
}

@end
