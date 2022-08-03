//
//  MNRefresh.swift
//  MNFoundation
//
//  Created by 冯盼 on 2021/10/8.
//  资源管理

import UIKit
import Foundation
import CoreGraphics

typealias MNRefreshEventHandler = ()->Void

@objc class MNRefresh: UIView {
    /**刷新状态*/
    @objc enum RefreshState: Int {
        case normal, pulling, refreshing, willRefresh, noMoreData
    }
    /**外观样式*/
    @objc enum RefreshStyle: Int {
        case normal
        case margin
    }
    /**外观颜色*/
    @objc enum RefreshColor: Int {
        case light, dark
    }
//    /**安全区域范围*/
//    @objc static let SafeAreaInsets: UIEdgeInsets = {
//        var inset: UIEdgeInsets = .zero
//        if #available(iOS 11.0, *) {
//            inset = UIWindow().safeAreaInsets
//        }
//        return inset
//    }()
//    /**状态栏高度*/
//    @objc static let StatusBarHeight: CGFloat = UIApplication.shared.statusBarFrame.height
//    /**导航栏高度*/
//    @objc static let NavBarHeight: CGFloat = UINavigationController().navigationBar.frame.height
//    /**标签栏安全区高度*/
//    @objc static let TabSafeHeight: CGFloat = MNRefresh.SafeAreaInsets.bottom
//    /**标签栏+安全区高度*/
//    @objc static let TabBarHeight: CGFloat = UITabBarController().tabBar.frame.height
    /**记录父视图*/
    private(set) weak var scrollView: UIScrollView?
    /**缓慢的动画时间*/
    @objc static let slowAnimationDuration: TimeInterval = 0.4
    /**快速的动画时间*/
    @objc static let fastAnimationDuration: TimeInterval = 0.25
    // 定义颜色
    @objc var color: UIColor = .black
    // 定义样式
    @objc var style: RefreshStyle = .normal
    /**是否在刷新*/
    @objc var isRefreshing: Bool { state == .refreshing }
    /**开始刷新回调*/
    @objc var beginRefreshingHandler: MNRefreshEventHandler?
    /**结束刷新回调*/
    @objc var endRefreshingHandler: MNRefreshEventHandler?
    /**当前状态*/
    var state: RefreshState = .normal
    /**原控件内容约束*/
    var originalInset: UIEdgeInsets = .zero
    /**刷新方法*/
    private var action: Selector?
    /**回调对象*/
    private weak var target: NSObjectProtocol?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initialized()
    }
    
    @objc public init(style: RefreshStyle) {
        super.init(frame: .zero)
        self.style = style
        initialized()
    }
    
    @objc public init(style: RefreshStyle, target: NSObjectProtocol, action: Selector) {
        super.init(frame: .zero)
        self.style = style
        addTarget(target, action: action)
        initialized()
    }
    
    @objc func initialized() {
        backgroundColor = UIColor.clear
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func addTarget(_ target: NSObjectProtocol, action: Selector) {
        self.target = target
        self.action = action
    }
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        guard let scrollView = superview as? UIScrollView else { return }
        maxY = -0.0
        width = scrollView.width
        // 记录UIScrollView最开始的contentInset
        originalInset = scrollView.inset_mn
        // 设置永远支持垂直弹簧效果
        scrollView.alwaysBounceVertical = true
        // 开始监听
        scrollView.addObserver(self, forKeyPath: "contentSize", options: [.old, .new], context: nil)
        scrollView.addObserver(self, forKeyPath: "contentOffset", options: [.old, .new], context: nil)
        // 记录UIScrollView
        self.scrollView = scrollView
        // 通知即将添加到scrollView
        didMove(toScrollView: scrollView)
    }
    
    override func removeFromSuperview() {
        if let scrollView = superview as? UIScrollView {
            // 删除监听
            scrollView.removeObserver(self, forKeyPath: "contentSize")
            scrollView.removeObserver(self, forKeyPath: "contentOffset")
            self.scrollView = nil
            // 通知即将从scrollView中移除
            willRemove(fromScrollView: scrollView)
        }
        super.removeFromSuperview()
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        // 避免还没有出现就已经是刷新状态
        if state == .willRefresh {
            state = .refreshing
        }
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard let _ = keyPath else { return }
        if keyPath! == "contentSize" {
            scrollView(contentSizeDidChange: change)
        } else if isHidden == false, keyPath! == "contentOffset" {
            scrollView(contentOffsetDidChange: change)
        }
    }
    
    /**内容尺寸发生变化*/
    @objc func scrollView(contentSizeDidChange change: [NSKeyValueChangeKey : Any]?) {}
    /**偏移量发生变化*/
    @objc func scrollView(contentOffsetDidChange change: [NSKeyValueChangeKey : Any]?) {}
    /**即将移动到视图*/
    @objc func didMove(toScrollView scrollView: UIScrollView) {}
    /**即将从视图中删除*/
    @objc func willRemove(fromScrollView scrollView: UIScrollView) {}
}

// MARK: - 开始/停止刷新
extension MNRefresh {
    func beginRefresh() {
        if let _ = self.window {
            // 在屏幕上
            state = .refreshing
        } else {
            // 未在屏幕上
            guard state != .refreshing, state != .willRefresh else { return }
            state = .willRefresh
            setNeedsDisplay()
        }
    }
    
    @objc func endRefreshing() {
        DispatchQueue.main.async { [weak self] in
            self?.state = .normal
        }
    }
}

// MARK: - 回调事件
extension MNRefresh {
    func callbackRefreshing() {
        if let target = target, let action = action {
            target.perform(action)
        }
        beginRefreshingHandler?()
    }
    
    func callbackEndRefreshing() {
        endRefreshingHandler?()
    }
}
