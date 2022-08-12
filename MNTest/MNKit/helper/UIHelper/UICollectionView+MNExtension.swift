//
//  UICollectionView+MNExtension.swift
//  MNTest
//
//  Created by 冯盼 on 2022/8/13.
//

import UIKit

// MARK: - UICollectionView
public extension UICollectionView {
    
    /// 实例化CollectionView
    /// - Parameters:
    ///   - frame: 位置
    ///   - layout: 约束对象
    convenience init(frame: CGRect, layout: UICollectionViewLayout) {
        self.init(frame: frame, collectionViewLayout: layout)
        backgroundColor = UIColor.white
        keyboardDismissMode = .onDrag
        if #available(iOS 11.0, *) {
            contentInsetAdjustmentBehavior = .never;
        }
    }
}
