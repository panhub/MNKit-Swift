//
//  UICollectionView+MNEditing.swift
//  MNTest
//
//  Created by 冯盼 on 2022/8/26.
//

import UIKit
import Foundation
import ObjectiveC.runtime

extension UICollectionView {
    
    private struct EditingAssociated {
        static var editing = "com.mn.table.view.editing"
        static var options = "com.mn.table.view.editing.options"
        static var observer = "com.mn.table.view.editing.observer"
    }
    
    /// 编辑视图的配置
    @objc var editingOptions: MNEditingOptions {
        if let options = objc_getAssociatedObject(self, &EditingAssociated.options) as? MNEditingOptions { return options }
        if objc_getAssociatedObject(self, &EditingAssociated.observer) == nil {
            let observer = MNEditingObserver(scrollView: self, delegate: self)
            objc_setAssociatedObject(self, &EditingAssociated.observer, observer, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        let options = MNEditingOptions()
        objc_setAssociatedObject(self, &EditingAssociated.options, options, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        return options
    }
    
    /// 是否有表格处于编辑状态
    @objc var isHaulEditing: Bool {
        get { objc_getAssociatedObject(self, &EditingAssociated.editing) as? Bool ?? false }
        set { objc_setAssociatedObject(self, &EditingAssociated.editing, newValue, .OBJC_ASSOCIATION_ASSIGN) }
    }
    
    /// 结束编辑
    /// - Parameter animated: 是否动态显示过程
    @objc func endEditing(animated: Bool) {
        for cell in visibleCells {
            guard cell.isHaulEditing else { continue }
            cell.updateEditing(false, animated: animated)
        }
    }
}

// MARK: - MNEditingObserverHandler
extension UICollectionView: MNEditingObserverHandler {
    
    func scrollView(_ scrollView: UIScrollView, contentOffset change: [NSKeyValueChangeKey : Any]?) {
        guard isHaulEditing else { return }
        isHaulEditing = false
        endEditing(animated: (scrollView.isDragging || scrollView.isDecelerating))
    }
}

