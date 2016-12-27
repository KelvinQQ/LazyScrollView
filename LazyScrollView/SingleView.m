//
//  SingleView.m
//  LazyScrollView
//
//  Created by Zhang Qing on 16/12/1.
//  Copyright © 2016年 Tsing. All rights reserved.
//

#import "SingleView.h"

NSString * const kViewIdfSingle = @"kViewIdfSingle";
NSString * const kViewIdfSingleOther = @"kViewIdfSingleOther";

@interface SingleView ()
@property (nonatomic, strong) UILabel *title;
@end

@implementation SingleView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self setupUI];
    }
    return self;
}

- (void)setupUI {
    
    [self addSubview:self.title];
    
    self.title.frame = CGRectMake(0, 0, 100, 50);
}

- (UIColor *)randomColor {
    CGFloat hue = ( arc4random() % 256 / 256.0 );
    CGFloat saturation = ( arc4random() % 128 / 256.0 ) + 0.5;
    CGFloat brightness = ( arc4random() % 128 / 256.0 ) + 0.5;
    return [UIColor colorWithHue:hue saturation:saturation brightness:brightness alpha:1];
}

#pragma mark - setter

- (void)setData:(NSString *)data {
    _data = data;
    self.title.text = data;
    self.backgroundColor = [self randomColor];
}

#pragma mark - getter

- (UILabel *)title {
    if (!_title) {
        _title = [UILabel new];
        _title.font = [UIFont systemFontOfSize:13.f];
        _title.textColor = [UIColor whiteColor];
    }
    return _title;
}

@end
