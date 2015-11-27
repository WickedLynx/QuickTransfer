//
//  QTRActionSheetGalleryView.m
//  QuickTransfer
//
//  Created by Tarun Yadav on 27/11/15.
//  Copyright © 2015 Laughing Buddha Software. All rights reserved.
//

#import "QTRActionSheetGalleryView.h"
#import "QTRAlertControllerCollectionViewCell.h"

static NSString *cellIdentifier = @"cellIdentifier";
static int count = 0;

@implementation QTRActionSheetGalleryView

- (id)initWithFrame:(CGRect)aRect
{
    if ((self = [super initWithFrame:aRect])) {
        
        self.frame = CGRectMake(0.f, 37.f, 300.f, 65.f);
        self.backgroundColor = [UIColor purpleColor];
        
        UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
        [layout setMinimumInteritemSpacing:NO];
        [layout setMinimumLineSpacing:1.0f];
        layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        
        aCollectionView = [[UICollectionView alloc]initWithFrame:CGRectZero collectionViewLayout:layout];
        [aCollectionView setTranslatesAutoresizingMaskIntoConstraints:NO];
        [aCollectionView setShowsHorizontalScrollIndicator:NO];
        aCollectionView.frame = self.frame;
        
        [self addSubview:aCollectionView];
        _actionControllerCollectionView = aCollectionView;
        
        NSDictionary *views = NSDictionaryOfVariableBindings(aCollectionView);
        
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[aCollectionView]|" options:0 metrics:0 views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[aCollectionView]-0-|" options:0 metrics:0 views:views]];

        
        
        [self getAllPictures];
        
        
    }
    return self;
}


#pragma mark - UICollectionViewDataSource methods

-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
    
}

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    
    //    return [_connectedServers count] + [_connectedClients count];
    return [imageArray count];
    
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    QTRAlertControllerCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier forIndexPath:indexPath];
    
    //QTRUser *theUser = [self userAtIndexPath:indexPath isServer:NULL];
    
    //    [cell.connectedDeviceName setText:[theUser name]];
    
    
    cell.backgroundView = [[UIImageView alloc] initWithImage:[ (UIImage *) [imageArray objectAtIndex:indexPath.row] stretchableImageWithLeftCapWidth:0.0 topCapHeight:5.0] ];
    
    
    
    
    
    return cell;
    
}

//- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
//    static NSString *ConnectedDevicesTableCellIdentifier = @"ConnectedDevicesTableCellIdentifier";
//
//    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:ConnectedDevicesTableCellIdentifier];
//
//    if (cell == nil) {
//        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:ConnectedDevicesTableCellIdentifier];
//    }
//
//    QTRUser *theUser = [self userAtIndexPath:indexPath isServer:NULL];
//
//    [cell.textLabel setText:[theUser name]];
//
//
//
//
//    return cell;
//}


- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return CGSizeMake(65.0f, 65.0f);
}


#pragma mark - UICollectionViewDelegate methods


//- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath
//{
//    QTRAlertControllerCollectionViewCell *cell = (QTRAlertControllerCollectionViewCell *)[[_devicesView devicesCollectionView] cellForItemAtIndexPath:indexPath];
//    cell.connectedDeviceName.textColor = [UIColor whiteColor];
//
//}
//
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"Cell %lu Selected",indexPath.row);
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
                
                [library assetForURL:url
                         resultBlock:^(ALAsset *asset) {
                             [mutableArray addObject:[UIImage imageWithCGImage:[[asset defaultRepresentation] fullScreenImage]]];
                             
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
    [aCollectionView reloadData];
   
}


@end
