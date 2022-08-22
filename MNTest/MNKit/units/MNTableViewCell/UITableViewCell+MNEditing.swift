//
//  UITableViewCell+MNEditing.swift
//  MNTest
//
//  Created by 冯盼 on 2022/8/22.
//  对UITableViewCell编辑支持

import UIKit
import Foundation
import ObjectiveC.runtime

fileprivate extension UIGestureRecognizer {
    
    struct EditingKey {
        static var editingLabel = "com.mn.recognizer.editing.label"
    }
    
    var editingLabel: String {
        get { (objc_getAssociatedObject(self, &EditingKey.editingLabel) as? String) ?? "" }
        set { objc_setAssociatedObject(self, &EditingKey.editingLabel, newValue, .OBJC_ASSOCIATION_COPY) }
    }
}

@objc extension UITableViewCell {
    
    private struct EditingKey {
        static var allowsEditing = "com.mn.table.view.cell.allows.editing"
        static var contentObserver = "com.mn.table.view.cell.content.observer"
    }
    
    private var contentObserver: UITableViewCellObserver? {
        get { objc_getAssociatedObject(self, &EditingKey.contentObserver) as? UITableViewCellObserver }
        set { objc_setAssociatedObject(self, &EditingKey.contentObserver, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
    
    
    @objc var allowsEditing: Bool {
        get { (objc_getAssociatedObject(self, &EditingKey.allowsEditing) as? Bool) ?? false }
        set {
            if allowsEditing == newValue { return }
            objc_setAssociatedObject(self, &EditingKey.allowsEditing, newValue, .OBJC_ASSOCIATION_ASSIGN)
            if newValue {
                let pan = UIPanGestureRecognizer(target: self, action: #selector(handleCellEditing(_:)))
                pan.delegate = self
                pan.editingLabel = "com.mn.table.cell.recognizer.label"
                contentView.addGestureRecognizer(pan)
                let observer = UITableViewCellObserver(cell: self, keyPath: "frame")
                observer.addTarget(self, action: #selector(contentViewFrameChanged))
                contentObserver = observer
            } else {
                guard let gestureRecognizers = contentView.gestureRecognizers else { return }
                for recognizer in gestureRecognizers.filter ({ $0.editingLabel == "com.mn.table.cell.recognizer.label" }) {
                    recognizer.removeTarget(nil, action: nil)
                    contentView.removeGestureRecognizer(recognizer)
                }
                if let contentObserver = contentObserver {
                    contentObserver.removeObserver()
                    self.contentObserver = nil
                }
            }
        }
    }
    
    @objc private func handleCellEditing(_ recognizer: UIPanGestureRecognizer) {
        
    }
    
    @objc private func contentViewFrameChanged() {
        
    }
}

@objc extension UITableViewCell {
    
    
    
}
