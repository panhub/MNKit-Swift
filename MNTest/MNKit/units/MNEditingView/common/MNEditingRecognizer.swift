//
//  MNEditingRecognizer.swift
//  MNTest
//
//  Created by 冯盼 on 2022/8/23.
//  表格编辑手势

import UIKit

protocol MNEditingRecognizerHandler: NSObjectProtocol {
    
    /// 询问是否可响应手势
    /// - Parameters:
    ///   - recognizer: 拖拽手势
    ///   - editingDirection: 拖拽方向
    /// - Returns: 是否可响应
    func gestureRecognizerShouldBegin(_ recognizer: MNEditingRecognizer, direction editingDirection: MNEditingDirection) -> Bool
}

class MNEditingRecognizer: UIPanGestureRecognizer {
    
    /// 事件回调代理
    weak var handler: MNEditingRecognizerHandler?
    
    /// 实例化拖拽手势
    /// - Parameters:
    ///   - target: 响应者
    ///   - action: 响应方法
    override init(target: Any?, action: Selector?) {
        super.init(target: target, action: action)
        self.delegate = self
    }
}

// MARK: - UIGestureRecognizerDelegate
extension MNEditingRecognizer: UIGestureRecognizerDelegate {
    
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let recognizer = gestureRecognizer as? UIPanGestureRecognizer else { return false }
        // 判断方向
        let translation = recognizer.translation(in: recognizer.view)
        guard abs(translation.y) < abs(translation.x) else { return false }
        let velocity = recognizer.velocity(in: recognizer.view)
        // 判断是否可编辑
        guard let handler = handler else { return false }
        return handler.gestureRecognizerShouldBegin(self, direction: velocity.x <= 0.0 ? .left : .right)
    }
}
