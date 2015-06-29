//
//  ViewController.m
//  FiveHundredDaysOfKristin
//
//  Created by Kyle Lucovsky on 6/26/15.
//  Copyright (c) 2015 Kyle Lucovsky. All rights reserved.
//

#import "ViewController.h"
#import "DataManager.h"
#import "ColorManager.h"
#import "Post.h"
#import "KristinWebViewController.h"
#import "TableViewCell.h"

@interface ViewController ()  <UIScrollViewDelegate, UITableViewDelegate, UITableViewDataSource>
// views
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UILabel *taglineView;
@property (weak, nonatomic) IBOutlet UILabel *headlineView;
@property (weak, nonatomic) IBOutlet UITableView *tbView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *kristinCenterX;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *kristinCenterY;

// data
@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (strong, nonatomic) NSArray *allPosts;
@property (strong, nonatomic) Post *currentPost;
@property (nonatomic) NSInteger nextPage;
@property (nonatomic) BOOL isLoadingNextPage;
@end

@implementation ViewController

#pragma mark - Initialization

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupViewAttributes];
    [self setupImageDisplay];
    [self setupTableView];
    [[DataManager sharedInstance] fetchLatestKristinPosts];

    // fetch posts
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(feedReturned:) name:kFeedReturned object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(nextPageAvailable:) name:kNextPageAvailable object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(nextPageUnavailable) name:kNextPageUnavailable object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(nextPageAvailable:) name:kRequestingSamePageError object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(previousPostsReturned:) name:kPreviousFeedReturned object:nil];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Rendering

- (void)setupViewAttributes
{
    // setup navigation bar
    self.navigationController.navigationBar.backgroundColor = [UIColor whiteColor];
    [self.navigationController.navigationBar setTitleTextAttributes:@{NSFontAttributeName: [UIFont fontWithName:@"Allura" size:30]}];
    
    // setup gradient
    CAGradientLayer *gradient = [ColorManager blueGradient];
    gradient.frame = self.view.bounds;
    [self.view.layer insertSublayer:gradient atIndex:0];
}

- (void)setupImageDisplay
{
    // setup image display
    self.imageView.layer.cornerRadius = self.imageView.frame.size.width / 2;
    self.imageView.layer.borderWidth = 5;
    self.imageView.layer.borderColor = [UIColor whiteColor].CGColor;
    
    // animate image
    [UIView setAnimationRepeatCount:INFINITY];
    [UIView setAnimationRepeatAutoreverses:YES];
    [UIView animateWithDuration:1.5
                          delay:0
                        options: UIViewAnimationOptionRepeat | UIViewAnimationOptionAutoreverse | UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionAllowUserInteraction
                     animations:^{
                         CGAffineTransform t = CGAffineTransformMakeScale(0.95, 0.95);
                         self.imageView.transform = CGAffineTransformTranslate(t, 0, 5);
                     }
                     completion:nil];
}

- (void)setupTableView
{
    self.tbView.backgroundColor = [UIColor clearColor];
    self.tbView.layer.opacity = 0;
    self.tbView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tbView.showsVerticalScrollIndicator = NO;
    [self.tbView registerNib:[UINib nibWithNibName:@"TableViewCell" bundle:nil] forCellReuseIdentifier:@"TimelineCell"];
}

- (void)initializeWebview
{
    if (self.currentPost) {
        KristinWebViewController *webViewController = [[KristinWebViewController alloc] initWithNibName:@"KristinWebViewController" bundle:nil];
        webViewController.permalink = self.currentPost.permalink;
        [self.navigationController showViewController:webViewController sender:self];
    }
}

#pragma mark - Scroll Delegate Methods

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    Post *post = [self.fetchedResultsController objectAtIndexPath:[self.tbView indexPathForCell:self.tbView.visibleCells[0]]];
    
    if (![self.currentPost isEqual:post]) {
        self.currentPost = post;
        self.headlineView.text = self.currentPost.headline;
    }
}

#pragma mark - Table View Delegate Methods

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    Post *post = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    if ([post.day isEqualToNumber:@1]) {
        return 565;
    } else {
        return 200;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    Post *post = [self.fetchedResultsController objectAtIndexPath:indexPath];
    TableViewCell *cell = (TableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"TimelineCell" forIndexPath:indexPath];
    
    cell.permalink = post.permalink;
    cell.headline = post.headline;
    cell.timelineView.day = [post.day integerValue];
    
    return cell;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [[self.fetchedResultsController sections] count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if ([[self.fetchedResultsController sections] count] > 0) {
        id <NSFetchedResultsSectionInfo> sectionInfo = [[self.fetchedResultsController sections] objectAtIndex:section];
        return [sectionInfo numberOfObjects];
    } else
        return 0;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row + 1 == self.fetchedResultsController.fetchedObjects.count) {
        self.fetchedResultsController.fetchRequest.fetchLimit = self.fetchedResultsController.fetchRequest.fetchLimit + 25;
        
        if (self.nextPage) {
            [[DataManager sharedInstance] fetchPreviousBatchOfPosts:self.nextPage];
        }
        
        [self reload];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionTop animated:YES];
}

#pragma mark - Fetched Results Controller

- (NSFetchedResultsController *)fetchedResultsController
{
    if (!_fetchedResultsController) {
        DataManager *dataManager = [DataManager sharedInstance];
        
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"Post" inManagedObjectContext:dataManager.readingContext];
        NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"day" ascending:NO];
        
        fetchRequest.entity = entity;
        fetchRequest.fetchLimit = 25;
        [fetchRequest setSortDescriptors:@[sortDescriptor]];
        
        self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                            managedObjectContext:dataManager.readingContext
                                                                              sectionNameKeyPath:nil
                                                                                       cacheName:@"com.kinja.cache.days"];
    }
    
    return _fetchedResultsController;
}

- (void)fetchData
{
    [self reload];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(initializeWebview)];
    [self.imageView addGestureRecognizer:tap];
    
    self.currentPost = self.fetchedResultsController.fetchedObjects[0];
    self.headlineView.text = self.currentPost.headline;

    double delayInSeconds = 1.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^{
        [self.view.layer removeAllAnimations];
        [UIView setAnimationRepeatCount:0];
        [UIView setAnimationRepeatAutoreverses:NO];
        [UIView animateWithDuration:0.3
                              delay:0
                            options:UIViewAnimationOptionCurveEaseIn
                         animations:^{
                             self.kristinCenterX.constant = -75;
                             self.kristinCenterY.constant = 150;
                             [self.view layoutIfNeeded];
                             self.imageView.transform = CGAffineTransformMakeScale(0.7, 0.7);
                             self.headlineView.layer.opacity = 1;
                             self.taglineView.layer.opacity = 0;
                             self.tbView.layer.opacity = 1;
                         }
                         completion:^(BOOL finished) {
                             if (finished) {
                                 [self.taglineView removeFromSuperview];
                             }
                         }];
    });
}

- (void)reload
{
    NSError *error;
    
    if (![self.fetchedResultsController performFetch:&error]) {
        NSLog(@"%@, %@", error, error.localizedDescription);
        abort();
    }
    
    [self.tbView reloadData];
}

#pragma mark - Gestures and Events

- (void)feedReturned:(NSNotification *)notification
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self fetchData];
    });
}

- (void)previousPostsReturned:(NSNotification *)notification
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self reload];
    });
}

- (void)nextPageAvailable:(NSNotification *)notification
{
    self.nextPage = [notification.userInfo[@"startIndex"] integerValue];
}

- (void)nextPageUnavailable
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kNextPageAvailable object:nil];
}

@end
