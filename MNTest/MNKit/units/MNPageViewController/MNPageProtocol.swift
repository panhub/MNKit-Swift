//
//  MNPageProtocol.swift
//  anhe
//
//  Created by 冯盼 on 2022/5/29.
//

import UIKit
import Foundation

@objc protocol MNPageViewProtocol: NSObjectProtocol {
    
}

@objc protocol MNPageSegmentDataSource: NSObjectProtocol {
    /// 标题集合
    @objc var subpageTitles: [String] { get }
    /// 导航左视图
    @objc optional var segmentLeftView: UIView? { get }
    /// 导航右视图
    @objc optional var segmentRightView: UIView? { get }
}


@objc protocol MNPageViewControllerDataSource: MNPageSegmentDataSource {
    
    @objc optional func pageViewControllerHeaderView(_ pageViewController: MNPageViewController) -> UIView?
}

protocol MNPageViewControllerDelegate: NSObjectProtocol {
    
}

protocol MNPageScrollDelegate: NSObjectProtocol {
    
    func subpage(_ subpage: MNSubpageContainer, didScroll offset: CGPoint) -> Void
    
    //func pageController(_ pageController: MNPageScrollController, willLeave subpage: MNSubpageContainer?, to subpage: MNSubpageContainer?) -> Void
    
    func subpageWillAppear(_ subpage: MNSubpageContainer?, animated: Bool) -> Void
    
    func subpageDidAppear(_ subpage: MNSubpageContainer?, animated: Bool) -> Void
    
    func subpageWillDisappear(_ subpage: MNSubpageContainer?, animated: Bool) -> Void
    
    func subpageDidDisappear(_ subpage: MNSubpageContainer?, animated: Bool) -> Void
    
    func pageController(_ pageController: MNPageScrollController, didScroll ratio: CGFloat, dragging isDragging: Bool) -> Void
}

protocol MNPageScrollDataSource: MNPageViewProtocol {
    
    /// 页面数量
    var numberOfPages: Int { get }
    
    /// 当前界面的偏移
    var currentPageOffset: CGFloat { get }
    
    /// 页面顶部插入高度
    var pageTopInset: CGFloat { get }
    
    /// 界面最大偏移
    var pageMaxOffset: CGFloat { get }
    
    /// 获取指定索引的页面
    /// - Parameter index: 指定索引
    /// - Returns: 子页面
    func subpage(index: Int) -> MNSubpageContainer?
}

/// 子界面代理
@objc protocol MNSubpageDataSource: NSObjectProtocol {
    
    /// ScrollView
    @objc var subpageScrollView: UIScrollView { get }
    
    @objc optional func subpage(scrollView: UIScrollView, appendedTopInset inset: CGFloat) -> Void
    
    @objc optional func subpage(scrollView: UIScrollView, guessMinContentSize contentSize: CGSize) -> Void
}
