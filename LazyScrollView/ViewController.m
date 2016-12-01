//
//  ViewController.m
//  LazyScrollView
//
//  Created by Zhang Qing on 16/11/30.
//  Copyright © 2016年 Tsing. All rights reserved.
//

#import "ViewController.h"
#import "LazyScrollView.h"
#import "SingleView.h"

@interface ViewController () <LazyScrollViewDataSource>
@property (strong, nonatomic) LazyScrollView *lazyScrollView;
@property (copy, nonatomic) NSArray<LSVRectModel *> *rectDatas;
@property (copy, nonatomic) NSDictionary *viewsData;
@end

@implementation ViewController
- (void)loadView {
    [super loadView];
    [self loadDatas];
    [self setupUI];
}
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)setupUI {
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    [self.view addSubview:self.lazyScrollView];
    self.lazyScrollView.frame = self.view.bounds;
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSUInteger)numberOfItemInScrollView:(LazyScrollView *)scrollView {
    return self.rectDatas.count;
}

- (LSVRectModel *)scrollView:(LazyScrollView *)scrollView rectModelAtIndex:(NSUInteger)index {
    
    return self.rectDatas[index];
}

- (UIView *)scrollView:(LazyScrollView *)scrollView itemByLsvId:(NSString *)lsvId {
    
    SingleView *view = (SingleView *)[self.lazyScrollView dequeueReusableItemWithIdentifier:kViewIdfSingle];
    
    view.data = self.viewsData[lsvId];
    
    return view;
}

- (void)loadDatas {
    
    NSMutableArray *array = @[].mutableCopy;
    NSMutableDictionary *dictionary = @{}.mutableCopy;
    for (NSInteger index = 0; index < 5000; ++ index) {
        NSString *lsvId = [NSString stringWithFormat:@"%@/%@", @(index / 10), @(index % 10)];
        LSVRectModel *model = [LSVRectModel modelWithRect:CGRectMake(10 + (index % 2) * 120, (index / 2) * 120, 110, 110) lsvId:lsvId];
        [array addObject:model];
        [dictionary setObject:lsvId forKey:lsvId];
    }
    self.rectDatas = array;
    self.viewsData = dictionary;
    
}


#pragma mark - getter

- (LazyScrollView *)lazyScrollView {
    if (!_lazyScrollView) {
        _lazyScrollView = [LazyScrollView new];
        _lazyScrollView.dataSource = self;
        [_lazyScrollView registerClass:[SingleView class] forViewReuseIdentifier:kViewIdfSingle];
    }
    return _lazyScrollView;
}

- (NSArray<LSVRectModel *> *)rectDatas {
    if (!_rectDatas) {
        _rectDatas = [NSArray array];
    }
    return _rectDatas;
}

- (NSDictionary *)viewsData {
    if (!_viewsData) {
        _viewsData = [NSDictionary dictionary];
    }
    return _viewsData;
}
@end
