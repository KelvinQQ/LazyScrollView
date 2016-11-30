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
@property (nonatomic, copy) NSDictionary *reuseViews;
@property (nonatomic, copy) NSArray *allRects;
@property (nonatomic, assign) NSUInteger numberOfItems;
@property (nonatomic, copy) NSArray *ascendingMinEdgeRects;
@property (nonatomic, copy) NSArray *descendingMaxEdgeRects;
@property (nonatomic, copy) NSSet *visiableViews;
@end

@implementation LazyScrollView
- (instancetype)init {
    self = [super init];
    if (self) {
        self.delegate = self;
    }
    return self;
}
- (void)reloadData {
    _numberOfItems = [_dataSource numberOfItemInScrollView:self];
    NSMutableArray *allRects = @[].mutableCopy;
    for (NSInteger index = 0; index < _numberOfItems; ++ index) {
        [allRects addObject:[_dataSource scrollView:self rectModelAtIndex:index]];
    }
    _allRects = allRects;
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
- (UIView *)dequeueReusableItemWithIdentifier:(NSString *)identifier {
    return nil;
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
- (NSInteger)findIndexWithMinEdge:(CGFloat)minEdge {

}
#pragma mark -
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    
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


