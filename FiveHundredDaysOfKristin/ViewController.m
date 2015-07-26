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
// timeline scene
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UILabel *taglineView;
@property (weak, nonatomic) IBOutlet UILabel *headlineView;
@property (weak, nonatomic) IBOutlet UIImageView *speechBubble;
@property (weak, nonatomic) IBOutlet UIView *speechBubbleContainer;
@property (weak, nonatomic) IBOutlet UITableView *tbView;
@property (weak, nonatomic) IBOutlet UIButton *readMoreButton;

// webview scene
@property (weak, nonatomic) IBOutlet UIView *webViewContainer;
@property (weak, nonatomic) IBOutlet UIView *webViewSceneWrapper;
@property (weak, nonatomic) IBOutlet UIButton *backButton;

// constraints
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *tbViewTop;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *tbViewHeight;

// data and flags
@property (strong, nonatomic) KristinWebViewController *webViewController;
@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (strong, nonatomic) NSArray *allPosts;
@property (strong, nonatomic) Post *currentPost;
@property (strong, nonatomic) NSIndexPath *selectedIndexPath;
@property (nonatomic) NSInteger nextPage;
@property (nonatomic) BOOL isLoadingNextPage;
@property (nonatomic) BOOL isAnimating;
@property (nonatomic) BOOL webViewIsOpen;
@property (nonatomic) BOOL timelineSelected;
@end

@implementation ViewController

#pragma mark - Initialization

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupViewAttributes];
    [self setupImageDisplay];
    [self setupTableView];
    [self setupWebViewContainer];
    [[DataManager sharedInstance] fetchLatestKristinPosts];

    // fetch posts and handle errors
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(feedReturned:) name:kFeedReturned object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(nextPageAvailable:) name:kNextPageAvailable object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(nextPageUnavailable) name:kNextPageUnavailable object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(nextPageAvailable:) name:kRequestingSamePageError object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(previousPostsReturned:) name:kPreviousFeedReturned object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(networkConnectionLost) name:kNetworkConnectionError object:nil];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Rendering

- (void)setupViewAttributes
{
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
    self.tbViewTop.constant = self.view.bounds.size.height;
    self.tbViewHeight.constant = self.view.bounds.size.height;
    self.tbView.backgroundColor = [UIColor clearColor];
    self.tbView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tbView.showsVerticalScrollIndicator = NO;
    [self.tbView registerNib:[UINib nibWithNibName:@"TableViewCell" bundle:nil] forCellReuseIdentifier:@"TimelineCell"];
}

- (void)setupWebViewContainer
{
    self.webViewContainer.layer.cornerRadius = 10;
    self.webViewSceneWrapper.transform = CGAffineTransformMakeTranslation(self.view.bounds.size.width, 0);
    
    UISwipeGestureRecognizer *swipeLeft = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(openWebView)];
    swipeLeft.direction = UISwipeGestureRecognizerDirectionLeft;
    [self.view addGestureRecognizer:swipeLeft];
    
    UISwipeGestureRecognizer *swipeRight = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(closeWebView)];
    swipeRight.direction = UISwipeGestureRecognizerDirectionRight;
    [self.view addGestureRecognizer:swipeRight];
}

- (UIView *)setupBackgroundView
{
    UIVisualEffectView *blurView = [self getBlurView];
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:self.view.bounds];
    UIView *backgroundView = [[UIView alloc] initWithFrame:self.view.bounds];
    
    imageView.image = [UIImage imageNamed:@"kristin"];
    imageView.contentMode = UIViewContentModeScaleAspectFill;
    backgroundView.layer.opacity = 0;
    
    [backgroundView addSubview:imageView];
    [backgroundView addSubview:blurView];
    
    return backgroundView;
}

- (void)setupWebView
{
    self.webViewController = [[KristinWebViewController alloc] initWithNibName:@"KristinWebViewController" bundle:nil];
    [self addChildViewController:self.webViewController];
    [self.webViewContainer addSubview:self.webViewController.view];
    self.webViewController.view.translatesAutoresizingMaskIntoConstraints = NO;
    [self.webViewContainer addConstraint:[NSLayoutConstraint constraintWithItem:self.webViewController.view
                                                                      attribute:NSLayoutAttributeTop
                                                                      relatedBy:NSLayoutRelationEqual
                                                                         toItem:self.webViewContainer
                                                                      attribute:NSLayoutAttributeTop
                                                                     multiplier:1.0
                                                                       constant:0]];
    [self.webViewContainer addConstraint:[NSLayoutConstraint constraintWithItem:self.webViewController.view
                                                                      attribute:NSLayoutAttributeBottom
                                                                      relatedBy:NSLayoutRelationEqual
                                                                         toItem:self.webViewContainer
                                                                      attribute:NSLayoutAttributeBottom
                                                                     multiplier:1.0
                                                                       constant:0]];
    [self.webViewContainer addConstraint:[NSLayoutConstraint constraintWithItem:self.webViewController.view
                                                                      attribute:NSLayoutAttributeLeading
                                                                      relatedBy:NSLayoutRelationEqual
                                                                         toItem:self.webViewContainer
                                                                      attribute:NSLayoutAttributeLeft
                                                                     multiplier:1.0
                                                                       constant:0]];
    [self.webViewContainer addConstraint:[NSLayoutConstraint constraintWithItem:self.webViewController.view
                                                                      attribute:NSLayoutAttributeTrailing
                                                                      relatedBy:NSLayoutRelationEqual
                                                                         toItem:self.webViewContainer
                                                                      attribute:NSLayoutAttributeRight
                                                                     multiplier:1.0
                                                                       constant:0]];
    
    [self.webViewController didMoveToParentViewController:self];
}

- (UIVisualEffectView *)getBlurView
{
    UIBlurEffect *effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
    UIVisualEffectView *blurView = [[UIVisualEffectView alloc] initWithEffect:effect];
    blurView.frame = self.view.bounds;
    
    return blurView;
}

#pragma mark - Scroll Delegate Methods

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    UITableViewCell *topCell = self.tbView.visibleCells[0];
    NSIndexPath *currentPath = [self.tbView indexPathForCell:topCell];
    Post *post = [self.fetchedResultsController objectAtIndexPath:currentPath];
    
    if (![self.currentPost isEqual:post]) {
        self.currentPost = post;
        self.headlineView.text = self.currentPost.headline;
        
        if (nil != self.selectedIndexPath) {
            [[self.tbView cellForRowAtIndexPath:self.selectedIndexPath] setSelected:NO animated:NO];
        }
        
        self.selectedIndexPath = currentPath;
    }
    
    if (!self.timelineSelected) {
        [topCell setSelected:YES animated:NO];
    }
}

#pragma mark - Table View Delegate Methods

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    Post *post = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    if ([post.day isEqualToNumber:@1]) {
        return self.view.bounds.size.height;
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
    cell.dayLabel.text = [NSString stringWithFormat:@"%lu", (long)[post.day integerValue]];
    
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
    self.timelineSelected = YES;
    [tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionTop animated:YES];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.timelineSelected = NO;
    });
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
    
    self.currentPost = self.fetchedResultsController.fetchedObjects[0];
    self.headlineView.text = self.currentPost.headline;
    UIView *backgroundView = [self setupBackgroundView];
    [self.view addSubview:backgroundView];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.view.layer removeAllAnimations];
        [UIView setAnimationRepeatCount:0];
        [UIView setAnimationRepeatAutoreverses:NO];
        [UIView animateWithDuration:0.3
                              delay:0
                            options:UIViewAnimationOptionCurveEaseIn
                         animations:^{
                             [self.view bringSubviewToFront:self.headlineView];
                             [self.view bringSubviewToFront:self.tbView];
                             [self.view bringSubviewToFront:self.speechBubbleContainer];
                             [self.view bringSubviewToFront:self.webViewSceneWrapper];
                             
                             [self.tbView.visibleCells[0] setSelected:YES animated:NO];                             
                             self.imageView.transform = CGAffineTransformMakeScale(0, 0);
                             backgroundView.layer.opacity = 1;
                             self.taglineView.layer.opacity = 0;
                         }
                         completion:^(BOOL finished) {
                             if (finished) {
                                 [self.taglineView removeFromSuperview];
                                 [self.imageView removeFromSuperview];
                                 UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(openWebView)];
                                 [self.speechBubbleContainer addGestureRecognizer:tap];
                                 
                                 [UIView animateWithDuration:0.3
                                                       delay:0.125
                                      usingSpringWithDamping:0.8
                                       initialSpringVelocity:0.6
                                                     options:0
                                                  animations:^{
                                                      self.speechBubbleContainer.alpha = 1;
                                                      self.tbViewTop.constant = 15;
                                                      [self.view layoutIfNeeded];
                                                  }
                                                  completion:nil];
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

- (IBAction)tapReadMore:(id)sender
{
    [self openWebView];
}

- (IBAction)tapBackButton:(id)sender
{
    [self closeWebView];
}

- (void)openWebView
{
    if (self.webViewIsOpen) return;
    
    if (self.currentPost) {
        if (nil == self.webViewController) {
            [self setupWebView];
        }
        
        self.webViewController.permalink = self.currentPost.permalink;
        
        [UIView animateWithDuration:0.3
                              delay:0
             usingSpringWithDamping:0.8
              initialSpringVelocity:0.6
                            options:0
                         animations:^{
                             self.webViewSceneWrapper.transform = CGAffineTransformIdentity;
                             self.tbView.transform = CGAffineTransformMakeTranslation(-self.view.frame.size.width, 0);
                             self.speechBubbleContainer.transform = CGAffineTransformMakeTranslation(-self.view.frame.size.width, 0);
                         }
                         completion:nil];
        
        self.webViewIsOpen = YES;
    }
}

- (void)closeWebView
{
    if (!self.webViewIsOpen) return;
    
    [UIView animateWithDuration:0.3
                     animations:^{
                         self.webViewSceneWrapper.transform = CGAffineTransformMakeTranslation(self.view.bounds.size.width, 0);
                         self.tbView.transform = CGAffineTransformIdentity;
                         self.speechBubbleContainer.transform = CGAffineTransformIdentity;
                     }];
    
    self.webViewIsOpen = NO;
}

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

- (void)networkConnectionLost
{
    // setup text label
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
    label.font = [UIFont fontWithName:@"Archer" size:36];
    label.text = @"Ugh! There's no internet :(";
    label.textColor = [UIColor whiteColor];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    label.lineBreakMode = NSLineBreakByWordWrapping;
    label.numberOfLines = 0;
    label.textAlignment = NSTextAlignmentCenter;
    
    // setup blur view for alert
    UIVisualEffectView *blurView = [self getBlurView];
    blurView.layer.opacity = 0;
    [blurView.contentView addSubview:label];
    [blurView addConstraint:[NSLayoutConstraint constraintWithItem:label
                                                         attribute:NSLayoutAttributeCenterX
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:blurView
                                                         attribute:NSLayoutAttributeCenterX
                                                        multiplier:1.0
                                                          constant:0]];
    [blurView addConstraint:[NSLayoutConstraint constraintWithItem:label
                                                         attribute:NSLayoutAttributeCenterY
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:blurView
                                                         attribute:NSLayoutAttributeCenterY
                                                        multiplier:1.0
                                                          constant:0]];
    [blurView addConstraint:[NSLayoutConstraint constraintWithItem:label
                                                      attribute:NSLayoutAttributeWidth
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:blurView
                                                         attribute:NSLayoutAttributeWidth
                                                        multiplier:1.0
                                                          constant:-20]];
    [self.view addSubview:blurView];
    
    // fade in alert and then remove after 3 seconds
    [self.view addSubview:blurView];
    
    if (self.webViewIsOpen) {
        [self closeWebView];
    }
    
    [UIView animateWithDuration:0.3
                     animations:^{
                         blurView.layer.opacity = 1;
                     }
                     completion:^(BOOL finished) {
                         [UIView animateWithDuration:0.3
                                               delay:3.0
                                             options:0
                                          animations:^{
                                              blurView.layer.opacity = 0;
                                          }
                                          completion:^(BOOL finished) {
                                              [blurView removeFromSuperview];
                                          }];
                     }];
}

@end
