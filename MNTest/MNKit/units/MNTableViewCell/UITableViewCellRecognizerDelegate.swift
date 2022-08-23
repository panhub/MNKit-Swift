//
//  UITableViewCellPanDelegate.swift
//  MNTest
//
//  Created by 冯盼 on 2022/8/22.
//

import UIKit

class UITableViewCellRecognizerDelegate: NSObject, UIGestureRecognizerDelegate {
    
    var action: Selector?
    
    weak var target: NSObjectProtocol?
    
    override init() {
        super.init()
    }
    
    convenience init(target: NSObjectProtocol, action: Selector) {
        self.init()
        self.target = target
        self.action = action
    }
    
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let recognizer = gestureRecognizer as? UIPanGestureRecognizer else { return false }
        guard recognizer.editingLabel == UIGestureRecognizer.TableViewCellEditingLabel else { return false }
        // 判断方向
        let translation = recognizer.translation(in: recognizer.view)
        guard abs(translation.y) <= abs(translation.x) else { return false }
        // 判断是否在编辑状态
        guard let target = target, let action = action else { return false }
        guard let _ = target.perform(action) else { return false }
        //print(obj)
//        var obj = target.perform(action)
//        guard let flag = Unmanaged<AnyObject>.fromOpaque(obj).takeUnretainedValue() as? Bool else { return false }
        return true
    }
}
