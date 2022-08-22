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
        static var options = "com.mn.table.view.editing.options"
    }
    
    @objc var options: UITableViewEditingOptions {
        if let options = objc_getAssociatedObject(self, &EditingAssociated.options) as? UITableViewEditingOptions { return options }
        let options = UITableViewEditingOptions()
        objc_setAssociatedObject(self, &EditingAssociated.options, delegate, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        return options
    }
    
    
}
