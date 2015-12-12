//
//  QTRTransfersViewController.m
//  QuickTransfer
//
//  Created by Harshad on 04/04/14.
//  Copyright (c) 2014 Laughing Buddha Software. All rights reserved.
//

#import <QuickLook/QuickLook.h>

#import "QTRTransfersViewController.h"
#import "QTRConnectedDevicesView.h"
#import "QTRTransfersTableCell.h"
#import "QTRTransfer.h"
#import "QTRFile.h"
#import "QTRUser.h"
#import "QTRHelper.h"
#import "QTRTransfersStore.h"
#import "QTRRootViewController.h"


@interface QTRTransfersViewController () <UITableViewDataSource, UITableViewDelegate, QLPreviewControllerDataSource> {
    __weak QTRConnectedDevicesView *_transfersView;
    NSByteCountFormatter *_byteCountFormatter;
    NSDateFormatter *_dateFormatter;
    QTRTransfersStore *_transfersStore;
    QTRTransfer *_selectedTransfer;
    UITableView *logsTableView;
    
    
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

//- (void)loadView {
//    QTRConnectedDevicesView *view = [[QTRConnectedDevicesView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
//    [view setAutoresizingMask:(UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth)];
//    [self setView:view];
//}

//- (void)setView:(UIView *)view {
//    
//    if (![view isKindOfClass:[QTRConnectedDevicesView class]]) {
//        [NSException raise:NSInternalInconsistencyException format:@"%@ must be associated only with %@", NSStringFromClass([self class]), NSStringFromClass([QTRConnectedDevicesView class])];
//    }
//    
//    [super setView:view];
//    
//    _transfersView = (QTRConnectedDevicesView *)view;
//}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self setTitle:@"Transfers New"];
    
    logsTableView = [[UITableView alloc] initWithFrame:self.view.frame style:UITableViewStylePlain];
    logsTableView.delegate = self;
    logsTableView.dataSource = self;
    [logsTableView setBackgroundColor:[UIColor colorWithRed:76.f/255.f green:76.f/255.f blue:76.f/255.f alpha:1.00f]];
    [logsTableView setSeparatorColor:[UIColor colorWithRed:85.f/255.f green:85.f/255.f blue:85.f/255.f alpha:1.00f]];
    [logsTableView setShowsVerticalScrollIndicator:NO];
    
    
    
    [self.view addSubview:logsTableView];
//    
//    [[_transfersView devicesTableView] setDataSource:self];
//    [[_transfersView devicesTableView] setDelegate:self];
//    
//    QTRTransfersTableCell *tableCell = [[QTRTransfersTableCell alloc] init];
//    [[_transfersView devicesTableView] setRowHeight:[tableCell requiredHeightInTableView]];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
//    [self.navigationController.navigationBar setBarTintColor:[UIColor colorWithRed:0.95f green:0.91f blue:0.40f alpha:1.00f]];
//    NSIndexPath *selectedIndexPath = [[_transfersView devicesTableView] indexPathForSelectedRow];
//    if (selectedIndexPath != nil && selectedIndexPath.row < [[_transfersStore transfers] count]) {
//        [[_transfersView devicesTableView] deselectRowAtIndexPath:selectedIndexPath animated:YES];
//    }
}

#pragma mark - Public methods

- (QTRTransfersStore *)transfersStore {
    return _transfersStore;
}

#pragma mark - Cleanup

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc {
    
//    [[_transfersView devicesTableView] setDataSource:nil];
//    [[_transfersView devicesTableView] setDelegate:nil];
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
        
        [cell setSelectionStyle:UITableViewCellSelectionStyleDefault];
        
    }
    
    QTRTransfer *theTransfer = [[_transfersStore transfers] objectAtIndex:[indexPath row]];
    [[cell titleLabel] setText:[theTransfer.fileURL.absoluteString lastPathComponent]];
    [[cell subtitleLabel] setText:theTransfer.user.name];
    [cell.imageView setImage:[UIImage imageNamed:@"FileIconPlaceholder.png"]];
    
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        
        QTRTransfer *theTransfer = [[_transfersStore transfers] objectAtIndex:indexPath.row];
        
        [[NSFileManager defaultManager] removeItemAtPath:[theTransfer.fileURL path] error:nil];
        [_transfersStore deleteTransfer:theTransfer];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
}

#pragma mark - UITableViewDelegate methods

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    QTRTransfer *theTransfer = [[_transfersStore transfers] objectAtIndex:indexPath.row];
    if (theTransfer.state == QTRTransferStateCompleted) {
        _selectedTransfer = theTransfer;
        
        QLPreviewController *previewController = [[QLPreviewController alloc] init];
        [previewController setDataSource:self];
        
        [self.navigationController pushViewController:previewController animated:YES];
    } else {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
    
    
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewCellEditingStyleDelete;
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
    QTRTransfer *theTransfer = [[_transfersStore transfers] objectAtIndex:indexPath.row];
    if (theTransfer.state == QTRTransferStateCompleted) {
        if ([self.navigationController.parentViewController isKindOfClass:[QTRRootViewController class]]) {
            QTRRootViewController *rootController = (QTRRootViewController *)self.navigationController.parentViewController;
            [rootController importFileAtURL:theTransfer.fileURL];
        }
    }
}


#pragma mark - QTRTransfersStoreDelegate methods

- (void)transfersStore:(QTRTransfersStore *)transfersStore didAddTransfersAtIndices:(NSIndexSet *)addedIndices {
    
    NSMutableArray *indexPaths = [[NSMutableArray alloc] initWithCapacity:[addedIndices count]];
    [addedIndices enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        [indexPaths addObject:[NSIndexPath indexPathForRow:idx inSection:0]];
    }];
    
    [logsTableView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (void)transfersStore:(QTRTransfersStore *)transfersStore didDeleteTransfersAtIndices:(NSIndexSet *)deletedIndices {
    NSMutableArray *indexPaths = [[NSMutableArray alloc] initWithCapacity:[deletedIndices count]];
    [deletedIndices enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        [indexPaths addObject:[NSIndexPath indexPathForRow:idx inSection:0]];
    }];
    
    [logsTableView deleteRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (void)transfersStore:(QTRTransfersStore *)transfersStore didUpdateTransfersAtIndices:(NSIndexSet *)updatedIndices {
    NSMutableArray *indexPaths = [[NSMutableArray alloc] initWithCapacity:[updatedIndices count]];
    [updatedIndices enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        [indexPaths addObject:[NSIndexPath indexPathForRow:idx inSection:0]];
    }];
    
    [logsTableView reloadRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (void)transfersStore:(QTRTransfersStore *)transfersStore didUpdateProgressOfTransferAtIndex:(NSUInteger)transferIndex {
    //Update the progress of transfer
  }

#pragma mark - QLPreviewControllerDatasource methods

- (NSInteger)numberOfPreviewItemsInPreviewController:(QLPreviewController *)controller {
    return 1;
}

- (id<QLPreviewItem>)previewController:(QLPreviewController *)controller previewItemAtIndex:(NSInteger)index {
    return _selectedTransfer;
}


@end
