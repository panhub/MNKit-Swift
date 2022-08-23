//
//  UITableView+MNEditing.swift
//  MNTest
//
//  Created by 冯盼 on 2022/8/22.
//

import UIKit
import Foundation
import ObjectiveC.runtime

@objc extension UITableView {
    
    private struct EditingAssociated {
        static var editing = "com.mn.table.view.editing"
        static var options = "com.mn.table.view.editing.options"
        static var observer = "com.mn.table.view.editing.observer"
    }
    
    @objc var options: UITableViewEditingOptions {
        if let options = objc_getAssociatedObject(self, &EditingAssociated.options) as? UITableViewEditingOptions { return options }
        if objc_getAssociatedObject(self, &EditingAssociated.observer) == nil {
            let observer = UITableViewEditingObserver(tableView: self, delegate: self)
            objc_setAssociatedObject(self, &EditingAssociated.observer, observer, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        let options = UITableViewEditingOptions()
        objc_setAssociatedObject(self, &EditingAssociated.options, options, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        return options
    }
    
    @objc var isScrollEditing: Bool {
        get { objc_getAssociatedObject(self, &EditingAssociated.editing) as? Bool ?? false }
        set { objc_setAssociatedObject(self, &EditingAssociated.editing, newValue, .OBJC_ASSOCIATION_ASSIGN) }
    }
    
    @objc func endEditing(animated: Bool) {
        for cell in visibleCells {
            if cell.isScrollEditing {
                cell.updateEditing(false, animated: animated)
            }
        }
    }
}

// MARK: - UITableViewEditingObserverHandler
extension UITableView: UITableViewEditingObserverHandler {
    
    func tableView(_ tableView: UITableView, contentOffset change: [NSKeyValueChangeKey : Any]?) {
        guard isScrollEditing else { return }
        isScrollEditing = false
        endEditing(animated: (tableView.isDragging || tableView.isDecelerating))
    }
}
