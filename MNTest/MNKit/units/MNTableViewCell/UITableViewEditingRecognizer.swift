//
//  UITableViewEditingRecognizer.swift
//  MNTest
//
//  Created by 冯盼 on 2022/8/23.
//  表格编辑手势

import UIKit

protocol UITableViewEditingRecognizerHandler: NSObjectProtocol {
    
    /// 询问是否可编辑
    /// - Parameter recognizer: 拖拽手势
    /// - Returns: 是否可编辑
    func shouldBeginEditing(_ recognizer: UITableViewEditingRecognizer) -> Bool
}

class UITableViewEditingRecognizer: UIPanGestureRecognizer {
    
    weak var handler: UITableViewEditingRecognizerHandler?
    
    override init(target: Any?, action: Selector?) {
        super.init(target: target, action: action)
        self.delegate = self
    }
}

// MARK: - UIGestureRecognizerDelegate
extension UITableViewEditingRecognizer: UIGestureRecognizerDelegate {
    
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let recognizer = gestureRecognizer as? UIPanGestureRecognizer else { return false }
        // 判断方向
        let translation = recognizer.translation(in: recognizer.view)
        guard abs(translation.y) <= abs(translation.x) else { return false }
        // 判断是否可编辑
        guard let handler = handler else { return false }
        return handler.shouldBeginEditing(self)
    }
}
