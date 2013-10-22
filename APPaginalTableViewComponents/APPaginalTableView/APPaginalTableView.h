//
//  APPaginalTableView.h
//  BuyMeAPie
//
//  Created by Antol Peshkov on 21.08.13.
//  Copyright (c) 2013 BuyMeAPie. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "APPaginalTableViewElement.h"

@class APPaginalTableView;
@class APPaginalContainerView;
@class APPaginalContainerViewPage;

#pragma mark -

@protocol APPaginalTableViewDataSource <NSObject>
- (NSUInteger)numberOfElementsInPaginalTableView:(APPaginalTableView *)paginalTableView;
- (UIView *)paginalTableView:(APPaginalTableView *)paginalTableView collapsedViewAtIndex:(NSUInteger)index;
- (UIView *)paginalTableView:(APPaginalTableView *)paginalTableView expandedViewAtIndex:(NSUInteger)index;
@optional
- (UITableViewCell *)paginalTableView:(APPaginalTableView *)paginalTableView cellContainerForElementAtIndex:(NSUInteger)index;
- (APPaginalContainerViewPage *)paginalTableView:(APPaginalTableView *)paginalTableView pageContainerForElementAtIndex:(NSUInteger)index;
@end

#pragma mark -

@protocol APPaginalTableViewDelegate <NSObject>
@optional
- (BOOL)paginalTableView:(APPaginalTableView *)paginalTableView
      openElementAtIndex:(NSUInteger)index
      onChangeHeightFrom:(CGFloat)initialHeight
                toHeight:(CGFloat)finalHeight;

- (void)paginalTableView:(APPaginalTableView *)paginalTableView didSelectRowAtIndex:(NSUInteger)index;
- (void)paginalTableView:(APPaginalTableView *)paginalTableView deleteRowAtIndex:(NSUInteger)index;

@end

#pragma mark -

@interface APPaginalTableView : UIView

@property (nonatomic, assign) id<APPaginalTableViewDataSource> dataSource;
@property (nonatomic, assign) id<APPaginalTableViewDelegate> delegate;

@property (nonatomic, readonly) UITableView *tableView;
@property (nonatomic, readonly) APPaginalContainerView *paginalContainerView;

@property (nonatomic, readonly) BOOL isExpandedState;
@property (nonatomic, readonly) NSUInteger indexOpenedElement;
@property (nonatomic, readonly) NSUInteger numberOfElements;

#pragma mark - Methods

- (void)reloadData;

- (void)beginUpdates;
- (void)insertElementAtIndex:(NSInteger)index;
- (void)deleteElementAtIndex:(NSInteger)index;
- (void)endUpdates;

- (void)openElementAtIndex:(NSUInteger)index completion:(void(^)(BOOL))completion animated:(BOOL)animated;
- (void)closeElementWithCompletion:(void(^)(BOOL))completion animated:(BOOL)animated;

- (void)scrollToElementAtIndex:(NSInteger)index completion:(void(^)(BOOL))completion animated:(BOOL)animated;

- (NSUInteger)indexOfElement:(APPaginalTableViewElement *)element;
- (APPaginalTableViewElement *)elementAtIndex:(NSUInteger)index;

@end
