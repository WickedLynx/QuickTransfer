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
        // Initialization code

        [self setBackgroundColor:[UIColor whiteColor]];

        @autoreleasepool {
            UILabel * (^ addLabel)(CGRect, UIFont *, UIViewAutoresizing) = ^UILabel * (CGRect frame, UIFont *font, UIViewAutoresizing autoresizingMask) {

                UILabel *aLabel = [[UILabel alloc] initWithFrame:frame];
                [aLabel setFont:font];
                [aLabel setAutoresizingMask:autoresizingMask];
                [self addSubview:aLabel];

                return aLabel;
            };

            _titleLabel = addLabel(CGRectMake(40.00f, 10.00f, 150.00f, 20.00f), [UIFont systemFontOfSize:13.0f], (UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleRightMargin));
            _subtitleLabel = addLabel(CGRectMake(40.00f, 25.00f, 150.0f, 20.00f), [UIFont systemFontOfSize:10.0f], (UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleRightMargin));

//            UIProgressView *aProgressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleBar];
//            [aProgressView setFrame:CGRectMake(85.0f, 55.0f, 190.0f, 10.0f)];
//            [self addSubview:aProgressView];
//            _progressView = aProgressView;

            _fileSizeLabel = addLabel(CGRectMake(190.00f, 10.00f, 100.0f, 20.00f), [UIFont systemFontOfSize:13.0f], (UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleRightMargin));

            _fileStateLabel = addLabel(CGRectMake(190.00f, 25.00f, 100.0f, 20.00f), [UIFont systemFontOfSize:10.0f], (UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleRightMargin));
            
            _fileSizeLabel.textAlignment = NSTextAlignmentRight;
            _fileStateLabel.textAlignment = NSTextAlignmentRight;
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
