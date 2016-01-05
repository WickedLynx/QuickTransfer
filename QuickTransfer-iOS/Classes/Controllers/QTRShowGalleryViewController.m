//
//  QTRShowGalleryViewController.m
//  QuickTransfer
//
//  Created by Tarun Yadav on 26/11/15.
//  Copyright © 2015 Laughing Buddha Software. All rights reserved.
//

#import "QTRShowGalleryViewController.h"
#import "QTRGalleryCollectionViewCell.h"
#import "QTRRightBarButtonView.h"
#import "QTRTransfersViewController.h"
#import "QTRShowGalleryView.h"
#import "QTRPhotoLibraryController.h"



@interface QTRShowGalleryViewController () <UICollectionViewDataSource, UICollectionViewDelegate> {

    QTRShowGalleryView *_showGalleryView;
    NSMutableDictionary*_selectedImages;
    NSInteger _totalImageCount;
}

@end


static NSString *cellIdentifier = @"CellIdentifier";

@implementation QTRShowGalleryViewController

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    [_selectedImages removeAllObjects];
    [_showGalleryView.galleryCollectionView reloadData];

}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _selectedImages = [[NSMutableDictionary alloc]init];
    
    [self.view setBackgroundColor:[UIColor colorWithRed:76.f/255.f green:76.f/255.f blue:76.f/255.f alpha:1.00f]];
    [self setTitle:@"Camera Roll"];
    
    [self.navigationController.navigationBar setBarTintColor:[UIColor colorWithRed:85.f/255.f green:85.f/255.f blue:85.f/255.f alpha:1.00f]];
    
    UIButton *leftCustomButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [leftCustomButton setImage:[UIImage imageNamed:@"back_arrow"] forState:UIControlStateNormal];
    [leftCustomButton setTitle:@" Back" forState:UIControlStateNormal];
    [leftCustomButton setTitleColor:[UIColor colorWithRed:32.f/255.f green:149.f/255.f blue:242.f/255.f alpha:1.00f] forState:UIControlStateNormal];
    leftCustomButton.frame = CGRectMake(0.f, 0.f, 60.0f, 30.0f);
    [leftCustomButton addTarget:self action:@selector(backButtonAction) forControlEvents:UIControlEventTouchUpInside];

    UIBarButtonItem *leftBarButton = [[UIBarButtonItem alloc] init];
    [leftBarButton setCustomView:leftCustomButton];
    self.navigationItem.leftBarButtonItem=leftBarButton;
    
    QTRRightBarButtonView *customRightBarButton = [[QTRRightBarButtonView alloc]initWithFrame:CGRectZero];
    [customRightBarButton setUserInteractionEnabled:NO];
    
    UIButton *barButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [barButton addTarget:self action:@selector(rightBarButtonAction) forControlEvents:UIControlEventTouchUpInside];
    barButton.frame = customRightBarButton.frame;
    [customRightBarButton addSubview:barButton];
    
    UIBarButtonItem *rightBarButton = [[UIBarButtonItem alloc] initWithCustomView:customRightBarButton];
    [self.navigationItem setRightBarButtonItem:rightBarButton];
    
    _showGalleryView = [[QTRShowGalleryView alloc] init];
    [_showGalleryView setTranslatesAutoresizingMaskIntoConstraints:NO];
    
    _showGalleryView.galleryCollectionView.delegate = self;
    _showGalleryView.galleryCollectionView.dataSource =self;
    [_showGalleryView.galleryCollectionView registerClass:[QTRGalleryCollectionViewCell class] forCellWithReuseIdentifier:cellIdentifier];
    [_showGalleryView.sendButton addTarget:self action:@selector(sendData) forControlEvents:UIControlEventTouchUpInside];

    [self.view addSubview:_showGalleryView];
    
    NSDictionary *views = NSDictionaryOfVariableBindings(_showGalleryView);
    
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[_showGalleryView]-0-|" options:0 metrics:0 views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[_showGalleryView]-0-|" options:0 metrics:0 views:views]];
    
}

#pragma mark - Button Action methods

-(void)homeButton {
    
    [self.navigationController popToRootViewControllerAnimated:YES];
}

-(void)rightBarButtonAction {
    
    QTRTransfersViewController *filestransferViewController = [[QTRTransfersViewController alloc]init];
    [self.navigationController pushViewController:filestransferViewController animated:YES];
    
}


-(void)sendData {
    if ([_selectedImages count] > 0) {
        
        [self.delegate showGalleryViewController:self selectedImages:_selectedImages];
        [self.navigationController popViewControllerAnimated:YES];

        
    } else {
        
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Message" message:@"First Select Atleast One Image" preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
        [alertController addAction:ok];
        
        [self presentViewController:alertController animated:YES completion:nil];
    }

}

-(void)backButtonAction {

    [self.navigationController popToRootViewControllerAnimated:YES];

}

#pragma mark - UICollectionViewDataSource methods

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    
    int noOfItems = (self.view.frame.size.width) / 80;
    float totalRemSpace = self.view.frame.size.width - (noOfItems * 80);
    
    if (totalRemSpace == 0.0) {
        
        [_showGalleryView.galleryCollectionViewLayout setMinimumLineSpacing:0.0f];
        return UIEdgeInsetsMake(0.0f, 0.0f, 0.0f, 0.0f);

    }
    else {
        CGFloat gap = (CGFloat)totalRemSpace / (CGFloat)(noOfItems + 1);
        [_showGalleryView.galleryCollectionViewLayout setMinimumLineSpacing:gap];

    
    return UIEdgeInsetsMake( (gap * 2.0f), gap, (gap * 2.0f), gap);

    }
}
-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
    
}

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    
    return [_fetchPhotoLibrary fetchImageCount];
    
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    
    QTRGalleryCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier forIndexPath:indexPath];
    
    __weak UICollectionView *weakCollectionView = collectionView;
    __weak QTRGalleryCollectionViewCell *weakCell = cell;
 
    CGSize fetchImageSize = CGSizeMake(180.0, 180.0);
    
    [_fetchPhotoLibrary imageAtIndex:indexPath.item imageWithFullSize:NO imageSize:fetchImageSize completion:^(UIImage * image) {
    
        NSIndexPath *indexPathFromCell = [weakCollectionView indexPathForCell:weakCell];
        NSIndexPath *currentIndexPath = [NSIndexPath indexPathForItem:indexPath.item inSection:0];
        
        if (indexPathFromCell.item == currentIndexPath.item) {
            [weakCell setImage:image fetchItem:indexPath.item];

        }
    
    }];
    
    return cell;
}


- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake(80.0f, 80.0f);
}


- (void)collectionView:(UICollectionView *)collectionView didEndDisplayingCell:(nonnull UICollectionViewCell *)cell forItemAtIndexPath:(nonnull NSIndexPath *)indexPath {
    
    QTRGalleryCollectionViewCell *disapperedCell = (QTRGalleryCollectionViewCell *) cell;
    [disapperedCell resetImage:indexPath.item];
}


#pragma mark - UICollectionView Delegate methods

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    
    [_selectedImages setObject:[NSNumber numberWithInteger:indexPath.item] forKey:[NSNumber numberWithInteger:indexPath.item]];
    
}



- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath
{
   
    [_selectedImages removeObjectForKey:[NSNumber numberWithInteger:indexPath.item]];
    
}



@end
