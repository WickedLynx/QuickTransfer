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
        
        UITableView *aTableView = [[UITableView alloc] initWithFrame:self.bounds];
        [aTableView setAutoresizingMask:(UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth)];
        [self addSubview:aTableView];
        _devicesTableView = aTableView;
    }
    
    return self;
}

@end
