//
//  LazyScrollView.h
//  LazyScrollView
//
//  Created by Zhang Qing on 16/11/30.
//  Copyright © 2016年 Tsing. All rights reserved.
//

#import <UIKit/UIKit.h>

@class LSVRectModel;
@class LazyScrollView;

typedef NS_ENUM(NSUInteger, LazyScrollViewDirection) {
    LazyScrollViewDirectionHorizontal,
    LazyScrollViewDirectionVertical,
};

@protocol LazyScrollViewDataSource <NSObject>
@required
// ScrollView一共展示多少个item
- (NSUInteger)numberOfItemInScrollView:(LazyScrollView *)scrollView;
// 要求根据index直接返回RectModel
- (LSVRectModel *)scrollView:(LazyScrollView *)scrollView rectModelAtIndex:(NSUInteger)index;
// 返回下标所对应的view
- (UIView *)scrollView:(LazyScrollView *)scrollView itemByLsvId:(NSString *)lsvId;

@end

@protocol LazyScrollViewDelegate <NSObject, UIScrollViewDelegate>

@optional
- (void)scrollView:(LazyScrollView *)scrollView didClickItemAtLsvId:(NSString *)lsvId;

@end

@interface LazyScrollView : UIScrollView
@property (nonatomic, weak) id<LazyScrollViewDataSource> dataSource;
@property (nonatomic, weak) id<LazyScrollViewDelegate> delegate;
/**
 *  滚动方向
 *  暂时只支持 `LazyScrollViewDirectionVertical`
 */
//@property (nonatomic, assign) LazyScrollViewDirection direction;
- (void)reloadData;
- (UIView *)dequeueReusableItemWithIdentifier:(NSString *)identifier;
- (void)registerClass:(Class)viewClass forViewReuseIdentifier:(NSString *)identifier;
@end



@interface UIView (LSV)
// 索引过的标识，在LazyScrollView范围内唯一
@property (nonatomic, copy) NSString  *lsvId;
// 重用的ID
@property (nonatomic, copy) NSString *reuseIdentifier;
@end

@interface LSVRectModel : NSObject
// 转换后的绝对值rect
@property (nonatomic, assign) CGRect absRect;
// 业务下标
@property (nonatomic, copy) NSString *lsvId;
+ (instancetype)modelWithRect:(CGRect)rect lsvId:(NSString *)lsvId;
@end


