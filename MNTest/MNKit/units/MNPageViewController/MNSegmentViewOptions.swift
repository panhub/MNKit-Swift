//
//  MNSegmentViewOptions.swift
//  anhe
//
//  Created by 冯盼 on 2022/5/28.
//  分段视图配置信息

import UIKit
import Foundation

class MNSegmentViewOptions: NSObject {
    
    /// 补全方案
    enum SegmentContentMode: Int {
        case normal, fit, fill
    }
    
    /// 标记视图的补充方案
    enum SegmentShadowMask: Int {
        case fit, fill, aspectFit
    }
    
    /// 标记视图的对齐方式(相对于标题)
    enum SegmentShadowAlignment: Int {
        case left, center, right
    }
    
    /// 标记视图滑动位置
    enum SegmentScrollPosition: Int {
        case none, left, center, right
    }
    
    /// 高度
    var height: CGFloat = 48.0
    /// 补全方案
    var contentMode: SegmentContentMode = .normal
    /// 标记视图的补充方案
    var shadowMask: SegmentShadowMask = .fit
    /// 滑动位置
    var scrollPosition: SegmentScrollPosition = .none
    /// 标记视图对齐方式
    var shadowAlignment: SegmentShadowAlignment = .center
    /// 标记视图的大小(配合SegmentShadowMask.aspectFit使用宽度)
    var shadowSize: CGSize = CGSize(width: 0.0, height: 5.0)
    /// 标记视图的图片
    var shadowImage: UIImage?
    /// 标记视图的颜色
    var shadowColor: UIColor? = .red
    /// 标记视图的偏移
    var shadowOffset: UIOffset = .zero
    /// 标题的颜色
    var titleColor: UIColor? = .gray
    /// 标题高亮颜色
    var titleHighlightColor: UIColor? = .black
    /// 分割线颜色
    var separatorColor: UIColor? = .gray
    /// 背景颜色
    var backgroundColor: UIColor? = .white
    /// 集合视图颜色
    var collectionColor: UIColor? = .white
    /// 标题字体
    var titleFont: UIFont = .systemFont(ofSize: 17.0)
    /// 标题高亮字体
    var titleHighlightFont: UIFont = .systemFont(ofSize: 17.0, weight: .medium)
    /// 导航分割线约束
    var separatorInset: UIEdgeInsets = .zero
    /// 导航约束 左右边距内部会调整
    var contentInset: UIEdgeInsets = .zero
    /// width:标题项追加的宽度 height:导航高度
    var itemSize: CGSize = CGSize(width: 30.0, height: 48.0)
    /// 导航标题项间隔
    var interitemSpacing: CGFloat = 0.0
    /// 角标字体
    var badgeFont: UIFont = .systemFont(ofSize: 11.0, weight: .medium)
    /// 角标颜色
    var badgeColor: UIColor = .red
    /// 角标偏移
    var badgeOffset: UIOffset = .zero
    /// 标题项选中时transform动画缩放因数 不能小于1.0
    var transformScale: CGFloat = 1.0
}
