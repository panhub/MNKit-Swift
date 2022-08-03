//
//  UIEdgeInsets+MNExtension.swift
//  MNFoundation
//
//  Created by 冯盼 on 2021/12/21.
//

import UIKit
import Foundation

extension UIEdgeInsets {
    
    /// 约束
    /// - Parameter inset: 边距
    init(all inset: CGFloat) {
        self.init(top: inset, left: inset, bottom: inset, right: inset)
    }
}
