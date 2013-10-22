//
//  APPaginalContainerView.h
//  BuyMeAPie
//
//  Created by Antol Peshkov on 22.08.13.
//  Copyright (c) 2013 BuyMeAPie. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "APPaginalContainerViewPage.h"

@class APPaginalContainerView;

#pragma mark -

@protocol APPaginalContainerViewDataSource <NSObject>
- (NSInteger)numberOfPagesInPaginalContainerView:(APPaginalContainerView *)paginalContainerView;
- (APPaginalContainerViewPage *)paginalContainerView:(APPaginalContainerView *)paginalContainerView pageAtIndex:(NSUInteger)index;
@end

#pragma mark -

@protocol APPaginalContainerViewDelegate <NSObject>
@optional
- (void)paginalContainerView:(APPaginalContainerView *)paginalContainerView willScrollFromPageAtIndex:(NSInteger)index;
- (void)paginalContainerView:(APPaginalContainerView *)paginalContainerView didScrollToPageAtIndex:(NSInteger)index;
@end

#pragma mark -

@interface APPaginalContainerView : UIView

@property (nonatomic, assign) id<APPaginalContainerViewDataSource> dataSource;
@property (nonatomic, assign) id<APPaginalContainerViewDelegate> delegate;

@property (nonatomic, readonly) NSInteger numberOfPages;

- (void)reloadData;

- (void)beginUpdates;
- (void)insertPageAtIndex:(NSInteger)index;
- (void)deletePageAtIndex:(NSInteger)index;
- (void)endUpdates;

- (void)scrollToPageAtIndex:(NSInteger)index completion:(void(^)(BOOL))completion animated:(BOOL)animated;

- (NSInteger)indexOfCurrentPage;
- (APPaginalContainerViewPage *)currentPage;

- (NSInteger)indexOfPage:(APPaginalContainerViewPage *)page;
- (APPaginalContainerViewPage *)pageAtIndex:(NSInteger)index;

@end
