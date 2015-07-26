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
@property (weak, nonatomic) WKWebView *webView;
@property (strong, nonatomic) NSTimer *timer;
@end

@implementation KristinWebViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if ([self respondsToSelector:@selector(edgesForExtendedLayout)])
        self.edgesForExtendedLayout = UIRectEdgeNone;
    
    WKWebView *webView = [[WKWebView alloc] initWithFrame:CGRectZero];
    webView.translatesAutoresizingMaskIntoConstraints = NO;
    webView.scrollView.translatesAutoresizingMaskIntoConstraints = NO;
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
    
    self.webView = webView;
    [self addObserver:self forKeyPath:@"permalink" options:0 context:nil];
}

- (void)dealloc
{
    [self removeObserver:self forKeyPath:@"permalink"];
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

#pragma mark - Webview Delegate Methods

- (void)webView:(WKWebView *)webView didCommitNavigation:(WKNavigation *)navigation
{
    // Content size of the web view's scrollview is wider than the frame
    NSString *webviewResizeString = [NSString stringWithFormat:@"var meta = document.createElement('meta'); " \
                                     "meta.setAttribute( 'name', 'viewport' ); " \
                                     "meta.setAttribute( 'content', 'width=%f, initial-scale=1.0, user-scalable=yes'); " \
                                     "document.getElementsByTagName('head')[0].appendChild(meta)", self.webView.frame.size.width];
    [self.webView evaluateJavaScript:webviewResizeString completionHandler:nil];
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation
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

#pragma mark - Gestures and Events

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"permalink"]) {
        self.progressView.progress = 0;
        self.progressView.hidden = NO;
        self.progressView.layer.opacity = 1;
        self.timer = [NSTimer scheduledTimerWithTimeInterval:0.01667 target:self selector:@selector(increaseProgressBar) userInfo:nil repeats:YES];
        [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:self.permalink]]];
    }
}

@end
