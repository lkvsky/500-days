//
//  TableViewCell.h
//  FiveHundredDaysOfKristin
//
//  Created by Kyle Lucovsky on 7/1/15.
//  Copyright (c) 2015 Kyle Lucovsky. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TimelineView.h"

@interface TableViewCell : UITableViewCell
@property (strong, nonatomic) NSString *permalink;
@property (strong, nonatomic) NSString *headline;
@property (weak, nonatomic) TimelineView *timelineView;
@end
