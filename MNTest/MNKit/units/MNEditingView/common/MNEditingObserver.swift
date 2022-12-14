//
//  UITableViewCellObserver.swift
//  MNTest
//
//  Created by 冯盼 on 2022/8/22.
//  针对偏移改变的监听以取消编辑状态

import UIKit

protocol MNEditingObserverHandler: NSObjectProtocol {
    
    /// 表格偏移改变
    /// - Parameters:
    ///   - tableView: 表格集合控件
    ///   - change: 偏移变化
    func scrollView(_ scrollView: UIScrollView, contentOffset change: [NSKeyValueChangeKey : Any]?) -> Void
}

class MNEditingObserver: NSObject {
    
    /// 事件通知代理
    weak var delegate: MNEditingObserverHandler?
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard let scrollView = object as? UIScrollView else { return }
        delegate?.scrollView(scrollView, contentOffset: change)
    }
}
