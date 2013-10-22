//
//  APViewController.m
//  PaginalTableViewExample
//
//  Created by Antol Peshkov on 22.10.13.
//  Copyright (c) 2013 brainSTrainer. All rights reserved.
//

#import "APViewController.h"
#import "APPaginalTableView.h"

@interface APViewController () < APPaginalTableViewDataSource,
                                 APPaginalTableViewDelegate >
@end

@implementation APViewController {
    APPaginalTableView *_paginalTableView;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	self.view.backgroundColor = [UIColor lightGrayColor];
    
    _paginalTableView = [[APPaginalTableView alloc] initWithFrame:self.view.bounds];
    
    _paginalTableView.dataSource = self;
    _paginalTableView.delegate = self;
    
    [self.view addSubview:_paginalTableView];
}

#pragma mark - APPaginalTableViewDataSource

- (NSUInteger)numberOfElementsInPaginalTableView:(APPaginalTableView *)managerView
{
    NSUInteger numberOfElements = 8;
    return numberOfElements;
}

- (UIView *)paginalTableView:(APPaginalTableView *)paginalTableView collapsedViewAtIndex:(NSUInteger)index
{
    UIView *collapsedView = [self createCollapsedViewAtIndex:index];
    return collapsedView;
}

- (UIView *)paginalTableView:(APPaginalTableView *)paginalTableView expandedViewAtIndex:(NSUInteger)index
{
    UIView *expandedView = [self createExpandedViewAtIndex:index];
    return expandedView;
}

#pragma mark - APPaginalTableViewDelegate

- (BOOL)paginalTableView:(APPaginalTableView *)managerView
      openElementAtIndex:(NSUInteger)index
      onChangeHeightFrom:(CGFloat)initialHeight
                toHeight:(CGFloat)finalHeight
{
    BOOL open = _paginalTableView.isExpandedState;
    APPaginalTableViewElement *element = [managerView elementAtIndex:index];
    
    if (initialHeight > finalHeight) { //open
        open = finalHeight > element.expandedHeight * 0.8f;
    }
    else if (initialHeight < finalHeight) { //close
        open = finalHeight > element.expandedHeight * 0.2f;
    }
    return open;
}

- (void)paginalTableView:(APPaginalTableView *)paginalTableView didSelectRowAtIndex:(NSUInteger)index
{
    [_paginalTableView openElementAtIndex:index completion:nil animated:YES];
}

#pragma mark - Internal

- (UIView *)createCollapsedViewAtIndex:(NSUInteger)index
{
    UILabel *labelCollapsed = [[UILabel alloc] initWithFrame:CGRectMake(10.f, 0.f, 150.f, 50.f)];
    labelCollapsed.text = [NSString stringWithFormat:@"Collapsed View %d", index];
    
    UIView *collapsedView = [[UIView alloc] initWithFrame:CGRectMake(0.f, 0.f, self.view.bounds.size.width, 80.f)];
    collapsedView.backgroundColor = [UIColor colorWithRed:0.f + (index * 0.1f) green:0.3f blue:0.7f alpha:1.f];
    collapsedView.autoresizingMask = UIViewAutoresizingFlexibleHeight;
    [collapsedView addSubview:labelCollapsed];
    
    return collapsedView;
}

- (UIView *)createExpandedViewAtIndex:(NSUInteger)index
{
    UILabel *labelExpanded = [[UILabel alloc] initWithFrame:CGRectMake(30.f, 30.f, 150.f, 50.f)];
    labelExpanded.text = [NSString stringWithFormat:@"Expanded View %d", index];
    
    UIView *expandedView = [[UIView alloc] initWithFrame:self.view.bounds];
    expandedView.backgroundColor = [UIColor colorWithRed:0.f green:0.8f - (index * 0.08f) blue:0.2f + (index * 0.08f) alpha:1.f];
    [expandedView addSubview:labelExpanded];
    
    return expandedView;
}

@end
