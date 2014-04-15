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
    __weak UILabel *_footerLabel;
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

            _titleLabel = addLabel(CGRectMake(85.00f, 12.00f, 190.00f, 22.00f), [UIFont boldSystemFontOfSize:13.0f], (UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleRightMargin));
            _subtitleLabel = addLabel(CGRectMake(85.00f, 33.00f, 190.0f, 18.00f), [UIFont systemFontOfSize:13.0f], (UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleRightMargin));

            UIProgressView *aProgressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleBar];
            [aProgressView setFrame:CGRectMake(85.0f, 55.0f, 190.0f, 10.0f)];
            [self addSubview:aProgressView];
            _progressView = aProgressView;

            _footerLabel = addLabel(CGRectMake(85.00f, 60.00f, 190.0f, 18.00f), [UIFont italicSystemFontOfSize:12.0f], (UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleRightMargin));

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

- (UILabel *)footerLabel {
    return _footerLabel;
}

- (UIProgressView *)progressView {
    return _progressView;
}

- (CGFloat)requiredHeightInTableView {
    CGFloat requiredHeight = 0.0f;

    requiredHeight = _footerLabel.frame.origin.y + (1.5 * _footerLabel.frame.size.height);
    
    return requiredHeight;
}

@end
