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

    NSArray *totalSelectedImages;
    QTRShowGalleryView *showGalleryView;
    NSMutableDictionary *selectedImages;
    NSInteger totalImageCount;


}

@end


static NSString *cellIdentifier = @"CellIdentifier";

@implementation QTRShowGalleryViewController

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    [selectedImages removeAllObjects];
    [showGalleryView.galleryCollectionView reloadData];

}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    selectedImages = [[NSMutableDictionary alloc]init];
    
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
    
    showGalleryView = [[QTRShowGalleryView alloc] init];
    [showGalleryView setTranslatesAutoresizingMaskIntoConstraints:NO];
    
    showGalleryView.galleryCollectionView.delegate = self;
    showGalleryView.galleryCollectionView.dataSource =self;
    [showGalleryView.galleryCollectionView registerClass:[QTRGalleryCollectionViewCell class] forCellWithReuseIdentifier:cellIdentifier];
    [showGalleryView.sendButton addTarget:self action:@selector(sendData) forControlEvents:UIControlEventTouchUpInside];

    [self.view addSubview:showGalleryView];
    
    
    NSDictionary *views = NSDictionaryOfVariableBindings(showGalleryView);
    
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[showGalleryView]-0-|" options:0 metrics:0 views:views]];
    
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[showGalleryView]-0-|" options:0 metrics:0 views:views]];
    
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
    if ([selectedImages count] > 0) {
                
        [self.delegate showGalleryViewController:self selectedImages:selectedImages];
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
        
        [showGalleryView.galleryCollectionViewLayout setMinimumLineSpacing:0.0f];
        return UIEdgeInsetsMake(0.0f, 0.0f, 0.0f, 0.0f);

    }
    else {
        CGFloat gap = (CGFloat)totalRemSpace / (CGFloat)(noOfItems + 1);
        [showGalleryView.galleryCollectionViewLayout setMinimumLineSpacing:gap];

    
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
    
    __weak QTRGalleryCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier forIndexPath:indexPath];
    
    CGSize fetchImageSize = CGSizeMake(cell.frame.size.width * 2, cell.frame.size.width * 2);
    
    [_fetchPhotoLibrary imageAtIndex:indexPath.row imageWithFullSize:NO imageSize:fetchImageSize completion:^(UIImage * image) {
        cell.backgroundView = [[UIImageView alloc] initWithImage:image ];
    }];
    
    return cell;
    
}


- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake(80.0f, 80.0f);
}


#pragma mark - UICollectionView Delegate methods

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    

    
}



- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath
{

    
}



@end
