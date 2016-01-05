//
//  QTRTransfersTableCellView.m
//  QuickTransfer
//
//  Created by Harshad on 28/02/14.
//  Copyright (c) 2014 Laughing Buddha Software. All rights reserved.
//

#import "QTRTransfersTableCellView.h"
#import "QTRTransfer.h"
#import "QTRUser.h"
#import "QTRFile.h"

@implementation QTRTransfersTableCellView {
    NSTrackingArea *_trackingArea;
}

- (void)awakeFromNib {
    [super awakeFromNib];

    [self.leftButton setTarget:self];
    [self.leftButton setAction:@selector(clickLeftButton)];
}

- (void)setObjectValue:(id)objectValue {
    if ([objectValue isKindOfClass:[QTRTransfer class]]) {
        QTRTransfer *transfer = (QTRTransfer *)objectValue;

        [self.recipientNameField setStringValue:transfer.user.name];
        [self.fileSizeField setIntegerValue:transfer.fileSize];
        [self.fileNameField setStringValue:[[transfer.fileURL path] lastPathComponent]];

        switch (transfer.state) {
            case QTRTransferStateInProgress:
                [self.timestampField setObjectValue:[NSString stringWithFormat:@"%d%% completed", (int)(transfer.progress * 100)]];
                if ([transfer isIncoming]) {
                    [self.timestampField setTextColor:[NSColor colorWithRed:0.35 green:0.78 blue:0.98 alpha:1]];
                    [self.leftButton setImage:[NSImage imageNamed:@"IncomingFileIcon"]];
                } else {
                    [self.timestampField setTextColor:[NSColor colorWithRed:0.3 green:0.85 blue:0.39 alpha:1]];
                    [self.leftButton setImage:[NSImage imageNamed:@"OutgoingFileIcon"]];
                }
                break;

            case QTRTransferStateCompleted:
                [self.timestampField setObjectValue:transfer.timestamp];
                [self.timestampField setTextColor:self.recipientNameField.textColor];
                if ([transfer isIncoming]) {
                    [self.leftButton setImage:[NSImage imageNamed:@"IncomingFileIcon"]];
                } else {
                    [self.leftButton setImage:[NSImage imageNamed:@"OutgoingFileIcon"]];
                }
                break;

            case QTRTransferStateFailed:
                [self.timestampField setObjectValue:@"Failed"];
                [self.timestampField setTextColor:[NSColor colorWithRed:1 green:0.23 blue:0.19 alpha:1]];
                if (![transfer isIncoming]) {
                    [self.leftButton setImage:[NSImage imageNamed:@"RetryIcon"]];
                } else {
                    [self.leftButton setImage:nil];
                }
                break;

            case QTRTransferStatePaused:
                [self.timestampField setObjectValue:[NSString stringWithFormat:@"%d%% completed", (int)(transfer.progress * 100)]];
                if (![transfer isIncoming]) {
                    [self.leftButton setImage:[NSImage imageNamed:@"ResumeTransferIcon"]];
                } else {
                    [self.leftButton setImage:[NSImage imageNamed:@"PauseTransferIcon"]];
                }

            default:
                break;
        }

        [self setNeedsDisplay:YES];

    }
}

- (void)clickLeftButton {
    if ([self.delegate respondsToSelector:@selector(transfersTableCellViewDidClickPrimaryButton:)]) {
        [self.delegate transfersTableCellViewDidClickPrimaryButton:self];
    }
}

- (void)ensureTrackingArea {
    if (_trackingArea == nil) {
        _trackingArea = [[NSTrackingArea alloc] initWithRect:NSZeroRect options:NSTrackingInVisibleRect | NSTrackingActiveAlways | NSTrackingMouseEnteredAndExited owner:self userInfo:nil];
    }
}

- (void)updateTrackingAreas {
    [super updateTrackingAreas];
    [self ensureTrackingArea];
    if (![[self trackingAreas] containsObject:_trackingArea]) {
        [self addTrackingArea:_trackingArea];
    }
}

- (void)mouseEntered:(NSEvent *)theEvent {
    [super mouseEntered:theEvent];

    if ([self.delegate respondsToSelector:@selector(transferForCellView:)]) {
        QTRTransfer *transfer = [self.delegate transferForCellView:self];
        if (![transfer isIncoming]) {
            if (transfer.state == QTRTransferStateInProgress) {
                [self.leftButton setImage:[NSImage imageNamed:@"PauseTransferIcon"]];
            }
        }
    }
}

- (void)mouseExited:(NSEvent *)theEvent {
    [super mouseExited:theEvent];

    if ([self.delegate respondsToSelector:@selector(transferForCellView:)]) {
        QTRTransfer *transfer = [self.delegate transferForCellView:self];
        if (![transfer isIncoming]) {
            if (transfer.state == QTRTransferStateInProgress) {
                [self.leftButton setImage:[NSImage imageNamed:@"OutgoingFileIcon"]];
            }
        }
    }
}
@end
