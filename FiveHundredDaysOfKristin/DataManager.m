//
//  DataManager.m
//  FiveHundredDaysOfKristin
//
//  Created by Kyle Lucovsky on 6/26/15.
//  Copyright (c) 2015 Kyle Lucovsky. All rights reserved.
//

#import "DataManager.h"
#import "Post.h"

@interface DataManager()
@property (strong, nonatomic) NSURLSession *urlSession;
@property (strong, nonatomic) NSManagedObjectContext *insertionContext;
@property (strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic) NSInteger nextPage;
@property (nonatomic) NSInteger lastPageRequested;
@property (nonatomic) BOOL nextPageAvailable;
@end

@implementation DataManager

#pragma mark - Initialization

- (void)createManagedObjectContextsWithPersistentStoreCoordinator:(NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    self.persistentStoreCoordinator = persistentStoreCoordinator;
    
    // create insertion context
    self.insertionContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    self.insertionContext.persistentStoreCoordinator = self.persistentStoreCoordinator;
    self.insertionContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy;
    
    // create reading context
    self.readingContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    self.readingContext.persistentStoreCoordinator = self.persistentStoreCoordinator;
    self.readingContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy;
}

- (instancetype)init
{
    self = [super init];
    
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    self.urlSession = [NSURLSession sessionWithConfiguration:config];
    
    return self;
}

+ (instancetype)sharedInstance
{
    static DataManager *dataManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dataManager = [[self alloc] init];
    });
    
    return dataManager;
}

#pragma mark - Feed Management

- (NSDictionary *)parseFeedData:(NSData *)data withResponse:(NSURLResponse *)response withError:(NSError *)error
{
    NSArray *posts = @[];
    NSDictionary *pagination = @{};
    
    if (data.length && error == nil) {
        NSError *jsonError;
        id json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
        
        if (json[@"data"] && [json[@"data"] isKindOfClass:[NSDictionary class]]) {
            // grab posts
            if (json[@"data"][@"items"] && [json[@"data"][@"items"] isKindOfClass:[NSArray class]]) {
                posts = json[@"data"][@"items"];
            }
            
            // grab pagination
            if (json[@"data"][@"pagination"] && [json[@"data"][@"pagination"] isKindOfClass:[NSDictionary class]]) {
                pagination = json[@"data"][@"pagination"];
            }
        } else {
            NSLog(@"Malformed server response");
        }
        
    } else {
        NSLog(@"There was an error");
    }
    
    return @{@"posts": posts,
             @"pagination": pagination};
}

- (void)createPostsFromResults:(NSDictionary *)results
{    
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Post" inManagedObjectContext:self.readingContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    fetchRequest.entity = entity;
    
    for (NSDictionary *postDictionary in results[@"posts"]) {
        if (postDictionary[@"post"]) {
            NSDictionary *postData = postDictionary[@"post"];
            NSError *fetchError;
            NSArray *stringParts = [postData[@"headline"] componentsSeparatedByString:@":"];
            NSString *dayString = [stringParts[0] stringByReplacingOccurrencesOfString:@"500 Days of Kristin, Day " withString:@""];
            
            // Catch French Gawker exception
            if ([dayString containsString:@"Jours de Kristin"]) {
                continue;
            }
            
            NSNumber *day = [NSNumber numberWithInteger:[dayString integerValue]];
            fetchRequest.predicate = [NSPredicate predicateWithFormat:@"day = %@", day];
            NSUInteger objectStoredCount = [self.readingContext countForFetchRequest:fetchRequest error:&fetchError];
            
            if (objectStoredCount == 0 && [day integerValue] > 0) {
                Post *post = [NSEntityDescription insertNewObjectForEntityForName:@"Post" inManagedObjectContext:self.insertionContext];                
                post.headline = [[[[postData[@"headline"] stringByReplacingOccurrencesOfString:@"500 Days of Kristin, " withString:@""] stringByReplacingOccurrencesOfString:@"&amp;" withString:@"&"] stringByReplacingOccurrencesOfString:@"&quot;" withString:@"\""] stringByReplacingOccurrencesOfString:@"&#39;" withString:@"'"];
                post.day = day;
                post.permalink = postData[@"permalink"];
                
                NSTimeInterval time = (NSInteger)postDictionary[@"post"][@"publishTimeMillis"] / 1000;
                post.publishTime = [NSDate dateWithTimeIntervalSince1970:time];
            }
        }
    }
    
    if (results[@"pagination"] && results[@"pagination"][@"next"]) {
        self.nextPage = [results[@"pagination"][@"next"][@"startTime"] integerValue];
        self.nextPageAvailable = YES;
        [[NSNotificationCenter defaultCenter] postNotificationName:kNextPageAvailable object:nil userInfo:@{@"startTime": results[@"pagination"][@"next"][@"startTime"]}];
    } else {
        self.nextPage = 0;
        self.nextPageAvailable = NO;
        [[NSNotificationCenter defaultCenter] postNotificationName:kNextPageUnavailable object:nil userInfo:@{}];
    }
    
    [self saveInsertionContext];
}

- (void)fetchPreviousBatchOfPosts:(NSInteger)startTime
{
    if (self.lastPageRequested && self.lastPageRequested == startTime) {
        return;
    }
    
    if (self.nextPageAvailable) {
        self.lastPageRequested = startTime;
         NSString *previousKristinPosts = [NSString stringWithFormat:@"http://api.kinja.com/api/core/tag/500-days-of-kristin?startTime=%lu", (long)startTime];
        NSURL *kristinFeedUrl = [[NSURL alloc] initWithString:previousKristinPosts];
        NSURLSessionDataTask *dataTask = [self.urlSession dataTaskWithRequest:[NSURLRequest requestWithURL:kristinFeedUrl]
                                                            completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                                                if (nil != error) {
                                                                    
                                                                } else {
                                                                    NSDictionary *results = [self parseFeedData:data withResponse:response withError:error];
                                                                    [self createPostsFromResults:results];
                                                                    NSArray *allKristinPosts = [self allKristinPosts];
                                                                    
                                                                    if (allKristinPosts.count > 0) {
                                                                        [[NSNotificationCenter defaultCenter] postNotificationName:kPreviousFeedReturned object:nil userInfo:@{@"posts": allKristinPosts}];
                                                                    }
                                                                }
                                                            }];
        
        [dataTask resume];
    }
}

- (void)fetchLatestKristinPosts
{
    static NSString *kristinFeed = @"http://api.kinja.com/api/core/tag/500-days-of-kristin";
    NSURL *kristinFeedUrl = [[NSURL alloc] initWithString:kristinFeed];
    NSURLSessionDataTask *dataTask = [self.urlSession dataTaskWithRequest:[NSURLRequest requestWithURL:kristinFeedUrl]
                                                        completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                                            if (nil != error) {
                                                                [[NSNotificationCenter defaultCenter] postNotificationName:kNetworkConnectionError object:nil];
                                                            } else {
                                                                NSDictionary *results = [self parseFeedData:data withResponse:response withError:error];
                                                                [self createPostsFromResults:results];
                                                                NSArray *allKristinPosts = [self allKristinPosts];
                                                                
                                                                if (allKristinPosts.count > 0) {
                                                                    [[NSNotificationCenter defaultCenter] postNotificationName:kFeedReturned object:nil userInfo:@{@"posts": allKristinPosts}];
                                                                }
                                                            }
                                                        }];
    
    [dataTask resume];
}

- (NSArray *)allKristinPosts
{
    NSError *error;
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Post" inManagedObjectContext:self.readingContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    fetchRequest.entity = entity;
    fetchRequest.sortDescriptors = @[[[NSSortDescriptor alloc] initWithKey:@"day" ascending:NO]];
    
    NSArray *results = [self.readingContext executeFetchRequest:fetchRequest error:&error];
    
    if (error) {
        NSLog(@"%@, %@", error, error.localizedDescription);
        results = @[];
    }

    return results;
}

- (void)saveInsertionContext
{
    NSError *error;
    
    if (![self.insertionContext save:&error])
        NSLog(@"%@, %@", error, error.localizedDescription);
}

@end
