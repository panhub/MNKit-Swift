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
        static var delegate = "com.mn.table.view.cell.editing.delegate"
        static var recognizer = "com.mn.table.view.cell.recognizer.delegate"
    }
    
    private var recognizerDelegate: UITableViewCellRecognizerDelegate? {
        get { objc_getAssociatedObject(self, &EditingAssociated.recognizer) as? UITableViewCellRecognizerDelegate }
        set { objc_setAssociatedObject(self, &EditingAssociated.recognizer, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
    
    private var editingView: UITableViewCellEditingView? {
        get { objc_getAssociatedObject(self, &EditingAssociated.view) as? UITableViewCellEditingView }
        set { objc_setAssociatedObject(self, &EditingAssociated.view, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
    
    @objc var isEdit: Bool {
        guard let editingView = editingView, editingView.frame.width > 0.0 else { return false }
        return true
    }
    
    @objc var allowsEditing: Bool {
        get { (objc_getAssociatedObject(self, &EditingAssociated.editing) as? Bool) ?? false }
        set {
            if allowsEditing == newValue { return }
            objc_setAssociatedObject(self, &EditingAssociated.editing, newValue, .OBJC_ASSOCIATION_ASSIGN)
            if newValue {
                let delegate = UITableViewCellRecognizerDelegate(target: self, action: #selector(shouldBeginEditing))
                recognizerDelegate = delegate
                let pan = UIPanGestureRecognizer(target: self, action: #selector(handleCellEditing(_:)))
                pan.delegate = delegate
                pan.editingLabel = UIGestureRecognizer.TableViewCellEditingLabel
                contentView.addGestureRecognizer(pan)
                contentView.autoresizingMask = []
            } else {
                guard let gestureRecognizers = contentView.gestureRecognizers else { return }
                recognizerDelegate = nil
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
            rect = bounds
            rect.origin.x -= editingView.frame.width
            contentView.frame = rect
            print(contentView.frame)
        case .ended:
            guard let editingView = editingView else { break }
            let velocity = recognizer.velocity(in: recognizer.view)
            print(velocity)
            if editingView.frame.width <= 0.0 {
                tableView?.isEdit = false
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
    
    @objc private func shouldBeginEditing() -> Bool {
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
            editingView.addTargetForTouchUpInside(self, action: #selector(editingView(_:touchUpInside:)))
            insertSubview(editingView, aboveSubview: contentView)
            self.editingView = editingView
        } else {
            editingView.removeAllActions()
        }
        editingView.update(actions: actions)
        return true
    }
    
    @objc private func editingView(_ editingView: UITableViewCellEditingView, touchUpInside action: UIView) {
        guard let superview = action.superview else { return }
        guard let tableView = tableView else { return }
        guard let indexPath = tableView.indexPath(for: self) else { return }
        guard let delegate = tableView.delegate as? UITableViewEditingDelegate else { return }
        guard let view = delegate.tableView(tableView, commitEditing: action, forRowAt: indexPath) else { return }
        editingView.replacing(index: superview.tag, action: view)
    }
    
    /// 更新编辑状态
    /// - Parameters:
    ///   - editing: 是否开启编辑
    ///   - animated: 是否显示动画过程
    @objc func updateEditing(_ editing: Bool, animated: Bool) {
        func __updateEditing(_ editing: Bool) {
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
            rect = bounds
            rect.origin.x = -editingView.frame.width
            contentView.frame = rect
        }
        willBeginUpdateEditing(editing, animated: animated)
        if animated {
            let completionHandler: (Bool)->Void = { [weak self] _ in
                guard let self = self else { return }
                self.tableView?.isEdit = editing
                self.didEndUpdateEditing(editing, animated: animated)
            }
            if editing {
                UIView.animate(withDuration: 0.7, delay: 0.0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1.0, options: [.beginFromCurrentState, .curveEaseInOut], animations: {
                    __updateEditing(true)
                }, completion: completionHandler)
            } else {
                UIView.animate(withDuration: 0.3, delay: 0.0, options: [.beginFromCurrentState, .curveEaseInOut], animations: {
                    __updateEditing(false)
                }, completion: completionHandler)
            }
        } else {
            __updateEditing(editing)
            tableView?.isEdit = false
            didEndUpdateEditing(editing, animated: animated)
        }
    }
}

@objc extension UITableViewCell {
    
    @objc func willBeginUpdateEditing(_ editing: Bool, animated: Bool) {}
    @objc func didEndUpdateEditing(_ editing: Bool, animated: Bool) {}
}

@objc extension UITableViewCell {
    
    var indexPath: IndexPath? { tableView?.indexPath(for: self) }
    
    @objc var tableView: UITableView! {
        var responder = next
        while let res = responder {
            if res is UITableView { return res as? UITableView }
            responder = res.next
        }
        return nil
    }
}
