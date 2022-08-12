//
//  UITableView+MNExtension.swift
//  MNTest
//
//  Created by 冯盼 on 2022/8/13.
//

import UIKit

// MARK: - UITableView
public extension UITableView {
    
    /// 表格尺寸
    var rowSize: CGSize {
        CGSize(width: frame.width, height: rowHeight)
    }
    
    /// 实例化TableView
    /// - Parameters:
    ///   - frame: 位置
    ///   - style: 样式
    convenience init(frame: CGRect, tableStyle style: Style) {
        self.init(frame: frame, style: style)
        showsVerticalScrollIndicator = false
        showsHorizontalScrollIndicator = false
        backgroundColor = UIColor.white
        keyboardDismissMode = .onDrag
        separatorStyle = .singleLine
        tableHeaderView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: 0.0, height: CGFloat.leastNormalMagnitude))
        tableFooterView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: 0.0, height: CGFloat.leastNormalMagnitude))
        estimatedRowHeight = 0.0
        estimatedSectionHeaderHeight = 0.0
        estimatedSectionFooterHeight = 0.0
        layoutMargins = .zero
        separatorInset = .zero
        if #available(iOS 11.0, *) {
            contentInsetAdjustmentBehavior = .never;
        }
        if #available(iOS 15.0, *) {
            sectionHeaderTopPadding = 0.0
        }
    }
}
