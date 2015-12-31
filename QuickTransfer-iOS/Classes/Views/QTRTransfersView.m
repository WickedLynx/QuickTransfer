//
//  QTRTransfersView.m
//  QuickTransfer
//
//  Created by Tarun Yadav on 24/12/15.
//  Copyright © 2015 Laughing Buddha Software. All rights reserved.
//

#import "QTRTransfersView.h"

@implementation QTRTransfersView

- (id)initWithFrame:(CGRect)frame {
    
    self = [super initWithFrame:frame];
    
    if (self != nil) {
        
        UITableView *devicesTableView = [[UITableView alloc] initWithFrame:self.bounds];
        [devicesTableView setAutoresizingMask:(UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth)];
        [self addSubview:devicesTableView];
        _devicesTableView = devicesTableView;
    }
    
    return self;
}

@end
