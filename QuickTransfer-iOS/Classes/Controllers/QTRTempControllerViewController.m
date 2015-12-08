////
////  QTRTempControllerViewController.m
////  QuickTransfer
////
////  Created by Tarun Yadav on 07/12/15.
////  Copyright © 2015 Laughing Buddha Software. All rights reserved.
////
//
//#import "QTRTempControllerViewController.h"
//#import "QTRTransfersTableCell.h"
//#import "QTRTransfer.h"
//#import "QTRFile.h"
//#import "QTRUser.h"
//#import "QTRHelper.h"
//#import "QTRTransfersStore.h"
//#import "QTRRootViewController.h"
////#import "QTRConnectedDevicesView.h"
//#import "QTRTempTransView.h"
//
//
//@interface QTRTempControllerViewController ()  <UITableViewDataSource, UITableViewDelegate, QLPreviewControllerDataSource, QTRTransfersStoreDelegate> {
//    
//    NSByteCountFormatter *_byteCountFormatter;
//    NSDateFormatter *_dateFormatter;
//    QTRTransfersStore *_transfersStore;
//    QTRTransfer *_selectedTransfer;
//    
//    __weak QTRTempTransView *_devicesView;
//}
//@end
//
//@implementation QTRTempControllerViewController
//
//- (id)init {
//    self = [super init];
//    if (self != nil) {
//        
//        NSURL *fileCacheDirectoryURL = [QTRHelper fileCacheDirectory];
//        NSString *transfersArchiveFilePath = [[fileCacheDirectoryURL path] stringByAppendingPathComponent:@"Transfers"];
//        _transfersStore = [[QTRTransfersStore alloc] initWithArchiveLocation:transfersArchiveFilePath];
//        [_transfersStore setDelegate:self];
//        
//        _byteCountFormatter = [[NSByteCountFormatter alloc] init];
//        _dateFormatter = [[NSDateFormatter alloc] init];
//        
//        [_dateFormatter setDateStyle:NSDateFormatterShortStyle];
//        [_dateFormatter setTimeStyle:NSDateFormatterShortStyle];
//        [_dateFormatter setDoesRelativeDateFormatting:YES];
//        
//    }
//    
//    return self;
//}
//
//#pragma mark - View lifecycle
//
//- (void)loadView {
//    QTRTempTransView *view = [[QTRTempTransView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
//    [view setAutoresizingMask:(UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth)];
//    [self setView:view];
//}
//
//- (void)setView:(UIView *)view {
//    
//    if (![view isKindOfClass:[QTRTempTransView class]]) {
//        [NSException raise:NSInternalInconsistencyException format:@"%@ must be associated only with %@", NSStringFromClass([self class]), NSStringFromClass([QTRTempTransView class])];
//    }
//    
//    [super setView:view];
//    
//    _devicesView = (QTRTempTransView *)view;
//}
//
//- (void)viewDidLoad {
//    [super viewDidLoad];
//    // Do any additional setup after loading the view.
//    
//    
//    
//    [[ _devicesView devicesTableView] setDataSource:self];
//    [[_devicesView devicesTableView] setDelegate:self];
//    
//    QTRTransfersTableCell *tableCell = [[QTRTransfersTableCell alloc] init];
//    [[_devicesView devicesTableView] setRowHeight:[tableCell requiredHeightInTableView]];
//}
//
//- (void)viewWillAppear:(BOOL)animated {
//    [super viewWillAppear:animated];
//    
//    
//    [self setTitle:@"Transfers"];
//    [self.navigationController.navigationBar setBarTintColor:[UIColor colorWithRed:85.f/255.f green:85.f/255.f blue:85.f/255.f alpha:1.00f]];
//    
//    UIBarButtonItem *leftBarButton = [[UIBarButtonItem alloc] initWithTitle:@"Home" style:UIBarButtonItemStylePlain target:self action:@selector(leftBarButtonAction)];
//    [self.navigationItem setLeftBarButtonItem:leftBarButton];
//    
//    UIBarButtonItem *rightBarButton = [[UIBarButtonItem alloc] initWithTitle:@"Clear All" style:UIBarButtonItemStylePlain target:self action:@selector(rightBarButtonAction)];
//    [self.navigationItem setRightBarButtonItem:rightBarButton];
//    
//
//}
//
//#pragma mark - Public methods
//
//- (QTRTransfersStore *)transfersStore {
//    return _transfersStore;
//}
//
//
//#pragma mark - Button Actions
//
//- (void)leftBarButtonAction {
//
//    NSLog(@"Its left");
//    [self.navigationController popToRootViewControllerAnimated:YES];
//
//}
//
//- (void)rightBarButtonAction {
//
//
//    NSLog(@"Its right");
//}
//
//#pragma mark - Cleanup
//
//- (void)didReceiveMemoryWarning {
//    [super didReceiveMemoryWarning];
//    // Dispose of any resources that can be recreated.
//}
//
//- (void)dealloc {
//    
//    [[_devicesView devicesTableView] setDataSource:nil];
//    [[_devicesView devicesTableView] setDelegate:nil];
//    [_transfersStore setDelegate:nil];
//}
//
//
//#pragma mark - UITableViewDataSource methods
//
//- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
//    return 1;
//}
//
//- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
//    return [[_transfersStore transfers] count];
//}
//
//- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
//    
//    static NSString *QTRTransfersTableCellIdentifier = @"QTRTransfersTableCellIdentifier";
//    
//    QTRTransfersTableCell *cell = [tableView dequeueReusableCellWithIdentifier:QTRTransfersTableCellIdentifier];
//    
//    if (cell == nil) {
//        cell = [[QTRTransfersTableCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:QTRTransfersTableCellIdentifier];
////        
////        [cell setSelectionStyle:UITableViewCellSelectionStyleDefault];
////        [cell setAccessoryType:UITableViewCellAccessoryDetailButton];
////        
////        [[cell progressView] setTrackTintColor:[UIColor colorWithWhite:0.92f alpha:1.0f]];
////        [[cell progressView] setProgressTintColor:[UIColor colorWithRed:0.36f green:0.81f blue:1.00f alpha:1.00f]];
////        
//    }
//    QTRTransfer *theTransfer = [[_transfersStore transfers] objectAtIndex:[indexPath row]];
//    [[cell titleLabel] setText:[theTransfer.fileURL.absoluteString lastPathComponent]];
//    [[cell subtitleLabel] setText:theTransfer.user.name];
//    
////    NSString *footerLabelText = [NSString stringWithFormat:@"%@, %@", [_dateFormatter stringFromDate:theTransfer.timestamp], [_byteCountFormatter stringFromByteCount:theTransfer.fileSize]];
////    [[cell footerLabel] setText:footerLabelText];
//    
//    
//    UIColor *footerLabelColor = nil;
//    
//    switch (theTransfer.state) {
//        case QTRTransferStateCompleted:
//            footerLabelColor = [UIColor colorWithRed:0.44f green:0.74f blue:0.64f alpha:1.00f];
//            [[cell progressView] setHidden:YES];
//            
//            break;
//            
//        case QTRTransferStateInProgress:
//            footerLabelColor = [UIColor colorWithRed:0.41f green:0.77f blue:0.94f alpha:1.00f];
//            [[cell progressView] setProgress:theTransfer.progress];
//            
//            break;
//            
//        case QTRTransferStateFailed:
//            footerLabelColor = [UIColor colorWithRed:0.96f green:0.58f blue:0.56f alpha:1.00f];;
//            [[cell progressView] setHidden:YES];
//            
//            break;
//            
//        default:
//            break;
//    }
//    
//   // [[cell footerLabel] setTextColor:footerLabelColor];
//    
//    [cell.imageView setImage:[UIImage imageNamed:@"FileIconPlaceholder.png"]];
//    
//    return cell;
//}
//
//- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
//    return YES;
//}
//
//- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
//    if (editingStyle == UITableViewCellEditingStyleDelete) {
//        
//        QTRTransfer *theTransfer = [[_transfersStore transfers] objectAtIndex:indexPath.row];
//        
//        [[NSFileManager defaultManager] removeItemAtPath:[theTransfer.fileURL path] error:nil];
//        
//        [_transfersStore deleteTransfer:theTransfer];
//        
//        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
//    }
//}
//
//#pragma mark - UITableViewDelegate methods
//
//- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
//    
//    QTRTransfer *theTransfer = [[_transfersStore transfers] objectAtIndex:indexPath.row];
//    if (theTransfer.state == QTRTransferStateCompleted) {
//        _selectedTransfer = theTransfer;
//        
//        QLPreviewController *previewController = [[QLPreviewController alloc] init];
//        [previewController setDataSource:self];
//        
//        [self.navigationController pushViewController:previewController animated:YES];
//    } else {
//        [tableView deselectRowAtIndexPath:indexPath animated:YES];
//    }
//    
//    
//}
//
//- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
//    return UITableViewCellEditingStyleDelete;
//}
//
//- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
//    QTRTransfer *theTransfer = [[_transfersStore transfers] objectAtIndex:indexPath.row];
//    if (theTransfer.state == QTRTransferStateCompleted) {
//        if ([self.navigationController.parentViewController isKindOfClass:[QTRRootViewController class]]) {
//            QTRRootViewController *rootController = (QTRRootViewController *)self.navigationController.parentViewController;
//            [rootController importFileAtURL:theTransfer.fileURL];
//        }
//    }
//}
//
//
//#pragma mark - QTRTransfersStoreDelegate methods
//
//- (void)transfersStore:(QTRTransfersStore *)transfersStore didAddTransfersAtIndices:(NSIndexSet *)addedIndices {
//    
//    NSMutableArray *indexPaths = [[NSMutableArray alloc] initWithCapacity:[addedIndices count]];
//    [addedIndices enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
//        [indexPaths addObject:[NSIndexPath indexPathForRow:idx inSection:0]];
//    }];
//    
//    [[_devicesView devicesTableView] insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
//}
//
//- (void)transfersStore:(QTRTransfersStore *)transfersStore didDeleteTransfersAtIndices:(NSIndexSet *)deletedIndices {
//    NSMutableArray *indexPaths = [[NSMutableArray alloc] initWithCapacity:[deletedIndices count]];
//    [deletedIndices enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
//        [indexPaths addObject:[NSIndexPath indexPathForRow:idx inSection:0]];
//    }];
//    
//    [[_devicesView devicesTableView] deleteRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
//}
//
//- (void)transfersStore:(QTRTransfersStore *)transfersStore didUpdateTransfersAtIndices:(NSIndexSet *)updatedIndices {
//    NSMutableArray *indexPaths = [[NSMutableArray alloc] initWithCapacity:[updatedIndices count]];
//    [updatedIndices enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
//        [indexPaths addObject:[NSIndexPath indexPathForRow:idx inSection:0]];
//    }];
//    
//    [[_devicesView devicesTableView] reloadRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
//}
//
//- (void)transfersStore:(QTRTransfersStore *)transfersStore didUpdateProgressOfTransferAtIndex:(NSUInteger)transferIndex {
//    QTRTransfer *theTransfer = [[_transfersStore transfers] objectAtIndex:transferIndex];
//    
//    QTRTransfersTableCell *tableCell = (QTRTransfersTableCell *)[[_devicesView devicesTableView] cellForRowAtIndexPath:[NSIndexPath indexPathForRow:transferIndex inSection:0]];
//    [[tableCell progressView] setProgress:theTransfer.progress animated:YES];
//    
//}
//
//#pragma mark - QLPreviewControllerDatasource methods
//
//- (NSInteger)numberOfPreviewItemsInPreviewController:(QLPreviewController *)controller {
//    return 1;
//}
//
//- (id<QLPreviewItem>)previewController:(QLPreviewController *)controller previewItemAtIndex:(NSInteger)index {
//    return _selectedTransfer;
//}
//
//
//@end
//
