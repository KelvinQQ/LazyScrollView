Pod::Spec.new do |s|
  s.name         = "LazyScrollView"
  s.version      = "1.0.0"
  s.summary      = "iOS 高性能异构滚动视图构建方案."
  s.homepage     = "https://github.com/HistoryZhang/LazyScrollView"
  s.license      = { :type => 'MIT License', :file => 'LICENSE' }
  s.author       = { "TsingZhang" => "history_zq@163.com" }
  s.source       = { :git => "https://github.com/HistoryZhang/LazyScrollView.git", :tag => "1.0.0" }
  s.platform     = :ios, '7.0'
  s.source_files = 'Classes/*.{h,m}'
  s.requires_arc = true
end