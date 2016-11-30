//
//  LazyScrollView.m
//  LazyScrollView
//
//  Created by Zhang Qing on 16/11/30.
//  Copyright © 2016年 Tsing. All rights reserved.
//

#import "LazyScrollView.h"
#import <objc/runtime.h>


@interface LazyScrollView () <UIScrollViewDelegate>
{
    
}
@property (nonatomic, strong, nullable) NSMutableDictionary<NSString *, NSMutableArray *> *reuseViews;
@property (nonatomic, copy, nullable) NSArray *allRects;
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
- (void)reloadData {
    _numberOfItems = [_dataSource numberOfItemInScrollView:self];
    NSMutableArray *allRects = @[].mutableCopy;
    for (NSInteger index = 0; index < _numberOfItems; ++ index) {
        [allRects addObject:[_dataSource scrollView:self rectModelAtIndex:index]];
    }
    _allRects = allRects;
    LSVRectModel *model = [_allRects lastObject];
    self.contentSize = CGSizeMake(self.bounds.size.width, model.absRect.origin.y + model.absRect.size.height + 15);
    
    if (_direction == LazyScrollViewDirectionVertical) {
        _ascendingMinEdgeRects =
        [_allRects sortedArrayUsingComparator:^NSComparisonResult(LSVRectModel*  _Nonnull obj1, LSVRectModel*  _Nonnull obj2) {
            return CGRectGetMinY(obj1.absRect) > CGRectGetMinY(obj2.absRect);
        }];
        _descendingMaxEdgeRects =
        [_allRects sortedArrayUsingComparator:^NSComparisonResult(LSVRectModel*  _Nonnull obj1, LSVRectModel*  _Nonnull obj2) {
            return CGRectGetMaxY(obj1.absRect) < CGRectGetMaxY(obj2.absRect);
        }];
    }
    else {
        _ascendingMinEdgeRects =
        [_allRects sortedArrayUsingComparator:^NSComparisonResult(LSVRectModel*  _Nonnull obj1, LSVRectModel*  _Nonnull obj2) {
            return CGRectGetMinX(obj1.absRect) > CGRectGetMinX(obj2.absRect);
        }];
        _descendingMaxEdgeRects =
        [_allRects sortedArrayUsingComparator:^NSComparisonResult(LSVRectModel*  _Nonnull obj1, LSVRectModel*  _Nonnull obj2) {
            return CGRectGetMaxX(obj1.absRect) < CGRectGetMaxX(obj2.absRect);
        }];
    }
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
    // 能取出view,并且veiw的标示符正确
    if (view) {
        // 从缓存池中获取
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
- (NSArray *)allRects {
    if (!_allRects) {
        _allRects = @[];
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


