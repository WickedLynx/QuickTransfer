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

@interface QTRShowGalleryViewController () <UICollectionViewDataSource,UICollectionViewDelegate,UICollectionViewDelegateFlowLayout> {

    UICollectionView *galleryCollectionView;

}

@end

static NSString *cellIdentifier = @"cellIdentifier";
static int count = 0;
int totalImages;


@implementation QTRShowGalleryViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.view setBackgroundColor:[UIColor colorWithRed:76.f/255.f green:76.f/255.f blue:76.f/255.f alpha:1.00f]];
    [self setTitle:@"Camera Roll"];
    
    [self.navigationController.navigationBar setBarTintColor:[UIColor colorWithRed:85.f/255.f green:85.f/255.f blue:85.f/255.f alpha:1.00f]];
    
    
    UIBarButtonItem *leftBarButton = [[UIBarButtonItem alloc] initWithTitle:@"< Back" style:UIBarButtonItemStylePlain target:self action:@selector(homeButton)];
    
    [leftBarButton setTintColor:[UIColor colorWithRed:32.f/255.f green:149.f/255.f blue:242.f/255.f alpha:1.00f]];
    [self.navigationItem setLeftBarButtonItem:leftBarButton];
    
    QTRRightBarButtonView *customRightBarButton = [[QTRRightBarButtonView alloc]initWithFrame:CGRectZero];
    [customRightBarButton setUserInteractionEnabled:NO];
    
    UIButton *barButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [barButton addTarget:self action:@selector(logsBarButton) forControlEvents:UIControlEventTouchUpInside];
    barButton.frame = customRightBarButton.frame;
    [customRightBarButton addSubview:barButton];
    
    UIBarButtonItem *rightBarButton = [[UIBarButtonItem alloc] initWithCustomView:customRightBarButton];
    [self.navigationItem setRightBarButtonItem:rightBarButton];
    
    [self getAllPictures];
    
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    [layout setMinimumInteritemSpacing:2.0f];
    [layout setMinimumLineSpacing:2.0f];
    layout.scrollDirection = UICollectionViewScrollDirectionVertical;
    
    galleryCollectionView = [[UICollectionView alloc]initWithFrame:CGRectZero collectionViewLayout:layout];
    galleryCollectionView.delegate = self;
    galleryCollectionView.dataSource = self;
    galleryCollectionView.allowsMultipleSelection = YES;
    [galleryCollectionView setBackgroundColor:[UIColor colorWithRed:76.f/255.f green:76.f/255.f blue:76.f/255.f alpha:1.00f]];
    [galleryCollectionView setTranslatesAutoresizingMaskIntoConstraints:NO];
    
    [self.view addSubview:galleryCollectionView];
    
    [galleryCollectionView registerClass:[QTRGalleryCollectionViewCell class] forCellWithReuseIdentifier:@"cellIdentifier"];
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.frame = CGRectZero;
    [[button layer]setCornerRadius:7.0f];
    [[button layer]setBorderWidth:1.0f];
    [[button layer]setBorderColor:[UIColor whiteColor].CGColor];
    [[button layer]setMasksToBounds:TRUE];
    button.clipsToBounds = YES;
    [button setTitle:@"Send" forState:UIControlStateNormal];
    [button setBackgroundColor:[UIColor colorWithRed:76.f/255.f green:76.f/255.f blue:76.f/255.f alpha:1.00f]];
    [button setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.view addSubview:button];
    _sendButton = button;


    NSDictionary *views = NSDictionaryOfVariableBindings(galleryCollectionView, button);
    
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-2-[galleryCollectionView]-2-|" options:0 metrics:0 views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-7-[button]-7-|" options:0 metrics:0 views:views]];

    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-2-[galleryCollectionView]-5-[button]-5-|" options:0 metrics:0 views:views]];

    
}

-(void)homeButton {
    
    [self.navigationController popToRootViewControllerAnimated:YES];

}


-(void)logsBarButton {
    
    NSLog(@"Log Button Clicked..");


}

#pragma mark - UICollectionViewDataSource methods

-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
    
}

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    
    return [imageArray count];
    
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    QTRGalleryCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier forIndexPath:indexPath];
    
    cell.backgroundColor = [UIColor greenColor];
    cell.backgroundView = [[UIImageView alloc] initWithImage:[ (UIImage *) [imageArray objectAtIndex:indexPath.row] stretchableImageWithLeftCapWidth:0.0 topCapHeight:5.0] ];
 
    return cell;
    
}


- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return CGSizeMake(77.5f, 77.5f);
}


#pragma mark - UICollectionViewDelegate methods


- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath
{
//    QTRHomeCollectionViewCell *cell = (QTRHomeCollectionViewCell *)[[_devicesView devicesCollectionView] cellForItemAtIndexPath:indexPath];
//    cell.connectedDeviceName.textColor = [UIColor whiteColor];
    
    NSLog(@"Cell deselected..");
    
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    //QTRHomeCollectionViewCell *cell = (QTRHomeCollectionViewCell *)[[_devicesView devicesCollectionView] cellForItemAtIndexPath:indexPath];
    //cell.connectedDeviceName.textColor = [UIColor colorWithRed:32.f/255.f green:149.f/255.f blue:242.f/255.f alpha:1.00f];
 
    NSLog(@"Cell Selected..");

}




-(void)getAllPictures
{
    imageArray=[[NSArray alloc] init];
    mutableArray =[[NSMutableArray alloc]init];
    NSMutableArray* assetURLDictionaries = [[NSMutableArray alloc] init];
    
    library = [[ALAssetsLibrary alloc] init];
    
    void (^assetEnumerator)( ALAsset *, NSUInteger, BOOL *) = ^(ALAsset *result, NSUInteger index, BOOL *stop) {
        
        if(result != nil) {
            if([[result valueForProperty:ALAssetPropertyType] isEqualToString:ALAssetTypePhoto]) {
                [assetURLDictionaries addObject:[result valueForProperty:ALAssetPropertyURLs]];
                
                NSURL *url= (NSURL*) [[result defaultRepresentation]url];
                
                NSLog(@"URL:%@", url);
                
                [library assetForURL:url
                         resultBlock:^(ALAsset *asset) {
                             
                             if (asset){
                                 //////////////////////////////////////////////////////
                                 // SUCCESS POINT #1 - asset is what we are looking for
                                 //////////////////////////////////////////////////////
                                 [mutableArray addObject:[UIImage imageWithCGImage:[[asset defaultRepresentation] fullResolutionImage]]];
                       
                             }
                             
                             else {
                             
                                 [library enumerateGroupsWithTypes:ALAssetsGroupPhotoStream
                                                        usingBlock:^(ALAssetsGroup *group, BOOL *stop)
                                  {
                                      [group enumerateAssetsWithOptions:NSEnumerationReverse usingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop) {
                                          if([result.defaultRepresentation.url isEqual:url])
                                          {
                                              ///////////////////////////////////////////////////////
                                              // SUCCESS POINT #2 - result is what we are looking for
                                              ///////////////////////////////////////////////////////
                                              
                                              [mutableArray addObject:[UIImage imageWithCGImage:[[asset defaultRepresentation] fullResolutionImage]]];

                                              
                                              *stop = YES;
                                          }
                                      }];
                             
                                  }
                                  
                                                      failureBlock:^(NSError *error)
                                  {
                                      NSLog(@"Error: Cannot load asset from photo stream - %@", [error localizedDescription]);
                                      
                                  }];
                                      
                                      
                             }
                             
                             
                             
                             //[mutableArray addObject:[UIImage imageWithCGImage:[[asset defaultRepresentation] fullResolutionImage]]];
                             
                             if ([mutableArray count]==count)
                             {
                                 imageArray=[[NSArray alloc] initWithArray:mutableArray];
                                 [self allPhotosCollected:imageArray];
                             }
                             
                             

                             
                             
                         }
                        failureBlock:^(NSError *error){ NSLog(@"operation was not successfull!"); } ];
                
            }
        }
    };
    
    NSMutableArray *assetGroups = [[NSMutableArray alloc] init];
    
    void (^ assetGroupEnumerator) ( ALAssetsGroup *, BOOL *)= ^(ALAssetsGroup *group, BOOL *stop) {
        if(group != nil) {
            [group enumerateAssetsUsingBlock:assetEnumerator];
            [assetGroups addObject:group];
            count=(int)[group numberOfAssets];
        }
    };
    
    assetGroups = [[NSMutableArray alloc] init];
    
    [library enumerateGroupsWithTypes:ALAssetsGroupAll
                           usingBlock:assetGroupEnumerator
                         failureBlock:^(NSError *error) {NSLog(@"There is an error");}];
}

-(void)allPhotosCollected:(NSArray*)imgArray
{
    //write your code here after getting all the photos from library...
    NSLog(@"all pictures are %@",imgArray);
    totalImages = (int)[imageArray count];
    [galleryCollectionView reloadData];
}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
