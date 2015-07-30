//
//  DataManager.h
//  FiveHundredDaysOfKristin
//
//  Created by Kyle Lucovsky on 6/26/15.
//  Copyright (c) 2015 Kyle Lucovsky. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

#define kFeedReturned @"KristinFeedReturned"
#define kPreviousFeedReturned @"KristinPreviousFeedReturned"
#define kLatestPostReturned @"KristinLatestPostReturned"
#define kNextPageAvailable @"KristinNextPageAvailable"
#define kNextPageUnavailable @"KristinNextPageUnavailable"
#define kRequestingSamePageError @"KristinRequestingSamePageError"
#define kNetworkConnectionError @"KristinNetworkConnectionError"

@interface DataManager : NSObject
@property (strong, nonatomic) NSManagedObjectContext *readingContext;

+ (instancetype)sharedInstance;
- (void)fetchPreviousBatchOfPosts:(NSInteger)startTime;
- (void)fetchLatestKristinPosts;
- (void)createManagedObjectContextsWithPersistentStoreCoordinator:(NSPersistentStoreCoordinator *)persistentStoreCoordinator;
@end
