//
//  UITableViewCellObserver.swift
//  MNTest
//
//  Created by 冯盼 on 2022/8/22.
//  针对UITableViewCell编辑的监听

import UIKit

class UITableViewCellObserver: NSObject {
    
    weak var cell: UITableViewCell?
    
    var keyPath: String = ""
    
    var options: NSKeyValueObservingOptions = .new
    
    private var action: Selector?
    
    private weak var target: NSObjectProtocol?
    
    override init() {
        super.init()
    }
    
    convenience init(cell: UITableViewCell, keyPath: String, options: NSKeyValueObservingOptions = .new) {
        self.init()
        self.cell = cell
        self.options = options
        self.keyPath = keyPath
        cell.contentView.addObserver(self, forKeyPath: keyPath, options: options, context: nil)
    }
    
    deinit {
        removeObserver()
    }
    
    func addTarget(_ target: NSObjectProtocol, action: Selector) {
        self.target = target
        self.action = action
    }
    
    func removeObserver() {
        guard let cell = cell else { return }
        cell.contentView.removeObserver(self, forKeyPath: keyPath)
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
