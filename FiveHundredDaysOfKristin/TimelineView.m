//
//  TimelineView.m
//  FiveHundredDaysOfKristin
//
//  Created by Kyle Lucovsky on 6/27/15.
//  Copyright (c) 2015 Kyle Lucovsky. All rights reserved.
//

#import "TimelineView.h"
#import "ColorManager.h"

@interface TimelineView()
@property (weak, nonatomic) UILabel *dayLabel;
@property (strong, nonatomic) UIColor *fillColor;
@end

@implementation TimelineView

#define kStrokeWidth 10
#define kNotchDistance 150
#define kNotchWidth 30

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
    
    NSInteger timelineX = (rect.size.width / 2) + kStrokeWidth;
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    
    // draw circle
    CGContextSetFillColorWithColor(ctx, self.fillColor.CGColor);
    NSInteger notchX = timelineX - (kNotchWidth / 2);
    CGRect ellipseRect = CGRectMake(notchX, 0, kNotchWidth, kNotchWidth);
    CGContextAddEllipseInRect(ctx, ellipseRect);
    CGContextFillEllipseInRect(ctx, ellipseRect);
    
    // draw line to next notch
    if (self.day > 1) {
        CGContextSetStrokeColorWithColor(ctx, self.fillColor.CGColor);
        CGContextSetLineWidth(ctx, kStrokeWidth);
        CGContextMoveToPoint(ctx, timelineX, rect.origin.y + (kNotchWidth / 2));
        CGContextAddLineToPoint(ctx, timelineX, rect.size.height);
        CGContextStrokePath(ctx);
    }
}

#pragma mark - Initialization

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    [self setup];
    
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    [self setup];
    
    return self;
}

- (void)dealloc
{
    [self removeObserver:self forKeyPath:@"day"];
}

- (UIColor *)fillColor
{
    if (!_fillColor) _fillColor = [UIColor whiteColor];
    
    return _fillColor;
}

#pragma mark - Gestures and Events

- (void)setup
{
    // label view
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(self.frame.origin.x, self.frame.origin.y, 75, 75)];
    label.textColor = [UIColor whiteColor];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:label];
    self.dayLabel = label;
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.dayLabel
                                                     attribute:NSLayoutAttributeLeading
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:self
                                                     attribute:NSLayoutAttributeLeft
                                                    multiplier:1.0
                                                      constant:0]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.dayLabel
                                                     attribute:NSLayoutAttributeTop
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:self
                                                     attribute:NSLayoutAttributeTop
                                                    multiplier:1.0
                                                      constant:3]];
    
    self.backgroundColor = [UIColor clearColor];
    [self addObserver:self forKeyPath:@"day" options:0 context:nil];
    self.translatesAutoresizingMaskIntoConstraints = NO;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"day"]) {
        self.dayLabel.text = [NSString stringWithFormat:@"Day %ld", self.day];
        self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, self.frame.size.width, kNotchDistance);

        [self setNeedsDisplay];
    }
}

@end
