//
//  QTRTempTransView.m
//  QuickTransfer
//
//  Created by Tarun Yadav on 08/12/15.
//  Copyright © 2015 Laughing Buddha Software. All rights reserved.
//

#import "QTRTempTransView.h"

@implementation QTRTempTransView

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
