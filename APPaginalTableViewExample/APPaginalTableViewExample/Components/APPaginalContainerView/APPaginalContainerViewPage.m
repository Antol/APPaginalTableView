//
//  APPaginalContainerViewPage.m
//  BuyMeAPie
//
//  Created by Antol Peshkov on 22.08.13.
//  Copyright (c) 2013 BuyMeAPie. All rights reserved.
//

#import "APPaginalContainerViewPage.h"

@implementation APPaginalContainerViewPage

#pragma mark - Properties
@synthesize contentView = _contentView;
@synthesize focused = _focused;

- (id)init
{
    CGRect frame = [UIScreen mainScreen].applicationFrame;
    frame = CGRectMake(0.f, 0.f, frame.size.width, frame.size.height);
    self = [super initWithFrame:frame];
    
    if (self) {
        _focused = NO;
    }
    
    return self;
}

#pragma mark - Properties Methods

- (void)setContentView:(UIView *)contentView
{
    [_contentView removeFromSuperview];
    
    _contentView = contentView;
    
    if (_contentView) {
        [self addSubview:_contentView];
    }
}

@end
