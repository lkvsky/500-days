//
//  ColorManager.m
//  FiveHundredDaysOfKristin
//
//  Created by Kyle Lucovsky on 6/26/15.
//  Copyright (c) 2015 Kyle Lucovsky. All rights reserved.
//

#import "ColorManager.h"

@implementation ColorManager
+ (UIColor *)darkerBlue
{
    return [UIColor colorWithRed:0/255.0 green:114.0/255.0 blue:171.0/255.0 alpha:1.0];
}

+ (UIColor *)lighterBlue
{
    return [UIColor colorWithRed:0/255.0 green:148.0/255.0 blue:222.0/255.0 alpha:1.0];
}

+ (UIColor *)redColor
{
    return [UIColor colorWithRed:222.0/255.0 green:0/255.0 blue:37.0/255.0 alpha:1.0];
}

+ (CAGradientLayer *)blueGradient
{
    CAGradientLayer *blueGradient = [[CAGradientLayer alloc] init];
    blueGradient.colors = @[(id)[self lighterBlue].CGColor, (id)[self darkerBlue].CGColor];
    
    return blueGradient;
}
@end
