//
//  LazyScrollView.h
//  LazyScrollView
//
//  Created by Zhang Qing on 16/11/30.
//  Copyright © 2016年 Tsing. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol LazyScrollViewDataSource;
@protocol LazyScrollViewDelegate;

@class LSVRectModel;

typedef NS_ENUM(NSUInteger, LazyScrollViewDirection) {
    LazyScrollViewDirectionHorizontal,
    LazyScrollViewDirectionVertical,
};

@interface LazyScrollView : UIScrollView
@property (nonatomic, weak) id<LazyScrollViewDataSource> dataSource;
@property (nonatomic, weak) id<LazyScrollViewDelegate> delegateLsv;
@property (nonatomic, assign) LazyScrollViewDirection direction;
- (void)reloadData;
- (UIView *)dequeueReusableItemWithIdentifier:(NSString *)identifier;
@end

@protocol LazyScrollViewDataSource <NSObject>
@required
// ScrollView一共展示多少个item
- (NSUInteger)numberOfItemInScrollView:(LazyScrollView *)scrollView;
// 要求根据index直接返回RectModel
- (LSVRectModel *)scrollView:(LazyScrollView *)scrollView rectModelAtIndex:(NSUInteger)index;
// 返回下标所对应的view
- (UIView *)scrollView:(LazyScrollView *)scrollView itemByLsvID:(NSString *)lsvID;
@end

@protocol LazyScrollViewDelegate <NSObject, UIScrollViewDelegate>

@optional
- (void)scrollView:(LazyScrollView *)scrollView didClickItemAtIndex:(NSUInteger)index;

@end

@interface UIView (LSV)
// 索引过的标识，在LazyScrollView范围内唯一
@property (nonatomic, copy) NSString  *lsvID;
// 重用的ID
@property (nonatomic, copy) NSString *reuseIdentifier;
@end

@interface LSVRectModel : NSObject
// 转换后的绝对值rect
@property (nonatomic, assign) CGRect absRect;
// 业务下标
@property (nonatomic, copy) NSString *lsvID;
@end


