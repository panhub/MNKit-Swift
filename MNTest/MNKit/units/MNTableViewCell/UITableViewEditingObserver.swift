//
//  UITableViewCellObserver.swift
//  MNTest
//
//  Created by 冯盼 on 2022/8/22.
//  针对UITableViewCell编辑的监听

import UIKit

class UITableViewEditingObserver: NSObject {
    
    weak var tableView: UITableView?
    
    override init() {
        super.init()
    }
    
    convenience init(tableView: UITableView) {
        self.init()
        self.tableView = tableView
        tableView.addObserver(self, forKeyPath: "contentOffset", options: .new, context: nil)
    }
    
    deinit {
        if let tableView = tableView {
            tableView.removeObserver(self, forKeyPath: "contentOffset")
            self.tableView = nil
        }
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if let tableView = tableView, tableView.isEdit {
            tableView.isEdit = false
            tableView.endEditing(animated: (tableView.isDragging || tableView.isDecelerating))
        }
    }
}
