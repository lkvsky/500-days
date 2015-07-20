//
//  KristinWebViewController.m
//  FiveHundredDaysOfKristin
//
//  Created by Kyle Lucovsky on 6/27/15.
//  Copyright (c) 2015 Kyle Lucovsky. All rights reserved.
//

#import "KristinWebViewController.h"

@import WebKit;

@interface KristinWebViewController () <WKNavigationDelegate>
@property (weak, nonatomic) IBOutlet UIProgressView *progressView;
@property (strong, nonatomic) NSTimer *timer;
@end

@implementation KristinWebViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if ([self respondsToSelector:@selector(edgesForExtendedLayout)])
        self.edgesForExtendedLayout = UIRectEdgeNone;
    
    WKWebView *webView = [[WKWebView alloc] initWithFrame:CGRectZero];
    webView.translatesAutoresizingMaskIntoConstraints = NO;
    webView.navigationDelegate = self;
    [self.view addSubview:webView];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:webView
                                                          attribute:NSLayoutAttributeTop
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.progressView
                                                          attribute:NSLayoutAttributeBottom
                                                         multiplier:1.0
                                                           constant:0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:webView
                                                          attribute:NSLayoutAttributeLeading
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.view
                                                          attribute:NSLayoutAttributeLeft
                                                         multiplier:1.0
                                                           constant:0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:webView
                                                          attribute:NSLayoutAttributeBottom
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.view
                                                          attribute:NSLayoutAttributeBottom
                                                         multiplier:1.0
                                                           constant:0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:webView
                                                          attribute:NSLayoutAttributeRight
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.view
                                                          attribute:NSLayoutAttributeRight
                                                         multiplier:1.0
                                                           constant:0]];
    
    self.timer = [NSTimer scheduledTimerWithTimeInterval:0.01667 target:self selector:@selector(increaseProgressBar) userInfo:nil repeats:YES];
    [webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:self.permalink]]];
}

-(void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation
{
    [self.timer invalidate];
    
    [UIView animateWithDuration:0.125
                     animations:^{
                         self.progressView.progress = 1;
                         self.progressView.layer.opacity = 0;
                     } completion:^(BOOL finished) {
                         self.progressView.hidden = YES;
                     }];
}

- (void)increaseProgressBar
{
    if (self.progressView.progress >= 0.95) {
        self.progressView.progress = 0.95;
        [self.timer invalidate];
    } else {
        self.progressView.progress += 0.01;
    }
}

@end
