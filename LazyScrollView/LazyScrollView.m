//
//  LazyScrollView.m
//  LazyScrollView
//
//  Created by Zhang Qing on 16/11/30.
//  Copyright © 2016年 Tsing. All rights reserved.
//

#import "LazyScrollView.h"
#import <objc/runtime.h>

#define LAZY_TOP self.contentOffset.y
#define LAZY_BOTTOM self.contentOffset.y + self.bounds.size.height
#define BUFFER 20

@interface LazyScrollView () <UIScrollViewDelegate>
{
    
}
@property (nonatomic, strong, nullable) NSMutableDictionary<NSString *, NSMutableArray *> *reuseViews;
@property (nonatomic, copy, nullable) NSMutableArray *allRects;
@property (nonatomic, assign) NSUInteger numberOfItems;
@property (nonatomic, strong, nullable) NSMutableDictionary<NSString *,Class> *registerClass;
@property (nonatomic, copy) NSArray *ascendingMinEdgeRects;
@property (nonatomic, copy) NSArray *descendingMaxEdgeRects;
@property (nonatomic, copy) NSMutableArray<__kindof UIView *> *visiableViews;
@end

@implementation LazyScrollView
- (instancetype)init {
    self = [super init];
    if (self) {
        self.delegate = self;
    }
    return self;
}
- (void)layoutSubviews {
    [super layoutSubviews];
    
}
- (void)willMoveToSuperview:(UIView *)newSuperview {
    [super willMoveToSuperview:newSuperview];
    [self updateAllRects];
}
- (void)reloadData {
    
    [self.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [self.visiableViews removeAllObjects];
    
    [self updateAllRects];
    
    NSMutableArray *visibleViews = [self visiableViewModels];
}

- (void)enqueueReusableView:(UIView *)view {
    if (!view.reuseIdentifier) {
        return;
    }
    NSString *identifier = view.reuseIdentifier;
    NSMutableArray *reuseArray = self.reuseViews[identifier];
    if (!reuseArray) {
        reuseArray = [NSMutableArray array];
        [self.reuseViews setValue:reuseArray forKey:identifier];
    }
    [reuseArray addObject:view];
}
- (UIView *)dequeueReusableItemWithIdentifier:(NSString *)identifier {
    if (!identifier) {
        return nil;
    }
    UIView *view = nil;
    NSMutableArray *reuseArray = self.reuseViews[identifier];
    if (reuseArray && reuseArray.lastObject) {
        view = reuseArray.lastObject;
    }
    if (view) {
        view.hidden = NO;
        [self.reuseViews removeObjectForKey:identifier];
        return view;
    }
    else {
        Class viewClass = [self.registerClass objectForKey:identifier];
        view = [viewClass new];
        view.reuseIdentifier = identifier;
        return view;
    }
}

#pragma mark -
- (CGFloat)minEdgeOffset {
    CGFloat min = _direction == LazyScrollViewDirectionVertical ? self.contentOffset.y : self.contentOffset.x;
    return min - 20;
}
- (CGFloat)maxEdgeOffset {
    CGFloat max = _direction == LazyScrollViewDirectionVertical ? self.contentOffset.y + CGRectGetHeight(self.bounds) : self.contentOffset.x + CGRectGetWidth(self.bounds);
    return max + 20;
}
- (NSUInteger)findIndexWithMinEdge:(CGFloat)minEdge {
    return 0;
}
- (NSUInteger)findIndexWithMaxEdge:(CGFloat)maxEdge {
    return 0;
}
- (NSArray *)visiableViewModels {
    NSMutableSet *ascendSet = [self ascendYAndFindGreaterThanTop];
    
    NSMutableSet *descendSet = [self descendYAppendHeightAndFindLessThanBottom];
    
    [ascendSet intersectSet:descendSet];
    
    NSMutableArray *result = [NSMutableArray arrayWithArray: ascendSet.allObjects];
    return result;
}
- (void)updateAllRects {
    [self.allRects removeAllObjects];
    _numberOfItems = [self.dataSource numberOfItemInScrollView:self];
    
    for (NSInteger index = 0; index < _numberOfItems; ++ index) {
        LSVRectModel *model = [self.dataSource scrollView:self rectModelAtIndex:index];
        [self.allRects addObject:model];
    }
    LSVRectModel *model = self.allRects.lastObject;
    self.contentSize = CGSizeMake(self.bounds.size.width, model.absRect.origin.y + model.absRect.size.height + 15);
    
}
- (NSMutableSet *)descendYAppendHeightAndFindLessThanBottom {
    
    NSArray *descendingEdgeArray =
    [self.allRects sortedArrayUsingComparator:^NSComparisonResult(LSVRectModel *obj1, LSVRectModel *obj2) {
        return CGRectGetMaxY(obj1.absRect) < CGRectGetMaxY(obj2.absRect) ? NSOrderedDescending : NSOrderedAscending;
    }];
    
    NSInteger index = descendingEdgeArray.count / 2;
    LSVRectModel *model = descendingEdgeArray[index];
    while (model.absRect.origin.y > 300 && index >= 0) {
        index /= 2;
        model = descendingEdgeArray[index];
    }
    
    NSArray *array = [descendingEdgeArray subarrayWithRange:NSMakeRange(index, descendingEdgeArray.count)];
    return [NSMutableSet setWithArray:array];
}
- (NSMutableSet *)ascendYAndFindGreaterThanTop {
    
    NSArray *ascendingEdgeArray =
    [self.allRects sortedArrayUsingComparator:^NSComparisonResult(LSVRectModel *obj1, LSVRectModel *obj2) {
        return obj1.absRect.origin.y > obj2.absRect.origin.y ? NSOrderedDescending : NSOrderedAscending;
    }];
    
    NSInteger index = ascendingEdgeArray.count / 2;
    LSVRectModel *model = ascendingEdgeArray[index];
    while (model.absRect.origin.y > 300 && index >= 0) {
        index /= 2;
        model = ascendingEdgeArray[index];
    }
    
    NSArray *array = [ascendingEdgeArray subarrayWithRange:NSMakeRange(index, ascendingEdgeArray.count)];
    return [NSMutableSet setWithArray:array];
}
#pragma mark -
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    
}

#pragma mark - getter
- (NSMutableDictionary *)reuseViews {
    if (!_reuseViews) {
        _reuseViews = @{}.mutableCopy;
    }
    return _reuseViews;
}
- (NSMutableArray *)allRects {
    if (!_allRects) {
        _allRects = @[].mutableCopy;
    }
    return _allRects;
}
- (NSMutableDictionary *)registerClass {
    if (!_registerClass) {
        _registerClass = @{}.mutableCopy;
    }
    return _registerClass;
}
- (NSMutableArray *)visiableViews {
    if (!_visiableViews) {
        _visiableViews = @[].mutableCopy;
    }
    return _visiableViews;
}
@end

static char kAssociatedObjectKeyLsvID;
static char kAssociatedObjectKeyReuseIdentifier;

@implementation UIView (LSV)
- (NSString *)lsvID {
    return objc_getAssociatedObject(self, &kAssociatedObjectKeyLsvID);
}
- (void)setLsvID:(NSString *)lsvID {
    objc_setAssociatedObject(self, &kAssociatedObjectKeyLsvID, lsvID, OBJC_ASSOCIATION_COPY_NONATOMIC);
}
- (NSString *)reuseIdentifier {
    return objc_getAssociatedObject(self, &kAssociatedObjectKeyReuseIdentifier);
}
- (void)setReuseIdentifier:(NSString *)reuseIdentifier {
    objc_setAssociatedObject(self, &kAssociatedObjectKeyReuseIdentifier, reuseIdentifier, OBJC_ASSOCIATION_COPY_NONATOMIC);
}
@end

@implementation LSVRectModel

@end


