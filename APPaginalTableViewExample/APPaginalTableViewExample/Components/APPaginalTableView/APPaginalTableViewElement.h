//
//  APPaginalTableViewElement.h
//  BuyMeAPie
//
//  Created by Antol Peshkov on 21.08.13.
//  Copyright (c) 2013 BuyMeAPie. All rights reserved.
//

#import <UIKit/UIKit.h>

extern const CGFloat kAPPaginalTableViewElementAnimationDuration;

#pragma mark -

@interface APPaginalTableViewElement : UIView

#pragma mark - Properties

@property (nonatomic, readonly) CGFloat height;
@property (nonatomic, readonly) UIView *currentView;

@property (nonatomic, readonly) UIView *collapsedView;
@property (nonatomic, readonly) UIView *expandedView;

@property (nonatomic, assign) CGFloat collapsedHeight;
@property (nonatomic, assign) CGFloat expandedHeight;

#pragma mark - Methods

- (id)initCollapsedWithCollapsedView:(UIView *)collapsedView expandedView:(UIView *)expandedView;
- (id)initExpandedWithCollapsedView:(UIView *)collapsedView expandedView:(UIView *)expandedView;

- (void)changeHeight:(CGFloat)height;

- (void)expandAnimated:(BOOL)animated completion:(void (^)(BOOL finished))completion;
- (void)collapseAnimated:(BOOL)animated completion:(void (^)(BOOL finished))completion;

@end
