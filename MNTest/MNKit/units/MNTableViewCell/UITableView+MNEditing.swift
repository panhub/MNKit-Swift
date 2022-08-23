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
        let options = UITableViewEditingOptions()
        objc_setAssociatedObject(self, &EditingAssociated.options, options, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        let observer = UITableViewEditingObserver(tableView: self)
        objc_setAssociatedObject(self, &EditingAssociated.observer, observer, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        return options
    }
    
    @objc var isEdit: Bool {
        get { objc_getAssociatedObject(self, &EditingAssociated.editing) as? Bool ?? false }
        set { objc_setAssociatedObject(self, &EditingAssociated.editing, newValue, .OBJC_ASSOCIATION_ASSIGN) }
    }
    
    @objc func endEditing(animated: Bool) {
        for cell in visibleCells {
            if cell.isEdit {
                cell.updateEditing(false, animated: animated)
            }
        }
    }
}
