//
//  APPaginalTableView.m
//  BuyMeAPie
//
//  Created by Antol Peshkov on 21.08.13.
//  Copyright (c) 2013 BuyMeAPie. All rights reserved.
//

#import "APPaginalTableView.h"
#import "APPaginalTableViewElement.h"
#import "APPaginalContainerView.h"

@interface APPaginalTableView () < UITableViewDataSource,
                                   UITableViewDelegate,
                                   APPaginalContainerViewDataSource,
                                   APPaginalContainerViewDelegate >
@property (nonatomic, assign) BOOL isExpandedState;
@property (nonatomic, assign) NSUInteger indexOpenedElement;
@property (nonatomic, strong) APPaginalContainerViewPage *openedPage;
@end

NSUInteger kAPPaginalTableViewSection = 0;

#pragma mark -

@implementation APPaginalTableView {
    NSMutableArray *_elementViews;
    
    NSInteger _indexOfPinchingElement;
    CGFloat _initialHeightOfPinchingElement;
    CGPoint _offsetTableViewBeforePinching;
    UIEdgeInsets _insetTableView;
    
    BOOL _isUpdateInProgress;
    NSMutableIndexSet *_insertedIndexes;
    NSMutableIndexSet *_deletedIndexes;
}

@synthesize dataSource = _dataSource;
@synthesize delegate = _delegate;

@synthesize tableView = _tableView;
@synthesize paginalContainerView = _paginalContainerView;

@synthesize isExpandedState = _isExpandedState;
@synthesize indexOpenedElement = _indexOpenedElement;
@synthesize openedPage = _openedPage;
@dynamic numberOfElements;

#pragma mark - Methods

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        
        _elementViews = [NSMutableArray array];

        UIPinchGestureRecognizer *pinchRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinch:)];
        [self addGestureRecognizer:pinchRecognizer];

        _tableView = [[UITableView alloc] initWithFrame:self.bounds];
        _tableView.backgroundColor = [UIColor clearColor];
        _tableView.dataSource = self;
        _tableView.delegate = self;
        [self addSubview:_tableView];
        
        _insertedIndexes = [NSMutableIndexSet indexSet];
        _deletedIndexes = [NSMutableIndexSet indexSet];
        
        self.openedPage = nil;
    }
    return self;
}

- (void)reloadData
{
    _elementViews = [NSMutableArray array];
    
    NSUInteger numberOfElements = [self.dataSource numberOfElementsInPaginalTableView:self];
    
    for (NSUInteger index = 0; index < numberOfElements; index++) {
        APPaginalTableViewElement *view = [self createPaginalTableViewElementAtIndex:index];
        [_elementViews insertObject:view atIndex:index];
    }
    
    if (self.isExpandedState) {
        [self expandAllElementsExceptAtIndex:NSNotFound];
        [_paginalContainerView reloadData];
    }
    else {
        [self collapseAllElementsExceptAtIndex:NSNotFound];
        [_tableView reloadData];
    }
}

- (void)beginUpdates
{
    _isUpdateInProgress = YES;
    
    [_tableView beginUpdates];
    [_paginalContainerView beginUpdates];
    
    [_insertedIndexes removeAllIndexes];
    [_deletedIndexes removeAllIndexes];
}

- (void)insertElementAtIndex:(NSInteger)index
{
    NSAssert(_isUpdateInProgress, @"You must call beginUpdate before batch inserting new pages");
    
    [_insertedIndexes addIndex:index];
    
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:kAPPaginalTableViewSection];
    [_tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationTop];
    [_paginalContainerView insertPageAtIndex:index];
}

- (void)deleteElementAtIndex:(NSInteger)index
{
    NSAssert(_isUpdateInProgress, @"You must call beginUpdate before batch deleting pages");
    NSAssert(_elementViews[index] != nil, @"Element should exist for deleting");
    
    [_deletedIndexes addIndex:index];
    
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:kAPPaginalTableViewSection];
    [_tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    [_paginalContainerView deletePageAtIndex:index];
}

- (void)endUpdates
{
    if ([self hasChanges]) {
        NSMutableIndexSet *oldIndexes = [NSMutableIndexSet indexSetWithIndexesInRange:NSMakeRange(0, _elementViews.count)];
        NSMutableArray *newElementViews = [NSMutableArray array];
        __block NSUInteger newIndex = 0;
        
        [oldIndexes enumerateIndexesUsingBlock:^(NSUInteger index, BOOL *stop)
        {
            if (![_deletedIndexes containsIndex:index]) {
                
                while ([_insertedIndexes containsIndex:newIndex]) {
                    APPaginalTableViewElement *element = [self createPaginalTableViewElementAtIndex:newIndex];
                    [newElementViews insertObject:element atIndex:newIndex];
                    
                    [_insertedIndexes removeIndex:newIndex];
                    newIndex++;
                }
                
                APPaginalTableViewElement *element = _elementViews[index];
                [newElementViews insertObject:element atIndex:newIndex];
                
                newIndex++;
            }
        }];
        
        [_insertedIndexes enumerateIndexesUsingBlock:^(NSUInteger index, BOOL *stop)
        {
            APPaginalTableViewElement *element = [self createPaginalTableViewElementAtIndex:newIndex];
            [newElementViews insertObject:element atIndex:index];
        }];
        
        _elementViews = newElementViews;
    }
    
    [_tableView endUpdates];
    [_paginalContainerView endUpdates];
    
    _isUpdateInProgress = NO;
    
    [_insertedIndexes removeAllIndexes];
    [_deletedIndexes removeAllIndexes];
    
    if (self.isExpandedState) {
        self.openedPage = [_paginalContainerView currentPage];
    }
}

- (BOOL)hasChanges
{
    BOOL hasChanges = _insertedIndexes.count != 0 || _deletedIndexes.count != 0;
    return hasChanges;
}

- (void)openElementAtIndex:(NSUInteger)index completion:(void (^)(BOOL))completion animated:(BOOL)animated
{
    void (^internalCompletion)(BOOL) = ^(BOOL finished)
    {
        [self switchToPaginalPresentationWithSelectedIndex:index];
        
        self.isExpandedState = YES;
        
        if (completion) {
            completion(YES);
        }
    };
    
//    [self.tableView hideFixedHeaderAndFooterAnimated:animated];
    [self expandElementAtIndex:index completion:internalCompletion animated:animated];
}

- (void)closeElementAtIndex:(NSUInteger)index completion:(void (^)(BOOL))completion animated:(BOOL)animated
{
    _tableView.contentInset = UIEdgeInsetsMake(_tableView.frame.size.height, 0.f, _tableView.frame.size.height, 0.f);
    
    if (self.isInPaginalPresentation) {
        [self switchToTabularPresentation];
    }
    
    void (^internalCompletion)(BOOL) = ^(BOOL finished)
    {
        self.isExpandedState = NO;
        
        CGPoint offset = _tableView.contentOffset;
        _tableView.contentInset = _insetTableView;
        _tableView.contentOffset = offset;
        
        if (completion) {
            completion(YES);
        }
    };
    
//    [self.tableView showFixedHeaderAndFooterAnimated:animated];
    [self collapseElementAtindex:index completion:internalCompletion animated:animated];
}

- (void)closeElementWithCompletion:(void (^)(BOOL))completion animated:(BOOL)animated
{
    NSUInteger indexSelected = [_paginalContainerView indexOfCurrentPage];
    [self closeElementAtIndex:indexSelected completion:completion animated:animated];
}


- (void)scrollToElementAtIndex:(NSInteger)index completion:(void (^)(BOOL))completion animated:(BOOL)animated
{
    [_paginalContainerView scrollToPageAtIndex:index completion:completion animated:animated];
}

- (NSUInteger)indexOfElement:(APPaginalTableViewElement *)element
{
    NSUInteger index = [_elementViews indexOfObject:element];
    return index;
}

- (APPaginalTableViewElement *)elementAtIndex:(NSUInteger)index
{
    APPaginalTableViewElement *element = [_elementViews objectAtIndex:index];
    return element;
}

#pragma mark - Properties Methods

- (void)setDataSource:(id <APPaginalTableViewDataSource>)dataSource
{
    _dataSource = dataSource;
    
    if (_dataSource) {
        [self reloadData];
    }
}

- (NSUInteger)indexOpenedElement
{
    NSParameterAssert(_indexOpenedElement == NSNotFound || _indexOpenedElement == [_paginalContainerView indexOfCurrentPage]);
    return _indexOpenedElement;
}

- (NSUInteger)numberOfElements
{
    NSUInteger numberOfElements = _elementViews.count;
    return numberOfElements;
}

- (void)setOpenedPage:(APPaginalContainerViewPage *)openedPage
{
    if (openedPage != _openedPage) {
        _openedPage.focused = NO;
        _openedPage = openedPage;
        _openedPage.focused = YES;
    }
    
    self.indexOpenedElement = (_openedPage == nil)? NSNotFound : [_paginalContainerView indexOfCurrentPage];
}

#pragma mark - UIPinchGestureRecognizer

- (void)handlePinch:(UIPinchGestureRecognizer*)pinchRecognizer
{
    if (pinchRecognizer.state == UIGestureRecognizerStateBegan) {
        [self onPinchBegan:pinchRecognizer];
    }
    else if (pinchRecognizer.state == UIGestureRecognizerStateChanged) {
        [self onPinchChanged:pinchRecognizer];
    }
    else if ((pinchRecognizer.state == UIGestureRecognizerStateCancelled) || (pinchRecognizer.state == UIGestureRecognizerStateEnded)) {
        [self onPinchEnded:pinchRecognizer];
    }
}

- (void)onPinchBegan:(UIPinchGestureRecognizer*)pinchRecognizer
{
    _indexOfPinchingElement = NSNotFound;
    
    if (self.isExpandedState) {
        [self switchToTabularPresentation];
    }
    
    CGPoint pinchLocation = [pinchRecognizer locationInView:_tableView];
    NSIndexPath *indexPath = [_tableView indexPathForRowAtPoint:pinchLocation];
    
    if (indexPath != nil) {
        _indexOfPinchingElement = indexPath.row;
        
        APPaginalTableViewElement *view = _elementViews[_indexOfPinchingElement];
        _initialHeightOfPinchingElement = view.frame.size.height;
        _offsetTableViewBeforePinching = _tableView.contentOffset;
        
        _tableView.contentInset = UIEdgeInsetsMake(_tableView.frame.size.height, 0.f, _tableView.frame.size.height, 0.f);
    }
}

- (void)onPinchChanged:(UIPinchGestureRecognizer*)pinchRecognizer
{
    if (_indexOfPinchingElement == NSNotFound) {
        return;
    }
    
    CGFloat newHeight = _initialHeightOfPinchingElement * pinchRecognizer.scale;
    
    APPaginalTableViewElement *view = _elementViews[_indexOfPinchingElement];
    [view changeHeight:newHeight];
    
    [self updateCellsHeightsAnimated:NO];
    
    CGFloat diffHeight = ((newHeight > view.height) ? view.height : newHeight) - _initialHeightOfPinchingElement;
    CGFloat yOffsetTableView = _offsetTableViewBeforePinching.y + diffHeight / 2.f;
    _tableView.contentOffset = CGPointMake(_offsetTableViewBeforePinching.x, yOffsetTableView);
}

- (void)onPinchEnded:(UIPinchGestureRecognizer*)pinchRecognizer
{
    if (_indexOfPinchingElement == NSNotFound) {
        return;
    }
    
    CGPoint offset = _tableView.contentOffset;
    _tableView.contentInset = _insetTableView;
    _tableView.contentOffset = offset;
    
    APPaginalTableViewElement *view = _elementViews[_indexOfPinchingElement];
    CGFloat finalHeight = view.height;
    
    BOOL open = [self.delegate paginalTableView:self
                             openElementAtIndex:_indexOfPinchingElement
                             onChangeHeightFrom:_initialHeightOfPinchingElement
                                       toHeight:finalHeight];
    
    if (open) {
        [self openElementAtIndex:_indexOfPinchingElement completion:nil animated:YES];
    }
    else {
        [self closeElementAtIndex:_indexOfPinchingElement completion:nil animated:YES];
    }
}

#pragma mark - APHeadersFootersTableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSParameterAssert(section == kAPPaginalTableViewSection);
    
    NSUInteger numberOfRows = _elementViews.count;
    return numberOfRows;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = nil;
    if ([self.dataSource respondsToSelector:@selector(paginalTableView:cellContainerForElementAtIndex:)]) {
        cell = [self.dataSource paginalTableView:self cellContainerForElementAtIndex:indexPath.row];
    }
    else {
        cell =  [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@""];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.backgroundColor = [UIColor clearColor];
    }
    
    if (self.isInPaginalPresentation == NO) {
        APPaginalTableViewElement *view = _elementViews[indexPath.row];
        [cell.contentView addSubview:view];
    }
    
    return cell;
}

#pragma mark - APHeadersFootersTableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    APPaginalTableViewElement *element = _elementViews[indexPath.row];
    CGFloat height = element.frame.size.height;
    return height;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self.delegate respondsToSelector:@selector(paginalTableView:didSelectRowAtIndex:)]) {
        [self.delegate paginalTableView:self didSelectRowAtIndex:indexPath.row];
    }
}

#pragma mark - APPaginalContainerViewDataSource

- (NSInteger)numberOfPagesInPaginalContainerView:(APPaginalContainerView *)paginalContainerView
{
    NSUInteger number = _elementViews.count;
    return number;
}

- (APPaginalContainerViewPage *)paginalContainerView:(APPaginalContainerView *)paginalContainerView pageAtIndex:(NSUInteger)index
{
    APPaginalContainerViewPage *page = nil;
    if ([self.dataSource respondsToSelector:@selector(paginalTableView:pageContainerForElementAtIndex:)]) {
        page = [self.dataSource paginalTableView:self pageContainerForElementAtIndex:index];
    }
    else {
        page = [[APPaginalContainerViewPage alloc] init];
    }
    
    APPaginalTableViewElement *view = _elementViews[index];
    page.contentView = view;
    
    return page;
}

#pragma mark - APPaginalContainerViewDelegate

- (void)paginalContainerView:(APPaginalContainerView *)paginalContainerView didScrollToPageAtIndex:(NSInteger)index
{
    self.openedPage = [_paginalContainerView currentPage];
}

#pragma mark - Internal

- (void)switchToTabularPresentation
{
    NSUInteger indexSelectedPage = [_paginalContainerView indexOfCurrentPage];
    
    [self collapseAllElementsExceptAtIndex:indexSelectedPage];
    
    [_paginalContainerView removeFromSuperview];
    _paginalContainerView = nil;
    self.openedPage = nil;
    
    _tableView.alpha = 1.f;
    _tableView.scrollsToTop = YES;
    [_tableView reloadData];
    
    [self scrollToTopCellAtIndex:indexSelectedPage animated:NO];
}

- (void)switchToPaginalPresentationWithSelectedIndex:(NSUInteger)indexSelected
{
    [self expandAllElementsExceptAtIndex:indexSelected];
    
    _paginalContainerView = [[APPaginalContainerView alloc] initWithFrame:self.bounds];
    _paginalContainerView.dataSource = self;
    [_paginalContainerView scrollToPageAtIndex:indexSelected completion:nil animated:NO];
    
    _paginalContainerView.delegate = self;
    
    self.openedPage = [_paginalContainerView currentPage];
    
    [self addSubview:_paginalContainerView];
    
    _tableView.alpha = 0.f;
    _tableView.scrollsToTop = NO;
}

- (BOOL)isInPaginalPresentation
{
    BOOL isPaginal = _paginalContainerView != nil;
    return isPaginal;
}

- (void)expandAllElementsExceptAtIndex:(NSUInteger)indexExcept
{
    for (NSUInteger index = 0; index < _elementViews.count; index++) {
        if (index != indexExcept) {
            [_elementViews[index] expandAnimated:NO completion:nil];
        }
    }
}

- (void)collapseAllElementsExceptAtIndex:(NSUInteger)indexExcept
{
    for (NSUInteger index = 0; index < _elementViews.count; index++) {
        if (index != indexExcept) {
            [_elementViews[index] collapseAnimated:NO completion:nil];
        }
    }
}

- (void)expandElementAtIndex:(NSUInteger)index completion:(void (^)(BOOL))blockCompletion animated:(BOOL)animated
{
    APPaginalTableViewElement *view = _elementViews[index];
    [view expandAnimated:animated completion:blockCompletion];
    [self updateCellsHeightsAnimated:animated];
    
    [self scrollToTopCellAtIndex:index animated:animated];
}

- (void)collapseElementAtindex:(NSUInteger)index completion:(void (^)(BOOL))blockCompletion animated:(BOOL)animated
{
    APPaginalTableViewElement *view = _elementViews[index];
    [view collapseAnimated:animated completion:blockCompletion];
    [self updateCellsHeightsAnimated:animated];
    
    [self scrollToContentBoundsCellAtIndex:index animated:animated];
}

- (void)scrollToTopCellAtIndex:(NSUInteger)index animated:(BOOL)animated
{
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:kAPPaginalTableViewSection];
    CGRect frameOfCell = [_tableView rectForRowAtIndexPath:indexPath];
    CGPoint offsetCellToTop = CGPointMake(_tableView.contentOffset.x, frameOfCell.origin.y);
    
    void (^blockScrollToTop)(void) = ^(void)
    {
        _tableView.contentOffset = offsetCellToTop;
    };
    
    if (animated) {
        [UIView animateWithDuration:kAPPaginalTableViewElementAnimationDuration animations:blockScrollToTop];
    }
    else {
        blockScrollToTop();
    }
}

- (void)scrollToContentBoundsCellAtIndex:(NSInteger)indexSelected animated:(BOOL)animated
{
    CGFloat visibleTableHeight = _tableView.frame.size.height - _insetTableView.top - _insetTableView.bottom;
    
    NSUInteger indexofLastCell = [_tableView numberOfRowsInSection:kAPPaginalTableViewSection] - 1;
    APPaginalTableViewElement *lastElement = (APPaginalTableViewElement *)_elementViews[indexofLastCell];
    
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:indexofLastCell inSection:kAPPaginalTableViewSection];
    CGFloat heightOfContent = [_tableView rectForRowAtIndexPath:indexPath].origin.y + lastElement.collapsedHeight;
    
    CGPoint newContentOffset = CGPointZero;
    
    if (visibleTableHeight > heightOfContent) {
        newContentOffset = CGPointMake(_tableView.contentOffset.x, 0.f - _insetTableView.top);
    }
    else {
        CGFloat maxContentOffset = heightOfContent - visibleTableHeight;
        CGFloat percentOfMaxOffset = MIN(1.f, indexSelected / (CGFloat)(indexofLastCell - 2));
        newContentOffset = CGPointMake(_tableView.contentOffset.x, maxContentOffset * percentOfMaxOffset - _insetTableView.top);
    }
    
    void (^blockScrollToBorder)(void) = ^(void)
    {
        _tableView.contentOffset = newContentOffset;
    };
    
    if (animated) {
        [UIView animateWithDuration:kAPPaginalTableViewElementAnimationDuration animations:blockScrollToBorder];
    }
    else {
        blockScrollToBorder();
    }
}

- (void)updateCellsHeightsAnimated:(BOOL)animated
{
    BOOL animationsEnabled = [UIView areAnimationsEnabled];
    [UIView setAnimationsEnabled:animated];
    [_tableView beginUpdates];
    [_tableView endUpdates];
    [UIView setAnimationsEnabled:animationsEnabled];
}

- (APPaginalTableViewElement *)createPaginalTableViewElementAtIndex:(NSUInteger)index
{
    APPaginalTableViewElement *view = nil;
    
    UIView *expandedView = [self.dataSource paginalTableView:self expandedViewAtIndex:index];
    UIView *collapsedView = [self.dataSource paginalTableView:self collapsedViewAtIndex:index];
    
    if (self.isExpandedState) {
        view = [[APPaginalTableViewElement alloc] initExpandedWithCollapsedView:collapsedView expandedView:expandedView];
    }
    else {
        view = [[APPaginalTableViewElement alloc] initCollapsedWithCollapsedView:collapsedView expandedView:expandedView];
    }
    
    return view;
}

@end

