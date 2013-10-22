//
//  APPaginalContainerView.m
//  BuyMeAPie
//
//  Created by Antol Peshkov on 22.08.13.
//  Copyright (c) 2013 BuyMeAPie. All rights reserved.
//

#import "APPaginalContainerView.h"

#pragma mark -

@interface APPaginalContainerViewScrollView : UIScrollView
@property (nonatomic, assign) UIEdgeInsets panRecognizeInsets;
@end

@implementation APPaginalContainerViewScrollView
@synthesize panRecognizeInsets = _panRecognizeInsets;
- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    BOOL shouldBegin = YES;
    
    if (gestureRecognizer == self.panGestureRecognizer) {
        CGPoint touchLocation = [self.panGestureRecognizer locationInView:gestureRecognizer.view];
        
        CGRect panRecognizeFrame = UIEdgeInsetsInsetRect(self.bounds, self.panRecognizeInsets);
        shouldBegin = !CGRectContainsPoint(panRecognizeFrame, touchLocation);
    }
    
    return shouldBegin;
}
@end

#pragma mark -

@interface APPaginalContainerView () < UIScrollViewDelegate,
                                       UIGestureRecognizerDelegate >
@property (nonatomic, assign) CGPoint pageSizeRelative;
@property (nonatomic, readonly) CGSize pageSizeAbsolute;
@end

#pragma mark -

@implementation APPaginalContainerView {
    APPaginalContainerViewScrollView *_scrollView;
    NSMutableArray *_pages;
    
    BOOL _isUpdateInProgress;
    NSMutableIndexSet *_insertedIndexes;
    NSMutableIndexSet *_deletedIndexes;
    
    APPaginalContainerViewPage *_tempCurrentPage;
}

#pragma mark - Properties

@synthesize dataSource = _dataSource;
@synthesize delegate = _delegate;

@synthesize pageSizeRelative = _pageSizeRelative;
@dynamic pageSizeAbsolute;

#pragma mark - UIView Override

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _scrollView = [[APPaginalContainerViewScrollView alloc] initWithFrame:self.bounds];
        _scrollView.panRecognizeInsets = UIEdgeInsetsMake(0, 30, 0, 25);
        _scrollView.delegate = self;
        _scrollView.pagingEnabled = YES;
        _scrollView.showsVerticalScrollIndicator = NO;
        _scrollView.showsHorizontalScrollIndicator = NO;
        _scrollView.clipsToBounds = NO;
        _scrollView.alwaysBounceHorizontal = YES;
        _scrollView.scrollsToTop = NO;
        [self addSubview:_scrollView];
        
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        
        _pageSizeRelative = CGPointMake(1.f, 1.f);
        
        _pages = [NSMutableArray array];
        
        _insertedIndexes = [NSMutableIndexSet indexSet];
        _deletedIndexes = [NSMutableIndexSet indexSet];
    }
    return self;
}

#pragma mark - Properties Override

- (void)setDataSource:(id <APPaginalContainerViewDataSource>)dataSource
{
    _dataSource = dataSource;
    
    if (_dataSource) {
        [self reloadData];
    }
}

- (NSInteger)numberOfPages
{
    return _pages.count;
}

- (void)setPageSizeRelative:(CGPoint)pageSizeRelative
{
    NSParameterAssert(CGRectContainsPoint(CGRectMake(0.f, 0.f, 1.f, 1.f), pageSizeRelative));
    
    _pageSizeRelative = pageSizeRelative;
}

- (CGSize)pageSizeAbsolute
{
    CGSize pageSizeAbsolute = CGSizeMake(ceilf(_scrollView.bounds.size.width * self.pageSizeRelative.x),
                                         ceilf(_scrollView.bounds.size.height * self.pageSizeRelative.y));
    return pageSizeAbsolute;
}

#pragma mark - Methods

- (void)reloadData
{
    [self deleteAllPages];
    
    NSInteger numPages = [self.dataSource numberOfPagesInPaginalContainerView:self];
    
    for (NSInteger i = 0; i < numPages; i++) {
        APPaginalContainerViewPage *newPage = [self.dataSource paginalContainerView:self pageAtIndex:i];
        
        [_pages insertObject:newPage atIndex:i];
        [_scrollView addSubview:newPage];
    }
    
    [self layoutPages];
}

- (void)beginUpdates
{
    _isUpdateInProgress = YES;
    
    [_insertedIndexes removeAllIndexes];
    [_deletedIndexes removeAllIndexes];
    
    _tempCurrentPage = [self currentPage];
}

- (void)insertPageAtIndex:(NSInteger)index
{
    NSAssert(_isUpdateInProgress, @"You must call beginUpdate before inserting new pages");
    
    [_insertedIndexes addIndex:index];
}

- (void)deletePageAtIndex:(NSInteger)index
{
    NSAssert(_isUpdateInProgress, @"You must call beginUpdate before deleting pages");
    NSAssert(_pages[index] != nil, @"Element should exist for deleting");
    
    [_deletedIndexes addIndex:index];
}

- (void)endUpdates
{
    if ([self hasChanges]) {
        NSMutableIndexSet *oldlIndexes = [NSMutableIndexSet indexSetWithIndexesInRange:NSMakeRange(0, _pages.count)];
        NSMutableArray *newPages = [NSMutableArray array];
        
        [_deletedIndexes enumerateIndexesUsingBlock:^(NSUInteger index, BOOL *stop)
        {
            [_pages[index] removeFromSuperview];
        }];
        
        __block NSUInteger newIndex = 0;
        [oldlIndexes enumerateIndexesUsingBlock:^(NSUInteger index, BOOL *stop)
        {
            if (![_deletedIndexes containsIndex:index]) {
                
                while ([_insertedIndexes containsIndex:newIndex]) {
                    APPaginalContainerViewPage *newPage = [self.dataSource paginalContainerView:self pageAtIndex:newIndex];
                    [newPages insertObject:newPage atIndex:newIndex];
                    [_scrollView addSubview:newPage];
                    
                    [_insertedIndexes removeIndex:newIndex];
                    newIndex++;
                }
                
                APPaginalContainerViewPage *page = _pages[index];
                [newPages insertObject:page atIndex:newIndex];
                
                newIndex++;
            }
        }];
        
        [_insertedIndexes enumerateIndexesUsingBlock:^(NSUInteger index, BOOL *stop)
        {
            APPaginalContainerViewPage *newPage = [self.dataSource paginalContainerView:self pageAtIndex:index];
            [newPages insertObject:newPage atIndex:index];
            [_scrollView addSubview:newPage];
        }];
        
        _pages = newPages;
    }
    
    _isUpdateInProgress = NO;
    
    [_insertedIndexes removeAllIndexes];
    [_deletedIndexes removeAllIndexes];
    
    [self layoutPages];
    
    _scrollView.contentOffset = [self offsetForPageAtIndex:[self indexOfPage:_tempCurrentPage]];
    _tempCurrentPage = nil;
}

- (BOOL)hasChanges
{
    BOOL hasChanges = _insertedIndexes.count != 0 || _deletedIndexes.count != 0;
    return hasChanges;
}

- (void)scrollToPageAtIndex:(NSInteger)index completion:(void (^)(BOOL))completion animated:(BOOL)animated
{
    [self onBeginScrolling];
    
    CGPoint offset = [self offsetForPageAtIndex:index];
    
    void (^blockAnimation)(void) = ^(void)
    {
        _scrollView.contentOffset = offset;
	};
    
	void (^blockCompletion)(BOOL) = ^(BOOL finished)
    {
        [self onEndScrolling];
        
        if (completion) {
            completion(finished);
        }
	};
    
    if (animated) {
        [UIView animateWithDuration:0.25 animations:blockAnimation completion:blockCompletion];
    }
    else {
        blockAnimation();
        blockCompletion(YES);
    }
}

- (NSInteger)indexOfCurrentPage
{
    NSInteger index = [self indexOfPageForOffset:_scrollView.contentOffset];
    return index;
}

- (APPaginalContainerViewPage *)currentPage
{
    APPaginalContainerViewPage *currentPage = [self pageAtIndex:self.indexOfCurrentPage];
    return currentPage;
}

- (NSInteger)indexOfPage:(APPaginalContainerViewPage *)page
{
    NSParameterAssert(page);
    NSInteger index = [_pages indexOfObject:page];
    return index;
}

- (APPaginalContainerViewPage *)pageAtIndex:(NSInteger)index
{
    NSParameterAssert((index >= 0 && index < self.numberOfPages) || (index == NSNotFound));
    
    APPaginalContainerViewPage *page = nil;
    
    if (index != NSNotFound) {
        page = [_pages objectAtIndex:index];
        NSParameterAssert(page);
    }
    
    return page;
}

- (NSInteger)indexOfPageForOffset:(CGPoint)offset
{
    NSInteger index = roundf(offset.x / self.pageSizeAbsolute.width);
    index = MAX(0, MIN(index, self.numberOfPages - 1));
    return index;
}

- (CGPoint)offsetForPageAtIndex:(NSInteger)index
{
    NSParameterAssert((0 <= index && index < self.numberOfPages) || (index == NSNotFound));
    
    CGPoint offset = (index == NSNotFound)? CGPointZero : CGPointMake(self.pageSizeAbsolute.width * index, 0.f);
    
    NSParameterAssert(offset.x <= _scrollView.contentSize.width && offset.y <= _scrollView.contentSize.height);
    return offset;
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
	[self onBeginScrolling];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    [self onEndScrolling];
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView
{
    [self onEndScrolling];
}

#pragma mark - Internal

- (void)deleteAllPages
{
    [_pages makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [_pages removeAllObjects];
}

- (void)layoutPages
{
    _scrollView.contentSize = CGSizeMake(self.numberOfPages * self.pageSizeAbsolute.width, self.pageSizeAbsolute.height);
    
    for (NSUInteger i = 0; i < _pages.count; i++) {
        APPaginalContainerViewPage *page = [_pages objectAtIndex:i];
        page.frame = (CGRect){.origin = CGPointMake(self.pageSizeAbsolute.width * i, 0.f), .size = self.pageSizeAbsolute};
    }
}

- (void)onBeginScrolling
{
    if ([self.delegate respondsToSelector:@selector(paginalContainerView:willScrollFromPageAtIndex:)]) {
        [self.delegate paginalContainerView:self willScrollFromPageAtIndex:[self indexOfCurrentPage]];
    }
}

- (void)onEndScrolling
{
    if ([self.delegate respondsToSelector:@selector(paginalContainerView:didScrollToPageAtIndex:)]) {
        [self.delegate paginalContainerView:self didScrollToPageAtIndex:[self indexOfCurrentPage]];
    }
}

@end
