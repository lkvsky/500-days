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
@property (weak, nonatomic) IBOutlet UIImageView *selectedImage;
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
        [UIView animateWithDuration:0.125
                         animations:^{
                             self.selectedImage.layer.opacity = 1;
                         }];
    } else {
        [UIView animateWithDuration:0.125
                         animations:^{
                             self.selectedImage.layer.opacity = 0;
                         }];
    }
}

@end
