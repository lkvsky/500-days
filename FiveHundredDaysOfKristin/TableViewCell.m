//
//  TableViewCell.m
//  FiveHundredDaysOfKristin
//
//  Created by Kyle Lucovsky on 7/1/15.
//  Copyright (c) 2015 Kyle Lucovsky. All rights reserved.
//

#import "TableViewCell.h"

@interface TableViewCell ()
@property (weak, nonatomic) IBOutlet UIImageView *notchImageView;
@end

@implementation TableViewCell

- (void)awakeFromNib {
    self.backgroundColor = [UIColor clearColor];
    self.selectionStyle = UITableViewCellSelectionStyleNone;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
    
    if (selected) {
        self.notchImageView.image = [UIImage imageNamed:@"timeline_w_kristin"];
        self.dayLabel.layer.opacity = 0;
    } else {
        self.notchImageView.image = [UIImage imageNamed:@"timeline_notch"];
        self.dayLabel.layer.opacity = 1;
    }
}

@end
