##`LazyScrollView`简介
>LazyScrollView 继承自ScrollView，目标是解决异构（与TableView的同构对比）滚动视图的复用回收问题。它可以支持跨View层的复用，用易用方式来生成一个高性能的滚动视图。此方案最先在天猫iOS客户端的首页落地。

>----[苹果核 - iOS 高性能异构滚动视图构建方案 —— LazyScrollView](http://pingguohe.net/2016/01/31/lazyscroll.html)

在[这篇文章](http://pingguohe.net/2016/01/31/lazyscroll.html)中，博主详细介绍了LazyScrollView的使用和实现方案，但是并没有给出具体DEMO，这里只是站在巨人的肩膀上，给一个DEMO，同时也希望可以抛砖引玉。

##`LazyScrollView`使用
暂时的实现比较简陋，目前只有一个`id<LazyScrollViewDataSource> dataSource;`，需要实现下面三个接口：
```
@protocol LazyScrollViewDataSource <NSObject>
@required
// ScrollView一共展示多少个item
- (NSUInteger)numberOfItemInScrollView:(LazyScrollView *)scrollView;
// 要求根据index直接返回RectModel
- (LSVRectModel *)scrollView:(LazyScrollView *)scrollView rectModelAtIndex:(NSUInteger)index;
// 返回下标所对应的view
- (UIView *)scrollView:(LazyScrollView *)scrollView itemByLsvId:(NSString *)lsvId;
@end
```
其中`LSVRectModel`就是原文中的`TMMuiRectModel`：
```
@interface LSVRectModel : NSObject
// 转换后的绝对值rect
@property (nonatomic, assign) CGRect absRect;
// 业务下标
@property (nonatomic, copy) NSString *lsvId;
+ (instancetype)modelWithRect:(CGRect)rect lsvId:(NSString *)lsvId;
@end
```
三个接口都很简单，和`UITableView`很类似，如果有不清楚，可以在底部查看DEMO或者原文。

另外，``LazyScrollView``提供了三个接口，也都是仿照`UITableView`来的，所以整个`LazyScrollView`的使用应该是很容易上手的：
```
- (void)reloadData;
- (UIView *)dequeueReusableItemWithIdentifier:(NSString *)identifier;
- (void)registerClass:(Class)viewClass forViewReuseIdentifier:(NSString *)identifier;
```
##`LazyScrollView`实现
最主要的思路就是复用，所以有两个`View`池：
```
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSMutableSet *> *reuseViews;
@property (nonatomic, strong) NSMutableSet<__kindof UIView *> *visibleViews;
```
由于每个`View`可能对应不同的identifier，所以`reuseViews`是一个`NSMutableDictionary`。
当一个`View`滑出可见区域之后，会将它先从`visibleViews`中移除，然后添加到`reuseViews`中，并从`LazyScrollView`中 *remove*，即调用`removeFromSuperview`。这个地方在原文中作者的表述可能让大家误会了。
>LazyScrollView中有一个Dictionary，key是reuseIdentifier,Value是对应reuseIdentifier被回收的View，当LazyScrollView得知这个View不该再出现了，会把View放在这里，并且把这个View hidden掉。

这里作者用的是`hidden掉`，但是我们知道，`hidden`只是控制显隐，`View`本身还是在那里，也无法去复用。

而当一个View滑到可见区域内时，需要先从`reuseViews`中复用，如果`reuseViews`没有，则重新创建一个。相关实现请看`- (UIView *)dequeueReusableItemWithIdentifier:(NSString *)identifier;`。

最后一个问题就是如何判断一个`View`是在可见区域内的。这里原文中说的很清晰，还有图片配合。建议大家还是移步原文。这里我简单说一下，找到顶边大于`contentOffset.y - BUFFER_HEIGHT`，底边小于`contentOffset.y+CGRectGetHeight(self.bounds) + BUFFER_HEIGHT`，然后两个集合取交集就是需要显示的`View`集合了。
当然，这里有一些处理算法：
* 对 **顶边** 做升序处理得到一个集合，对 **底边** 降序处理得到一个集合。
* 采用二分法查找合适的位置，然后再对上一步得到的集合取子集即可。

好了，说了这么多，先放出DEMO地址吧，希望大家可以帮助完善，也希望可以给个Star。[https://github.com/HistoryZhang/LazyScrollView](https://github.com/HistoryZhang/LazyScrollView)。

原文地址：[苹果核 - iOS 高性能异构滚动视图构建方案 —— LazyScrollView](http://pingguohe.net/2016/01/31/lazyscroll.html)（里面还有很多干货）。

最后说一下目前写的几个问题，希望大家可以一起来优化：

- [x] 没有处理`View`点击事件，即没有写`delegate`回调。

- [ ] 二分法查找合适位置的时候算法待优化。

- [ ] 从旧的`visibleViews`中移除被滑出的`View`算法待优化。

贴一段第二个问题的代码：
```
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
```

再贴一段第三个问题的代码：
```
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
```

##更新记录
* **2016.12.27 新增`delegate`**

	新增了`@protocol LazyScrollViewDelegate <NSObject, UIScrollViewDelegate>`。其中有一个接口：
	
	```
	@optional
	- (void)scrollView:(LazyScrollView *)scrollView didClickItemAtLsvId:(NSString *)lsvId;
	```
	由于`lsvId`在`ScrollView`中是唯一了，这里就没有使用`index`了。
	
* **2016.12.04 实现基本功能**