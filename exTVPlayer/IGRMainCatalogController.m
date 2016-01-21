//
//  ViewController.m
//  exTVPlayer
//
//  Created by Vitalii Parovishnyk on 12/17/15.
//  Copyright © 2015 IGR Software. All rights reserved.
//

#import "IGRMainCatalogController.h"
#import "IGRCChanelViewController.h"

#import "IGREXParser.h"
#import "IGREntityExChanel.h"

#import "IGRChanelCell.h"

@interface IGRMainCatalogController () <NSFetchedResultsControllerDelegate>

@property (weak, nonatomic) IBOutlet UICollectionView *chanels;

@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (strong, nonatomic) NSMutableArray *sectionChanges;
@property (strong, nonatomic) NSMutableArray *itemChanges;

@property (strong, nonatomic) NSIndexPath *lastSelectedItem;
@property (strong, nonatomic) NSNumber *lastVideoCatalog;

@end

@implementation IGRMainCatalogController

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	self.chanels.backgroundColor = [UIColor clearColor];
	self.lastSelectedItem = nil;
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	
	IGREntityAppSettings *settings = [self appSettings];
	NSNumber *langId = settings.videoLanguageId;
	
	if (![self.lastVideoCatalog isEqualToNumber:langId])
	{
		self.lastVideoCatalog = langId;
		
		[IGREXParser parseVideoCatalogContent:langId.stringValue];
		
		_fetchedResultsController = nil;
		self.lastSelectedItem = nil;
		
		[self.chanels reloadData];
	}
	else if (self.lastSelectedItem)
	{
		[[self.chanels cellForItemAtIndexPath:self.lastSelectedItem] setHighlighted:YES];
	}
}

- (void)viewWillDisappear:(BOOL)animated
{
	[self.chanels.visibleCells enumerateObjectsUsingBlock:^(__kindof UICollectionViewCell * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		
		[obj setSelected:NO];
	}];
	
	[super viewWillDisappear:animated];
}

- (UIView *)preferredFocusedView
{
	return self.chanels;
}

- (void)didReceiveMemoryWarning
{
	[super didReceiveMemoryWarning];
	// Dispose of any resources that can be recreated.
}

#pragma mark - Public

#pragma mark - Privat

- (void)didUpdateFocusInContext:(UIFocusUpdateContext *)context withAnimationCoordinator:(UIFocusAnimationCoordinator *)coordinator
{
	if ([context.nextFocusedView isKindOfClass:NSClassFromString(@"UITabBarButton")])
	{
		[self.chanels.visibleCells enumerateObjectsUsingBlock:^(__kindof UICollectionViewCell * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
			
			[obj setHighlighted:NO];
		}];
	}
	else if ([context.previouslyFocusedView isKindOfClass:NSClassFromString(@"UITabBarButton")] && [context.nextFocusedView isKindOfClass:[IGRChanelCell class]])
	{
		[(IGRChanelCell *)context.nextFocusedView setHighlighted:YES];
	}
		
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	if ([segue.identifier isEqualToString:@"showChanel"])
	{
		IGRCChanelViewController *catalogViewController = segue.destinationViewController;
		
		NSIndexPath *dbIndexPath = [NSIndexPath indexPathForRow:0 inSection:(self.chanels.indexPathsForSelectedItems.firstObject.row + self.chanels.indexPathsForSelectedItems.firstObject.section)];
		IGREntityExChanel *chanel = [self.fetchedResultsController objectAtIndexPath:dbIndexPath];
		
		dispatch_async(dispatch_get_main_queue(), ^{
			
			[catalogViewController setChanel:chanel.itemId];
		});
	}
}

#pragma mark - UICollectionViewDataSource
#pragma mark -

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return (self.fetchedResultsController).sections.count;
}

// The cell that is returned must be retrieved from a call to -dequeueReusableCellWithReuseIdentifier:forIndexPath:
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
	IGRChanelCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"IGRChanelCell" forIndexPath:indexPath];
	
	NSIndexPath *dbIndexPath = [NSIndexPath indexPathForRow:0 inSection:(indexPath.row + indexPath.section)];
	IGREntityExChanel *track = [self.fetchedResultsController objectAtIndexPath:dbIndexPath];
	
	cell.title.text = track.name;
	
	return cell;
}

#pragma mark - UICollectionViewDelegate
#pragma mark -

- (BOOL)collectionView:(UICollectionView *)collectionView shouldUpdateFocusInContext:(UICollectionViewFocusUpdateContext *)context
{
	IGRChanelCell *previouslyFocusedCell = (IGRChanelCell *)context.previouslyFocusedView;
	IGRChanelCell *nextFocusedCell = (IGRChanelCell *)context.nextFocusedView;
	
	[previouslyFocusedCell setHighlighted:NO];
	[nextFocusedCell setHighlighted:YES];
	
	return YES;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
	self.lastSelectedItem = indexPath;
}

#pragma mark - Fetched results controller

- (NSFetchedResultsController *)fetchedResultsController
{
	if (_fetchedResultsController == nil)
	{
		IGREntityAppSettings *settings = [self appSettings];
		NSPredicate *predicate = [NSPredicate predicateWithFormat:@"videoCatalog.itemId == %@", settings.videoLanguageId];
		_fetchedResultsController = [IGREntityExChanel MR_fetchAllGroupedBy:@"name"
															 withPredicate:predicate
																  sortedBy:@"name"
																 ascending:YES];
	}
	
	return _fetchedResultsController;
}

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
	_sectionChanges = [[NSMutableArray alloc] init];
	_itemChanges = [[NSMutableArray alloc] init];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
		   atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type
{
	NSMutableDictionary *change = [[NSMutableDictionary alloc] init];
	change[@(type)] = @(sectionIndex);
	[_sectionChanges addObject:change];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject
	   atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type
	  newIndexPath:(NSIndexPath *)newIndexPath
{
	NSMutableDictionary *change = [[NSMutableDictionary alloc] init];
	switch(type) {
		case NSFetchedResultsChangeInsert:
			change[@(type)] = newIndexPath;
			break;
		case NSFetchedResultsChangeDelete:
			change[@(type)] = indexPath;
			break;
		case NSFetchedResultsChangeUpdate:
			change[@(type)] = indexPath;
			break;
		case NSFetchedResultsChangeMove:
			change[@(type)] = @[indexPath, newIndexPath];
			break;
	}
	[_itemChanges addObject:change];
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
	[self.chanels performBatchUpdates:^{
		for (NSDictionary *change in _sectionChanges) {
			[change enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
				NSFetchedResultsChangeType type = [key unsignedIntegerValue];
				switch(type) {
					case NSFetchedResultsChangeInsert:
						[self.chanels insertSections:[NSIndexSet indexSetWithIndex:[obj unsignedIntegerValue]]];
						break;
					case NSFetchedResultsChangeDelete:
						[self.chanels deleteSections:[NSIndexSet indexSetWithIndex:[obj unsignedIntegerValue]]];
						break;
					default:
						break;
				}
			}];
		}
		for (NSDictionary *change in _itemChanges) {
			[change enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
				NSFetchedResultsChangeType type = [key unsignedIntegerValue];
				switch(type) {
					case NSFetchedResultsChangeInsert:
						[self.chanels insertItemsAtIndexPaths:@[obj]];
						break;
					case NSFetchedResultsChangeDelete:
						[self.chanels deleteItemsAtIndexPaths:@[obj]];
						break;
					case NSFetchedResultsChangeUpdate:
						[self.chanels reloadItemsAtIndexPaths:@[obj]];
						break;
					case NSFetchedResultsChangeMove:
						[self.chanels moveItemAtIndexPath:obj[0] toIndexPath:obj[1]];
						break;
				}
			}];
		}
	} completion:^(BOOL finished) {
		_sectionChanges = nil;
		_itemChanges = nil;
	}];
}

@end