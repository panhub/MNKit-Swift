//
//  UITableViewCellObserver.swift
//  MNTest
//
//  Created by 冯盼 on 2022/8/22.
//  针对UITableViewCell编辑的监听

import UIKit

protocol UITableViewEditingObserverHandler: NSObjectProtocol {
    
    /// 表格偏移改变
    /// - Parameters:
    ///   - tableView: 表格集合控件
    ///   - change: 偏移变化
    func tableView(_ tableView: UITableView, contentOffset change: [NSKeyValueChangeKey : Any]?) -> Void
}

class UITableViewEditingObserver: NSObject {
    
    weak var tableView: UITableView?
    
    weak var delegate: UITableViewEditingObserverHandler?
    
    override init() {
        super.init()
    }
    
    convenience init(tableView: UITableView, delegate: UITableViewEditingObserverHandler?) {
        self.init()
        self.delegate = delegate
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
        if let tableView = tableView {
            delegate?.tableView(tableView, contentOffset: change)
        }
    }
}
