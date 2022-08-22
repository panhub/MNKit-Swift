//
//  UITableViewCellObserver.swift
//  MNTest
//
//  Created by 冯盼 on 2022/8/22.
//  针对UITableViewCell编辑的监听

import UIKit

class UITableViewCellContentObserver: NSObject {
    
    var action: Selector?
    
    weak var cell: UITableViewCell?
    
    weak var target: NSObjectProtocol?
    
    override init() {
        super.init()
    }
    
    convenience init(cell: UITableViewCell, target: NSObjectProtocol, action: Selector) {
        self.init()
        self.cell = cell
        self.target = target
        self.action = action
        cell.contentView.addObserver(self, forKeyPath: "frame", options: .new, context: nil)
    }
    
    deinit {
        removeObserver()
    }
    
    func removeObserver() {
        guard let cell = cell else { return }
        cell.contentView.removeObserver(self, forKeyPath: "frame")
        self.cell = nil
        self.target = nil
        self.action = nil
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if let target = target, let action = action {
            target.perform(action)
        }
    }
}
