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
#import "DTBonjourDataChunk.h"
#import "QTRTransfer.h"
#import "QTRFile.h"
#import "QTRUser.h"
#import "QTRHelper.h"

float const QTRTransfersControllerProgressThresholdIOS = 0.02f;

@interface QTRTransfersViewController () <UITableViewDataSource, UITableViewDelegate> {
    __weak QTRConnectedDevicesView *_transfersView;
    NSMutableArray *_transfers;
    NSString *_archivedTransfersFilePath;
    NSByteCountFormatter *_byteCountFormatter;
    NSDateFormatter *_dateFormatter;
    NSMapTable *_dataChunksToTransfers;
    NSMutableDictionary *_fileIdentifierToTransfers;
}

@end

@implementation QTRTransfersViewController

#pragma mark - Initialisation

- (id)init {
    self = [super init];
    if (self != nil) {

        _dataChunksToTransfers = [NSMapTable strongToStrongObjectsMapTable];

        _fileIdentifierToTransfers = [NSMutableDictionary new];

        _byteCountFormatter = [[NSByteCountFormatter alloc] init];
        _dateFormatter = [[NSDateFormatter alloc] init];

        [_dateFormatter setDateStyle:NSDateFormatterShortStyle];
        [_dateFormatter setTimeStyle:NSDateFormatterShortStyle];
        [_dateFormatter setDoesRelativeDateFormatting:YES];

        NSURL *appSupportDirectoryURL = [QTRHelper fileCacheDirectory];
        _archivedTransfersFilePath = [[appSupportDirectoryURL path] stringByAppendingPathComponent:@"Transfers"];

        NSArray *array = [NSKeyedUnarchiver unarchiveObjectWithFile:_archivedTransfersFilePath];
        if (array != nil) {
            _transfers = [array mutableCopy];
        } else {
            _transfers = [NSMutableArray new];
        }

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

#pragma mark - Cleanup

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc {

    [[_transfersView devicesTableView] setDataSource:nil];
    [[_transfersView devicesTableView] setDelegate:nil];
}


#pragma mark - UITableViewDataSource methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_transfers count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *QTRTransfersTableCellIdentifier = @"QTRTransfersTableCellIdentifier";

    QTRTransfersTableCell *cell = [tableView dequeueReusableCellWithIdentifier:QTRTransfersTableCellIdentifier];

    if (cell == nil) {
        cell = [[QTRTransfersTableCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:QTRTransfersTableCellIdentifier];
        [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
        [[cell footerLabel] setTextColor:[UIColor colorWithRed:0.44f green:0.74f blue:0.64f alpha:1.00f]];
    }
    QTRTransfer *theTransfer = _transfers[[indexPath row]];
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

#pragma mark - QTRBonjourTransferDelegate methods

- (void)addTransferForUser:(QTRUser *)user file:(QTRFile *)file chunk:(DTBonjourDataChunk *)chunk {
    if (file != nil) {
        QTRTransfer *transfer = [QTRTransfer new];
        [transfer setUser:user];
        [transfer setFileURL:file.url];
        [transfer setTimestamp:[NSDate date]];
        [transfer setTotalParts:file.totalParts];
        [transfer setState:QTRTransferStateInProgress];
        if (file.totalParts > 1) {
            [transfer setFileSize:file.totalSize];
        } else {
            [transfer setFileSize:[file length]];
        }
        [_transfers insertObject:transfer atIndex:0];
        [_dataChunksToTransfers setObject:transfer forKey:chunk];

        [[_transfersView devicesTableView] reloadData];
    }

}

- (void)updateTransferForChunk:(DTBonjourDataChunk *)chunk {

    QTRTransfer *theTransfer = [_dataChunksToTransfers objectForKey:chunk];
    if (theTransfer != nil) {

        BOOL shouldReload = NO;

        float progress = (double)(chunk.numberOfTransferredBytes) / (double)(chunk.totalBytes);

        if (theTransfer.totalParts == 1) {

            if (progress - theTransfer.progress > QTRTransfersControllerProgressThresholdIOS) {
                [theTransfer setProgress:progress];
                shouldReload = YES;
            }

            if ([chunk isTransmissionComplete]) {
                [_dataChunksToTransfers removeObjectForKey:chunk];
                [theTransfer setState:QTRTransferStateCompleted];
                [theTransfer setProgress:1.0f];
                shouldReload = YES;
            }

        } else {

            if (progress == 1.0f || (progress - theTransfer.currentChunkProgress > QTRTransfersControllerProgressThresholdIOS * 2)) {
                [theTransfer setCurrentChunkProgress:progress];
                shouldReload = YES;
            }

            if (theTransfer.progress == 1.0f) {
                [theTransfer setState:QTRTransferStateCompleted];
                [theTransfer setCurrentChunkProgress:1.0f];
                [_dataChunksToTransfers removeObjectForKey:chunk];
                shouldReload = YES;
            }

        }

        if (shouldReload) {

            NSInteger row = [_transfers indexOfObject:theTransfer];
            [[_transfersView devicesTableView] reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:row inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
        }
    }
}

- (void)replaceChunk:(DTBonjourDataChunk *)oldChunk withChunk:(DTBonjourDataChunk *)newChunk {
    QTRTransfer *transfer = [_dataChunksToTransfers objectForKey:oldChunk];
    if (transfer != nil) {
        [_dataChunksToTransfers removeObjectForKey:oldChunk];
        [transfer setCurrentChunkProgress:0.0f];
        ++transfer.transferedChunks;
        [_dataChunksToTransfers setObject:transfer forKey:newChunk];
    }
}

- (void)failAllTransfersForUser:(QTRUser *)user {

    for (QTRTransfer *aTransfer in _transfers) {
        if (aTransfer.progress < 1.0f && [aTransfer.user isEqual:user]) {
            [aTransfer setState:QTRTransferStateFailed];
        }
    }

    [self archiveTransfers];

    [[_transfersView devicesTableView] reloadData];
}

- (void)addTransferFromUser:(QTRUser *)user file:(QTRFile *)file {

    QTRTransfer *transfer = [QTRTransfer new];
    [transfer setUser:user];
    [transfer setTimestamp:[NSDate date]];
    [transfer setTotalParts:file.totalParts];
    [transfer setState:QTRTransferStateInProgress];
    [transfer setTransferedChunks:(file.partIndex + 1)];
    [transfer setFileSize:file.totalSize];
    [transfer setFileURL:file.url];
    [_transfers insertObject:transfer atIndex:0];
    _fileIdentifierToTransfers[file.identifier] = transfer;

    if (file.totalParts == (file.partIndex + 1)) {
        [transfer setProgress:1.0f];
        [transfer setState:QTRTransferStateCompleted];
    }

    [[_transfersView devicesTableView] reloadData];
}

- (void)updateTransferForFile:(QTRFile *)file {
    QTRTransfer *theTransfer = _fileIdentifierToTransfers[file.identifier];
    if (theTransfer != nil && ![theTransfer isKindOfClass:[NSNull class]]) {
        [theTransfer setTransferedChunks:(file.partIndex + 1)];
        if (theTransfer.progress == 1) {
            [theTransfer setState:QTRTransferStateCompleted];
        }

        NSInteger cellIndex = [_transfers indexOfObject:theTransfer];
        [[_transfersView devicesTableView] reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:cellIndex inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
    
    
}

- (void)archiveTransfers {
    [NSKeyedArchiver archiveRootObject:_transfers toFile:_archivedTransfersFilePath];
}



@end
