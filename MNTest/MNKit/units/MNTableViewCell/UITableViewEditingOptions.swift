//
//  UITableViewEditingOptions.swift
//  MNTest
//
//  Created by 冯盼 on 2022/8/22.
//  编辑的配置信息

import UIKit

@objc class UITableViewEditingOptions: NSObject {
    
    /// 定义拖拽方向
    @objc enum Direction: Int {
        case left, right
    }
    
    /// 圆角
    @objc var cornerRadius: CGFloat = 0.0
    
    /// 内容偏移
    @objc var contentInset: UIEdgeInsets = .zero
    
    /// 背景颜色
    @objc var backgroundColor: UIColor = .clear
    
    /// 拖拽的方向
    @objc var direction: UITableViewEditingOptions.Direction = .left
}
