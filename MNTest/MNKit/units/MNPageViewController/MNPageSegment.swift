//
//  MNPageSegment.swift
//  anhe
//
//  Created by 冯盼 on 2022/5/29.
//  分段配置信息

import UIKit
import Foundation
import CoreGraphics

class MNPageSegment {
    /// 标题
    var title: String = ""
    /// 角标
    var badge: MNBadgeConvertible?
    /// 大小
    var size: CGSize = .zero
    /// 是否选中状态
    var isSelected: Bool = false
    /// 标记线位置
    var shadowFrame: CGRect = .zero
    /// 高亮时标记线位置
    var highlightShadowFrame: CGRect = .zero
    /// transform缩放因数
    var scale: CGFloat = 1.0
}
