//
//  UIScrollView+MNHelper.swift
//  MNFoundation
//
//  Created by 冯盼 on 2021/8/5.
//

import UIKit
import Foundation

public extension UIScrollView {
    /**调整滚动视图的行为*/
    func neverAdjustmentBehavior() {
        if #available(iOS 11.0, *) {
            contentInsetAdjustmentBehavior = .never;
        }
    }
}

// MARK: - 滑动至边缘
public extension UIScrollView {
    
    func scrollToTop(animated: Bool = true) {
        var offset = contentOffset
        offset.y = -contentInset.top
        setContentOffset(offset, animated: animated)
    }
    
    func scrollToBottom(animated: Bool = true) {
        var offset = contentOffset
        offset.y = contentSize.height - frame.height + contentInset.bottom
        setContentOffset(offset, animated: animated)
    }
    
    func scrollToLeft(animated: Bool = true) {
        var offset = contentOffset
        offset.x = -contentInset.left
        setContentOffset(offset, animated: animated)
    }
    
    func scrollToRight(animated: Bool = true) {
        var offset = contentOffset
        offset.x = contentSize.width - frame.width + contentInset.right
        setContentOffset(offset, animated: animated)
    }
}
