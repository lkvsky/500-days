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
    self.backgroundColor = [UIColor clearColor];
    self.selectionStyle = UITableViewCellSelectionStyleNone;
}

@end
