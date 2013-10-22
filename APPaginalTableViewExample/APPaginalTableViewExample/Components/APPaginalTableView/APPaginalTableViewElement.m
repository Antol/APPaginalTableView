//
//  APPaginalTableViewElement.m
//  BuyMeAPie
//
//  Created by Antol Peshkov on 21.08.13.
//  Copyright (c) 2013 BuyMeAPie. All rights reserved.
//

#import "APPaginalTableViewElement.h"

@interface APPaginalTableViewElement ()
@property (nonatomic, getter = isRasterizeSubviews) BOOL rasterizeSubviews;
@property (nonatomic) CGFloat height;
@property (nonatomic, strong) UIView *collapsedView;
@property (nonatomic, strong) UIView *expandedView;
@property (nonatomic, strong) UIView *currentView;
@end

#pragma mark -

const CGFloat kAPPaginalTableViewElementAnimationDuration = 0.3f;

@implementation APPaginalTableViewElement

@synthesize rasterizeSubviews = _rasterizeSubviews;

@synthesize collapsedView = _collapsedView;
@synthesize expandedView = _expandedView;
@synthesize currentView = _currentView;

@synthesize collapsedHeight = _collapsedHeight;
@synthesize expandedHeight = _expandedHeight;

- (id)initCollapsedWithCollapsedView:(UIView *)collapsedView expandedView:(UIView *)expandedView
{
    self = [super initWithFrame:collapsedView.frame];
    if (self) {
        self.clipsToBounds = YES;
        self.backgroundColor = [UIColor clearColor];
        
        self.collapsedHeight = collapsedView.frame.size.height;
        self.expandedHeight = expandedView.frame.size.height;
        
        if ((expandedView.autoresizingMask & UIViewAutoresizingFlexibleHeight) != 0) {
            expandedView.frame = self.frame;
        }
        self.collapsedView = collapsedView;
        self.expandedView = expandedView;
        
        [self changeHeight:self.collapsedHeight];
        
        self.currentView = collapsedView;
    }
    return self;
}

- (id)initExpandedWithCollapsedView:(UIView *)collapsedView expandedView:(UIView *)expandedView
{
    self = [super initWithFrame:expandedView.frame];
    if (self) {
        self.clipsToBounds = YES;
        self.backgroundColor = [UIColor clearColor];
        
        self.collapsedHeight = collapsedView.frame.size.height;
        self.expandedHeight = expandedView.frame.size.height;
        
        if ((collapsedView.autoresizingMask & UIViewAutoresizingFlexibleHeight) != 0) {
            collapsedView.frame = self.frame;
        }
        self.collapsedView = collapsedView;
        self.expandedView = expandedView;
        
        [self changeHeight:self.expandedHeight];
        
        self.currentView = expandedView;
    }
    return self;
}

#pragma mark - Properties

- (CGFloat)height
{
    return self.frame.size.height;
}

- (void)setHeight:(CGFloat)height
{
    self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, self.frame.size.width, height);
}

- (void)setCollapsedView:(UIView *)collapsedView
{
    [_collapsedView removeFromSuperview];
    _collapsedView = collapsedView;
    [self addSubview:_collapsedView];
}

- (void)setExpandedView:(UIView *)expandedView
{
    [_expandedView removeFromSuperview];
    _expandedView = expandedView;
    [self addSubview:_expandedView];
}

- (void)setRasterizeSubviews:(BOOL)rasterizeSubviews
{
    if (_rasterizeSubviews != rasterizeSubviews) {
        self.collapsedView.layer.rasterizationScale = [[UIScreen mainScreen] scale];
        self.expandedView.layer.rasterizationScale = [[UIScreen mainScreen] scale];
        
        self.collapsedView.layer.shouldRasterize = rasterizeSubviews;
        self.expandedView.layer.shouldRasterize = rasterizeSubviews;

    }
    _rasterizeSubviews = rasterizeSubviews;
}

#pragma mark - Methods

- (void)changeHeight:(CGFloat)height
{
    CGFloat newHeight = MIN(self.expandedHeight, MAX(height, self.collapsedHeight));
    
    BOOL isTransitionState = height != self.collapsedHeight && height != self.expandedHeight;
    self.rasterizeSubviews = isTransitionState;
    
    self.height = newHeight;
    
    self.collapsedView.alpha = [self alphaForCollapsedView];
    self.expandedView.alpha = [self alphaForExpandedView];
}

- (void)expandAnimated:(BOOL)animated completion:(void (^)(BOOL finished))completion
{
    self.rasterizeSubviews = YES;
    
    void (^blockOpenAnimation)(void) = ^(void)
    {
        self.height = self.expandedHeight;
        self.collapsedView.alpha = 0.f;
        self.expandedView.alpha = 1.f;
    };
    
    void (^blockInternalCompletion)(BOOL) = ^(BOOL finished)
    {
        self.rasterizeSubviews = NO;
        self.currentView = self.expandedView;
        
        if (completion != nil) {
            completion(finished);
        }
    };
    
    if (animated) {
        [UIView animateWithDuration:kAPPaginalTableViewElementAnimationDuration
                         animations:blockOpenAnimation
                         completion:blockInternalCompletion];
    }
    else {
        blockOpenAnimation();
        blockInternalCompletion(YES);
    }
    
}

- (void)collapseAnimated:(BOOL)animated completion:(void (^)(BOOL finished))completion
{
    self.rasterizeSubviews = YES;
    
    void (^blockCollapseAnimation)(void) = ^(void)
    {
        self.height = self.collapsedHeight;
        self.collapsedView.alpha = 1.f;
        self.expandedView.alpha = 0.f;
    };
    
    void (^blockInternalCompletion)(BOOL) = ^(BOOL finished)
    {
        self.rasterizeSubviews = NO;
        self.currentView = self.collapsedView;
        
        if (completion != nil) {
            completion(finished);
        }
    };
    
    if (animated) {
        [UIView animateWithDuration:kAPPaginalTableViewElementAnimationDuration
                         animations:blockCollapseAnimation
                         completion:blockInternalCompletion];
    }
    else {
        blockCollapseAnimation();
        blockInternalCompletion(YES);
    }
}

#pragma mark - Internal

- (CGFloat)alphaForCollapsedView
{
    CGFloat diffViewsHeight = self.expandedHeight - self.collapsedHeight;
    CGFloat diffCurrentHeight = self.frame.size.height - self.collapsedHeight;
    
    CGFloat heightTransitionMin;
    CGFloat heightTransitionMax;
    
    if (self.currentView == self.collapsedView) {
        heightTransitionMin = diffViewsHeight * 0.f;
        heightTransitionMax = diffViewsHeight * 0.3f;
    }
    else {
        heightTransitionMin = diffViewsHeight * 0.6f;
        heightTransitionMax = diffViewsHeight * 0.85f;
    }
    
    CGFloat alpha = MAX(0.f, MIN(1.f - (diffCurrentHeight - heightTransitionMin) / (heightTransitionMax - heightTransitionMin), 1.f));
    return alpha;
}

- (CGFloat)alphaForExpandedView
{
    CGFloat diffViewsHeight = self.expandedHeight - self.collapsedHeight;
    CGFloat diffCurrentHeight = self.frame.size.height - self.collapsedHeight;
    
    CGFloat heightTransitionMin;
    CGFloat heightTransitionMax;
    
    if (self.currentView == self.collapsedView) {
        heightTransitionMin = diffViewsHeight * 0.f;
        heightTransitionMax = diffViewsHeight * 0.3f;
    }
    else {
        heightTransitionMin = diffViewsHeight * 0.6f;
        heightTransitionMax = diffViewsHeight * 0.85f;
    }
    
    CGFloat alpha = MAX(0.f, MIN((diffCurrentHeight - heightTransitionMin) / (heightTransitionMax - heightTransitionMin), 1.f));
    return alpha;
}

@end
