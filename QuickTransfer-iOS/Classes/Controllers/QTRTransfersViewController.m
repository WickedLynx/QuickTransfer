//
//  QTRTransfersViewController.m
//  QuickTransfer
//
//  Created by Harshad on 04/04/14.
//  Copyright (c) 2014 Laughing Buddha Software. All rights reserved.
//

#import "QTRTransfersViewController.h"
#import "QTRConnectedDevicesView.h"
#import "QTRTransfersTableCell.h"
#import "QTRTransfer.h"
#import "QTRFile.h"
#import "QTRUser.h"
#import "QTRHelper.h"
#import "QTRTransfersStore.h"

float const QTRTransfersControllerProgressThresholdIOS = 0.02f;

@interface QTRTransfersViewController () <UITableViewDataSource, UITableViewDelegate> {
    __weak QTRConnectedDevicesView *_transfersView;
    NSByteCountFormatter *_byteCountFormatter;
    NSDateFormatter *_dateFormatter;
    QTRTransfersStore *_transfersStore;
}

@end

@implementation QTRTransfersViewController

#pragma mark - Initialisation

- (id)init {
    self = [super init];
    if (self != nil) {

        NSURL *fileCacheDirectoryURL = [QTRHelper fileCacheDirectory];
        NSString *transfersArchiveFilePath = [[fileCacheDirectoryURL path] stringByAppendingPathComponent:@"Transfers"];
        _transfersStore = [[QTRTransfersStore alloc] initWithArchiveLocation:transfersArchiveFilePath];
        [_transfersStore setDelegate:self];

        _byteCountFormatter = [[NSByteCountFormatter alloc] init];
        _dateFormatter = [[NSDateFormatter alloc] init];

        [_dateFormatter setDateStyle:NSDateFormatterShortStyle];
        [_dateFormatter setTimeStyle:NSDateFormatterShortStyle];
        [_dateFormatter setDoesRelativeDateFormatting:YES];

    }

    return self;
}

#pragma mark - View lifecycle

- (void)loadView {
    QTRConnectedDevicesView *view = [[QTRConnectedDevicesView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    [view setAutoresizingMask:(UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth)];
    [self setView:view];
}

- (void)setView:(UIView *)view {

    if (![view isKindOfClass:[QTRConnectedDevicesView class]]) {
        [NSException raise:NSInternalInconsistencyException format:@"%@ must be associated only with %@", NSStringFromClass([self class]), NSStringFromClass([QTRConnectedDevicesView class])];
    }

    [super setView:view];

    _transfersView = (QTRConnectedDevicesView *)view;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.

    [[_transfersView devicesTableView] setDataSource:self];
    [[_transfersView devicesTableView] setDelegate:self];

    QTRTransfersTableCell *tableCell = [[QTRTransfersTableCell alloc] init];
    [[_transfersView devicesTableView] setRowHeight:[tableCell requiredHeightInTableView]];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    [self.navigationController.navigationBar setBarTintColor:[UIColor colorWithRed:0.95f green:0.91f blue:0.40f alpha:1.00f]];
}

#pragma mark - Public methods

- (QTRTransfersStore *)transfersStore {
    return _transfersStore;
}

#pragma mark - Cleanup

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc {

    [[_transfersView devicesTableView] setDataSource:nil];
    [[_transfersView devicesTableView] setDelegate:nil];
    [_transfersStore setDelegate:nil];
}


#pragma mark - UITableViewDataSource methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [[_transfersStore transfers] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *QTRTransfersTableCellIdentifier = @"QTRTransfersTableCellIdentifier";

    QTRTransfersTableCell *cell = [tableView dequeueReusableCellWithIdentifier:QTRTransfersTableCellIdentifier];

    if (cell == nil) {
        cell = [[QTRTransfersTableCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:QTRTransfersTableCellIdentifier];
        [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
        [[cell footerLabel] setTextColor:[UIColor colorWithRed:0.44f green:0.74f blue:0.64f alpha:1.00f]];
    }
    QTRTransfer *theTransfer = [[_transfersStore transfers] objectAtIndex:[indexPath row]];
    [[cell titleLabel] setText:[theTransfer.fileURL.absoluteString lastPathComponent]];
    [[cell subtitleLabel] setText:theTransfer.user.name];

    NSString *footerLabelText = [NSString stringWithFormat:@"%@, %@", [_dateFormatter stringFromDate:theTransfer.timestamp], [_byteCountFormatter stringFromByteCount:theTransfer.fileSize]];
    [[cell footerLabel] setText:footerLabelText];

    [cell.imageView setImage:[UIImage imageNamed:@"FileIconPlaceholder.png"]];

    return cell;
}

#pragma mark - UITableViewDelegate methods

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

}

#pragma mark - QTRTransfersStoreDelegate methods

- (void)transfersStore:(QTRTransfersStore *)transfersStore didAddTransfersAtIndices:(NSIndexSet *)addedIndices {

    NSMutableArray *indexPaths = [[NSMutableArray alloc] initWithCapacity:[addedIndices count]];
    [addedIndices enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        [indexPaths addObject:[NSIndexPath indexPathForRow:idx inSection:0]];
    }];

    [[_transfersView devicesTableView] insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (void)transfersStore:(QTRTransfersStore *)transfersStore didDeleteTransfersAtIndices:(NSIndexSet *)deletedIndices {
    NSMutableArray *indexPaths = [[NSMutableArray alloc] initWithCapacity:[deletedIndices count]];
    [deletedIndices enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        [indexPaths addObject:[NSIndexPath indexPathForRow:idx inSection:0]];
    }];

    [[_transfersView devicesTableView] deleteRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (void)transfersStore:(QTRTransfersStore *)transfersStore didUpdateTransfersAtIndices:(NSIndexSet *)updatedIndices {
    NSMutableArray *indexPaths = [[NSMutableArray alloc] initWithCapacity:[updatedIndices count]];
    [updatedIndices enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        [indexPaths addObject:[NSIndexPath indexPathForRow:idx inSection:0]];
    }];

    [[_transfersView devicesTableView] reloadRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
}



@end
