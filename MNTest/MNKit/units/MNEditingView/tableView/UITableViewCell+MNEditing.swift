//
//  UITableViewCell+MNEditing.swift
//  MNTest
//
//  Created by 冯盼 on 2022/8/22.
//  对UITableViewCell编辑支持

import UIKit
import Foundation
import ObjectiveC.runtime

@objc protocol UITableViewEditingDelegate {
    
    /// 提交表格的编辑方向
    /// - Parameters:
    ///   - tableView: 集合视图
    ///   - indexPath: 索引
    /// - Returns: 编辑方向
    func tableView(_ tableView: UITableView, rowEditingDirectionAt indexPath: IndexPath) -> MNEditingDirection
    
    /// 提交编辑视图
    /// - Parameters:
    ///   - tableView: 集合视图
    ///   - indexPath: 索引
    /// - Returns: 编辑视图
    func tableView(_ tableView: UITableView, editingActionsForRowAt indexPath: IndexPath) -> [UIView]
    
    /// 提交二次编辑视图
    /// - Parameters:
    ///   - tableView: 集合视图
    ///   - action: 点击的按钮
    ///   - indexPath: 索引
    /// - Returns: 二次编辑视图
    @objc optional func tableView(_ tableView: UITableView, commitEditing action: UIView, forRowAt indexPath: IndexPath) -> UIView?
}

@objc extension UITableViewCell {
    
    private struct EditingAssociated {
        static var x = "com.mn.table.view.cell.content.view.x"
        static var view = "com.mn.table.view.cell.editing.view"
        static var editing = "com.mn.table.view.cell.allows.editing"
    }
    
    /// 编辑开始时的x
    private var contentViewOriginX: CGFloat {
        get { objc_getAssociatedObject(self, &EditingAssociated.x) as? CGFloat ?? 0.0 }
        set { objc_setAssociatedObject(self, &EditingAssociated.x, newValue, .OBJC_ASSOCIATION_ASSIGN) }
    }
    
    /// 编辑视图
    private var editingView: MNEditingView? {
        get { objc_getAssociatedObject(self, &EditingAssociated.view) as? MNEditingView }
        set { objc_setAssociatedObject(self, &EditingAssociated.view, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
    
    /// 是否处于编辑状态
    @objc var isHaulEditing: Bool {
        guard let editingView = editingView, editingView.frame.width > 0.0 else { return false }
        return true
    }
    
    /// 是否允许编辑
    @objc var allowsEditing: Bool {
        get { (objc_getAssociatedObject(self, &EditingAssociated.editing) as? Bool) ?? false }
        set {
            guard allowsEditing != newValue else { return }
            objc_setAssociatedObject(self, &EditingAssociated.editing, newValue, .OBJC_ASSOCIATION_ASSIGN)
            if newValue {
                let pan = MNEditingRecognizer(target: self, action: #selector(handleCellEditing(_:)))
                pan.handler = self
                contentView.addGestureRecognizer(pan)
            } else {
                guard let gestureRecognizers = contentView.gestureRecognizers else { return }
                for recognizer in gestureRecognizers.filter ({ $0 is MNEditingRecognizer }) {
                    recognizer.removeTarget(nil, action: nil)
                    contentView.removeGestureRecognizer(recognizer)
                }
            }
        }
    }
    
    /// 处理拖拽手势
    /// - Parameter recognizer: 手势
    @objc private func handleCellEditing(_ recognizer: UIPanGestureRecognizer) {
        switch recognizer.state {
        case .changed:
            guard let editingView = editingView else { break }
            let translation = recognizer.translation(in: recognizer.view)
            recognizer.setTranslation(.zero, in: recognizer.view)
            let sum = editingView.sum
            var rect = editingView.frame
            var m: CGFloat = translation.x
            if rect.width >= sum {
                // 超过最优距离, 加阻尼, 减缓拖拽效果
                m = translation.x/4.0
            }
            m = ceil(m)
            if editingView.direction == .left {
                let spacing = tableView?.editingOptions.contentInset.right ?? 0.0
                rect.size.width -= m
                rect.size.width = max(0.0, rect.width)
                rect.origin.x = frame.width - rect.width - spacing
            } else {
                rect.size.width += m
                rect.size.width = max(0.0, rect.width)
            }
            editingView.frame = rect
            editingView.update(width: rect.width)
            setNeedsLayout()
            layoutIfNeeded()
        case .ended:
            guard let editingView = editingView else { break }
            let sum = editingView.sum
            let velocity = recognizer.velocity(in: recognizer.view)
            if editingView.frame.width <= 0.0 {
                tableView?.isHaulEditing = false
            } else if editingView.frame.width == sum {
                tableView?.isHaulEditing = true
            } else if editingView.frame.width > sum {
                updateEditing(true, animated: true)
            } else if editingView.frame.width >= 45.0 && ((editingView.direction == .left && velocity.x < 0.0) || (editingView.direction == .right && velocity.x > 0.0)) {
                updateEditing(true, animated: true)
            } else {
                updateEditing(false, animated: true)
            }
        default: break
        }
    }
    
    /// 更新编辑状态
    /// - Parameters:
    ///   - editing: 是否开启编辑
    ///   - animated: 是否显示动画过程
    @objc func updateEditing(_ editing: Bool, animated: Bool) {
        func update(editing: Bool) {
            guard let editingView = editingView else { return }
            var rect = editingView.frame
            if editing {
                rect.size.width = editingView.sum
            } else {
                rect.size.width = 0.0
            }
            if editingView.direction == .left {
                let spacing = tableView?.editingOptions.contentInset.right ?? 0.0
                rect.origin.x = frame.width - rect.width - spacing
            }
            editingView.frame = rect
            editingView.update(width: rect.width)
            setNeedsLayout()
            layoutIfNeeded()
        }
        willBeginUpdateEditing(editing, animated: animated)
        if animated {
            let completionHandler: (Bool)->Void = { [weak self] _ in
                guard let self = self else { return }
                self.tableView?.isHaulEditing = editing
                self.didEndUpdateEditing(editing, animated: animated)
            }
            if editing {
                UIView.animate(withDuration: 0.7, delay: 0.0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1.0, options: [.beginFromCurrentState, .curveEaseInOut], animations: {
                    update(editing: true)
                }, completion: completionHandler)
            } else {
                UIView.animate(withDuration: 0.25, delay: 0.0, options: [.beginFromCurrentState, .curveEaseInOut], animations: {
                    update(editing: false)
                }, completion: completionHandler)
            }
        } else {
            update(editing: editing)
            tableView?.isHaulEditing = false
            didEndUpdateEditing(editing, animated: animated)
        }
    }
}

// MARK: - MNEditingRecognizerHandler
extension UITableViewCell: MNEditingRecognizerHandler {
    
    func gestureRecognizerShouldBegin(_ recognizer: MNEditingRecognizer, direction editingDirection: MNEditingDirection) -> Bool {
        guard let tableView = tableView else { return false }
        guard let indexPath = tableView.indexPath(for: self) else { return false }
        guard let delegate = tableView.delegate as? UITableViewEditingDelegate else { return false }
        // 编辑状态下可继续拖拽
        if let editingView = editingView, editingView.frame.width > 0.0 { return true }
        // 支持的编辑方向
        let direction: MNEditingDirection = delegate.tableView(tableView, rowEditingDirectionAt: indexPath)
        if direction == .none { return false }
        // 方向一致
        guard direction == editingDirection else { return  false }
        // 获取自定义的编辑视图
        let actions = delegate.tableView(tableView, editingActionsForRowAt: indexPath)
        guard actions.count > 0 else { return false }
        // 结束其它表格编辑状态
        tableView.endEditing(animated: true)
        // 添加编辑视图
        var view: MNEditingView! = editingView
        if view == nil {
            view = MNEditingView(options: tableView.editingOptions)
            view.delegate = self
            insertSubview(view, aboveSubview: contentView)
            editingView = view
            contentViewOriginX = contentView.frame.minX
        }
        view.update(direction: direction)
        view.update(actions: actions)
        return true
    }
}

// MARK: - MNEditingViewDelegate
extension UITableViewCell: MNEditingViewDelegate {
    
    func editingView(_ editingView: MNEditingView, actionTouchUpInside action: UIView, index: Int) {
        guard let tableView = tableView else { return }
        guard let indexPath = tableView.indexPath(for: self) else { return }
        guard let delegate = tableView.delegate as? UITableViewEditingDelegate else { return }
        guard let newAction = delegate.tableView?(tableView, commitEditing: action, forRowAt: indexPath) else { return }
        editingView.replacing(index: index, action: newAction)
    }
}

// MARK: - 
@objc extension UITableViewCell {
    
    /// 即将更新编辑状态
    /// - Parameters:
    ///   - editing: 指定编辑状态
    ///   - animated: 是否显示动画过程
    @objc func willBeginUpdateEditing(_ editing: Bool, animated: Bool) {}
    
    /// 更新编辑状态结束
    /// - Parameters:
    ///   - editing: 编辑状态
    ///   - animated: 是否显示动画过程
    @objc func didEndUpdateEditing(_ editing: Bool, animated: Bool) {}
    
    /// 约束编辑视图
    @objc func layoutEditingView() {
        guard let editingView = editingView, editingView.frame.width > 0.0 else { return }
        var rect = contentView.frame
        rect.origin.x = contentViewOriginX
        if editingView.direction == .left {
            rect.origin.x -= editingView.frame.width
        } else {
            rect.origin.x += editingView.frame.width
        }
        contentView.frame = rect
    }
}

@objc extension UITableViewCell {
    
    /// 当前行索引
    var indexPath: IndexPath? { tableView?.indexPath(for: self) }
    
    /// 列表
    @objc var tableView: UITableView! {
        var responder = next
        while let res = responder {
            if res is UITableView { return res as? UITableView }
            responder = res.next
        }
        return nil
    }
}
