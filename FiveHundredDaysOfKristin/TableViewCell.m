//
//  TableViewCell.m
//  FiveHundredDaysOfKristin
//
//  Created by Kyle Lucovsky on 7/1/15.
//  Copyright (c) 2015 Kyle Lucovsky. All rights reserved.
//

#import "TableViewCell.h"

@interface TableViewCell ()
@end

@implementation TableViewCell

- (void)awakeFromNib {
    [self setupTimelineView];
}

- (void)setupTimelineView
{
    self.backgroundColor = [UIColor clearColor];
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    TimelineView *timelineView = [[TimelineView alloc] initWithFrame:CGRectZero];
    
    [self addSubview:timelineView];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:timelineView
                                                     attribute:NSLayoutAttributeTop
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:self
                                                     attribute:NSLayoutAttributeTop
                                                    multiplier:1.0
                                                      constant:0]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:timelineView
                                                     attribute:NSLayoutAttributeLeading
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:self
                                                     attribute:NSLayoutAttributeLeft
                                                    multiplier:1.0
                                                      constant:0]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:timelineView
                                                     attribute:NSLayoutAttributeBottom
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:self
                                                     attribute:NSLayoutAttributeBottom
                                                    multiplier:1.0
                                                      constant:1]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:timelineView
                                                     attribute:NSLayoutAttributeTrailing
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:self
                                                     attribute:NSLayoutAttributeRight
                                                    multiplier:1.0
                                                      constant:0]];
    
    self.timelineView = timelineView;
}

@end
