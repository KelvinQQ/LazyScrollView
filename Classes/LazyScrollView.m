//
//  LazyScrollView.m
//  LazyScrollView
//
//  Created by Zhang Qing on 16/11/30.
//  Copyright © 2016年 Tsing. All rights reserved.
//

#import "LazyScrollView.h"
#import <objc/runtime.h>

CGFloat const kBufferSize = 20;

@interface LazyScrollView () <UIScrollViewDelegate>
{
    
}
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSMutableSet *> *reuseViews;
@property (nonatomic, strong) NSMutableSet<__kindof UIView *> *visibleViews;
@property (nonatomic, strong) NSMutableArray *allRects;
@property (nonatomic, assign) NSUInteger numberOfItems;
@property (nonatomic, strong) NSMutableDictionary<NSString *, Class> *registerClass;
@end

@implementation LazyScrollView
@dynamic delegate;

- (void)setDataSource:(id<LazyScrollViewDataSource>)dataSource {
    if (dataSource != _dataSource) {
        _dataSource = dataSource;
    }
    if (_dataSource) {
        [self reloadData];
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    // TOOD: 此处算法待优化
    NSMutableArray *newVisibleViews = [self visiableViewModels].mutableCopy;
    NSMutableArray *newVisibleLsvIds = [newVisibleViews valueForKey:@"lsvId"];
    NSMutableArray *removeViews = [NSMutableArray array];
    for (UIView *view in self.visibleViews) {
        if (![newVisibleLsvIds containsObject:view.lsvId]) {
            [removeViews addObject:view];
        }
    }
    for (UIView *view in removeViews) {
        [self.visibleViews removeObject:view];
        [self enqueueReusableView:view];
        [view removeFromSuperview];
    }
    
    NSMutableArray *alreadyVisibles = [self.visibleViews valueForKey:@"lsvId"];
    
    for (LSVRectModel *model in newVisibleViews) {
        if ([alreadyVisibles containsObject:model.lsvId]) {
            continue;
        }
        UIView *view = [self.dataSource scrollView:self itemByLsvId:model.lsvId];
        view.frame = model.absRect;
        view.lsvId = model.lsvId;
        
        [self.visibleViews addObject:view];
        [self addSubview:view];
    }
    
}

- (void)reloadData {
    
    [self.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [self.visibleViews removeAllObjects];
    
    [self updateAllRects];
}

- (void)enqueueReusableView:(UIView *)view {
    if (!view.reuseIdentifier) {
        return;
    }
    NSString *identifier = view.reuseIdentifier;
    NSMutableSet *reuseSet = self.reuseViews[identifier];
    if (!reuseSet) {
        reuseSet = [NSMutableSet set];
        [self.reuseViews setValue:reuseSet forKey:identifier];
    }
    [reuseSet addObject:view];
}
- (UIView *)dequeueReusableItemWithIdentifier:(NSString *)identifier {
    if (!identifier) {
        return nil;
    }
    NSMutableSet *reuseSet = self.reuseViews[identifier];
    UIView *view = [reuseSet anyObject];
    if (view) {
        [reuseSet removeObject:view];
        return view;
    }
    else {
        Class viewClass = [self.registerClass objectForKey:identifier];
        view = [viewClass new];

        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapItemAction:)];
        [view addGestureRecognizer:tap];
        view.userInteractionEnabled = YES;
        
        view.reuseIdentifier = identifier;
        return view;
    }
}

- (void)registerClass:(Class)viewClass forViewReuseIdentifier:(NSString *)identifier {
    [self.registerClass setValue:viewClass forKey:identifier];
}

#pragma mark -
- (CGFloat)minEdgeOffset {
    CGFloat min = self.contentOffset.y;
    return MAX(min - kBufferSize, 0);
}
- (CGFloat)maxEdgeOffset {
    CGFloat max = self.contentOffset.y + CGRectGetHeight(self.bounds);
    return MIN(max + kBufferSize, self.contentSize.height);
}
- (NSMutableSet *)findSetWithMinEdge:(CGFloat)minEdge {
    NSArray *ascendingEdgeArray =
    [self.allRects sortedArrayUsingComparator:^NSComparisonResult(LSVRectModel *obj1, LSVRectModel *obj2) {
        return CGRectGetMinY(obj1.absRect) > CGRectGetMinY(obj2.absRect) ? NSOrderedDescending : NSOrderedAscending;
    }];
    
    // TOOD: 此处待优化
    // 二分法
    NSInteger minIndex = 0;
    NSInteger maxIndex = ascendingEdgeArray.count - 1;
    NSInteger midIndex = (minIndex + maxIndex) / 2;
    LSVRectModel *model = ascendingEdgeArray[midIndex];
    while (minIndex < maxIndex - 1) {
        if (CGRectGetMinY(model.absRect) > minEdge) {
            maxIndex = midIndex;
        }
        else {
            minIndex = midIndex;
        }
        midIndex = (minIndex + maxIndex) / 2;
        model = ascendingEdgeArray[midIndex];
    }
    midIndex = MAX(midIndex - 1, 0);
    NSArray *array = [ascendingEdgeArray subarrayWithRange:NSMakeRange(midIndex, ascendingEdgeArray.count - midIndex)];
    return [NSMutableSet setWithArray:array];
}
- (NSMutableSet *)findSetWithMaxEdge:(CGFloat)maxEdge {
    
    NSArray *descendingEdgeArray =
    [self.allRects sortedArrayUsingComparator:^NSComparisonResult(LSVRectModel *obj1, LSVRectModel *obj2) {
        return CGRectGetMaxY(obj1.absRect) < CGRectGetMaxY(obj2.absRect) ? NSOrderedDescending : NSOrderedAscending;
    }];
    // TOOD: 此处待优化
    // 二分法
    NSInteger minIndex = 0;
    NSInteger maxIndex = descendingEdgeArray.count - 1;
    NSInteger midIndex = (minIndex + maxIndex) / 2;
    LSVRectModel *model = descendingEdgeArray[midIndex];
    while (minIndex < maxIndex - 1) {
        if (CGRectGetMaxY(model.absRect) < maxEdge) {
            maxIndex = midIndex;
        }
        else {
            minIndex = midIndex;
        }
        midIndex = (minIndex + maxIndex) / 2;
        model = descendingEdgeArray[midIndex];
    }
    midIndex = MAX(midIndex - 1, 0);
    NSArray *array = [descendingEdgeArray subarrayWithRange:NSMakeRange(midIndex, descendingEdgeArray.count - midIndex)];
    return [NSMutableSet setWithArray:array];
}
- (NSArray *)visiableViewModels {
    NSMutableSet *ascendSet = [self findSetWithMinEdge:[self minEdgeOffset]];
    NSMutableSet *descendSet = [self findSetWithMaxEdge:[self maxEdgeOffset]];
    [ascendSet intersectSet:descendSet];
    NSMutableArray *result = [NSMutableArray arrayWithArray:ascendSet.allObjects];
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
    self.contentSize = CGSizeMake(CGRectGetWidth(self.bounds), CGRectGetMaxY(model.absRect));
}

- (void)tapItemAction:(UITapGestureRecognizer *)gesture {
    if ([self.delegate respondsToSelector:@selector(scrollView:didClickItemAtLsvId:)]) {
        UIView *view = [gesture view];
        [self.delegate scrollView:self didClickItemAtLsvId:view.lsvId];
    }
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
- (NSMutableSet *)visibleViews {
    if (!_visibleViews) {
        _visibleViews = [NSMutableSet set];
    }
    return _visibleViews;
}
@end

static char kAssociatedObjectKeylsvId;
static char kAssociatedObjectKeyReuseIdentifier;

@implementation UIView (LSV)
- (NSString *)lsvId {
    return objc_getAssociatedObject(self, &kAssociatedObjectKeylsvId);
}
- (void)setLsvId:(NSString *)lsvId {
    objc_setAssociatedObject(self, &kAssociatedObjectKeylsvId, lsvId, OBJC_ASSOCIATION_COPY_NONATOMIC);
}
- (NSString *)reuseIdentifier {
    return objc_getAssociatedObject(self, &kAssociatedObjectKeyReuseIdentifier);
}
- (void)setReuseIdentifier:(NSString *)reuseIdentifier {
    objc_setAssociatedObject(self, &kAssociatedObjectKeyReuseIdentifier, reuseIdentifier, OBJC_ASSOCIATION_COPY_NONATOMIC);
}
@end

@implementation LSVRectModel
+ (instancetype)modelWithRect:(CGRect)rect lsvId:(NSString *)lsvId {
    LSVRectModel *model = [[LSVRectModel alloc] init];
    model.absRect = rect;
    model.lsvId = lsvId;
    return model;
}
@end


