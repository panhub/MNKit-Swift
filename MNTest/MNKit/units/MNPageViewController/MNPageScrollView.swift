//
//  MNPageScrollView.swift
//  anhe
//
//  Created by 冯盼 on 2022/5/27.
//  分页滑动支持

import UIKit

class MNPageScrollView: UIScrollView {
    
    /// 页数
    var numberOfPages: Int = 1 {
        didSet {
            var contentSize = frame.size
            contentSize.height = frame.height
            contentSize.width = frame.width*CGFloat(max(numberOfPages, 1))
            self.contentSize = contentSize
        }
    }
    
    /// 当前页码
    var pageIndex: Int {
        let x = contentOffset.x
        let w = frame.width
        let index: Int = Int(round(x/w))
        return min(max(0, index), numberOfPages)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        bounces = false
        scrollsToTop = false
        isPagingEnabled = true
        contentSize = frame.size
        showsVerticalScrollIndicator = false
        showsHorizontalScrollIndicator = false
        if #available(iOS 11.0, *) {
            contentInsetAdjustmentBehavior = .never
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// 显示页码的横向偏移
    /// - Parameter pageIndex: 页码
    /// - Returns: 横向偏移
    func offsetX(pageIndex: Int) -> CGFloat { frame.width*CGFloat(pageIndex) }
    
    /// 设置指定页码偏移量
    /// - Parameter pageIndex: 页码
    func setOffsetX(pageIndex: Int) {
        let x = offsetX(pageIndex: pageIndex)
        setContentOffset(CGPoint(x: x, y: 0.0), animated: false)
    }
}
