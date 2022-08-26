//
//  MNEditingOptions.swift
//  MNTest
//
//  Created by 冯盼 on 2022/8/22.
//  表格编辑配置信息

import UIKit

@objc class MNEditingOptions: NSObject {
    
    /// 圆角
    @objc var cornerRadius: CGFloat = 0.0
    
    /// 内容偏移
    /// left: 'direction = right'时有效, right: 'direction = left'时有效
    @objc var contentInset: UIEdgeInsets = .zero
    
    /// 背景颜色
    @objc var backgroundColor: UIColor? = .clear
    
    /// 使用内部按钮响应事件 二次提交则由编辑视图自行处理响应
    @objc var adjustUserInteraction: Bool = true
}
