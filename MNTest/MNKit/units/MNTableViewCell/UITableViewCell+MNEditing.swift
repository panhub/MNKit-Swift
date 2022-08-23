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
    
    func tableView(_ tableView: UITableView, canEditingRowAt indexPath: IndexPath) -> Bool
    
    func tableView(_ tableView: UITableView, editingActionsForRowAt indexPath: IndexPath) -> [UIView]
    
    func tableView(_ tableView: UITableView, commitEditing action: UIView, forRowAt indexPath: IndexPath) -> UIView?
}

extension UIGestureRecognizer {
    
    static let TableViewCellEditingLabel: String = "com.mn.recognizer.editing.label"
    
    private struct EditingAssociated {
        static var label = "com.mn.recognizer.editing.label"
    }
    
    var editingLabel: String {
        get { (objc_getAssociatedObject(self, &EditingAssociated.label) as? String) ?? "" }
        set { objc_setAssociatedObject(self, &EditingAssociated.label, newValue, .OBJC_ASSOCIATION_COPY) }
    }
}

@objc extension UITableViewCell {
    
    private struct EditingAssociated {
        static var view = "com.mn.table.view.cell.editing.view"
        static var editing = "com.mn.table.view.cell.allows.editing"
    }
    
    private var editingView: UITableViewCellEditingView? {
        get { objc_getAssociatedObject(self, &EditingAssociated.view) as? UITableViewCellEditingView }
        set { objc_setAssociatedObject(self, &EditingAssociated.view, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
    
    @objc var isScrollEditing: Bool {
        guard let editingView = editingView, editingView.frame.width > 0.0 else { return false }
        return true
    }
    
    @objc var allowsEditing: Bool {
        get { (objc_getAssociatedObject(self, &EditingAssociated.editing) as? Bool) ?? false }
        set {
            if allowsEditing == newValue { return }
            objc_setAssociatedObject(self, &EditingAssociated.editing, newValue, .OBJC_ASSOCIATION_ASSIGN)
            if newValue {
                let pan = UITableViewEditingRecognizer(target: self, action: #selector(handleCellEditing(_:)))
                pan.handler = self
                pan.editingLabel = UIGestureRecognizer.TableViewCellEditingLabel
                contentView.addGestureRecognizer(pan)
            } else {
                guard let gestureRecognizers = contentView.gestureRecognizers else { return }
                for recognizer in gestureRecognizers.filter ({ $0.editingLabel == UIGestureRecognizer.TableViewCellEditingLabel }) {
                    recognizer.removeTarget(nil, action: nil)
                    contentView.removeGestureRecognizer(recognizer)
                }
            }
        }
    }
    
    @objc private func handleCellEditing(_ recognizer: UIPanGestureRecognizer) {
        let translation = recognizer.translation(in: recognizer.view)
        recognizer.setTranslation(.zero, in: recognizer.view)
        switch recognizer.state {
        case .began: break
        case .changed:
            guard let editingView = editingView else { break }
            let sum = editingView.sum
            var rect = editingView.frame
            let spacing = tableView?.options.contentInset.right ?? 0.0
            var m: CGFloat = translation.x/5.0*4.0
            if rect.width - m > sum {
                // 超过最优距离, 加阻尼, 减缓拖拽效果
                m = translation.x/4.0
            }
            rect.size.width -= m
            rect.size.width = max(0.0, rect.width)
            rect.origin.x = frame.width - spacing - rect.width
            editingView.frame = rect
            editingView.update(width: rect.width)
            setNeedsLayout()
            layoutIfNeeded()
        case .ended:
            guard let editingView = editingView else { break }
            let velocity = recognizer.velocity(in: recognizer.view)
            print(velocity)
            if editingView.frame.width <= 0.0 {
                tableView?.isScrollEditing = false
                editingView.removeAllActions()
            } else if editingView.frame.width >= editingView.sum {
                updateEditing(true, animated: true)
            } else if editingView.frame.width >= 50.0, velocity.x < 0.0 {
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
            let spacing = tableView?.options.contentInset.right ?? 0.0
            if editing {
                rect.size.width = editingView.sum
            } else {
                rect.size.width = 0.0
            }
            rect.origin.x = frame.width - spacing - rect.width
            editingView.frame = rect
            editingView.update(width: rect.width)
            setNeedsLayout()
            layoutIfNeeded()
        }
        willBeginUpdateEditing(editing, animated: animated)
        if animated {
            let completionHandler: (Bool)->Void = { [weak self] _ in
                guard let self = self else { return }
                self.tableView?.isScrollEditing = editing
                if editing == false { self.editingView?.removeAllActions() }
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
            if editing == false { editingView?.removeAllActions() }
            tableView?.isScrollEditing = false
            didEndUpdateEditing(editing, animated: animated)
        }
    }
}

// MARK: - UITableViewEditingRecognizerHandler
extension UITableViewCell: UITableViewEditingRecognizerHandler {
    
    func shouldBeginEditing(_ recognizer: UITableViewEditingRecognizer) -> Bool {
        guard let tableView = tableView else { return false }
        guard let indexPath = tableView.indexPath(for: self) else { return false }
        guard let delegate = tableView.delegate as? UITableViewEditingDelegate else { return false }
        guard delegate.tableView(tableView, canEditingRowAt: indexPath) else { return false }
        if let editingView = editingView, editingView.frame.width > 0.0 { return true }
        // 获取编辑视图
        let actions = delegate.tableView(tableView, editingActionsForRowAt: indexPath)
        guard actions.count > 0 else { return false }
        // 结束其它表格编辑状态
        tableView.endEditing(animated: true)
        // 添加编辑视图
        var editingView: UITableViewCellEditingView! = editingView
        if editingView == nil {
            editingView = UITableViewCellEditingView(options: tableView.options)
            editingView.delegate = self
            insertSubview(editingView, aboveSubview: contentView)
            self.editingView = editingView
        } else {
            editingView.removeAllActions()
        }
        editingView.update(actions: actions)
        return true
    }
}

// MARK: - UITableViewCellEditingHandler
extension UITableViewCell: UITableViewCellEditingHandler {
    
    func editingView(_ editingView: UITableViewCellEditingView, didTouchActionAt index: Int) {
        guard let tableView = tableView else { return }
        guard let indexPath = tableView.indexPath(for: self) else { return }
        guard let delegate = tableView.delegate as? UITableViewEditingDelegate else { return }
        guard let action = delegate.tableView(tableView, commitEditing: editingView.actions[index], forRowAt: indexPath) else { return }
        editingView.replacing(index: index, action: action)
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
        var rect = bounds
        rect.origin.x -= editingView.frame.width
        contentView.frame = rect
        print(contentView.frame)
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
