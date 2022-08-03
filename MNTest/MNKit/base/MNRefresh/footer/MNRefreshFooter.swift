//
//  MNRefreshFooter.swift
//  MNFoundation
//
//  Created by 冯盼 on 2021/8/18.
//  加载更多

import UIKit

class MNRefreshFooter: MNRefresh {
    /**是否是无更多数据状态*/
    @objc var isNoMoreData: Bool { state == .noMoreData }
    /**底部修改的差值*/
    @objc private(set) var delta: CGFloat = 0.0
    /**刷新前内容高度*/
    @objc private(set) var lastContentHeight: CGFloat = 0.0
    /**忽略的底部偏移*/
    @objc var offsetY: CGFloat = 0.0 {
        didSet {
            scrollView(contentSizeDidChange: nil)
        }
    }
    
    /**初始化*/
    override func initialized() {
        super.initialized()
        height = MN_TAB_BAR_HEIGHT + (style == .margin ? MN_TAB_SAFE_HEIGHT : 0.0)
    }
    
    override func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)
        scrollView(contentSizeDidChange: nil)
    }
    
    override func scrollView(contentOffsetDidChange change: [NSKeyValueChangeKey : Any]?) {
        super.scrollView(contentOffsetDidChange: change)
        
        // 处于刷新状态不做操作
        guard state != .refreshing, let scrollView = self.scrollView else { return }
        
        // 刷新四周约束
        originalInset = scrollView.inset_mn
        
        // 如果是无数据状态不做操作
        guard state != .noMoreData else { return }
        
        // 当前偏移
        let offsetY = scrollView.offsetY_mn
        // 刚好看到控件的偏移
        let happenOffsetY = happenOffsetY
        
        // 如果是向下滚动到看不见尾部控件 直接返回
        guard offsetY >= happenOffsetY else { return }
        
        // 普通和即将加载的临界点
        let pullingOffsetY = happenOffsetY + height
        
        // 更新滑动比率
        if offsetY <= pullingOffsetY {
            refreshFooter(didChangePercent: (offsetY - happenOffsetY)/height)
        }
        
        // 更新状态
        if scrollView.isDragging {
            if state == .normal, offsetY > pullingOffsetY {
                // 置为即将刷新状态
                refreshFooter(didChangePercent: 1.0)
                state = .pulling
            } else if state == .pulling, offsetY <= pullingOffsetY {
                // 置为普通状态
                state = .normal
            }
        } else if state == .pulling {
            // 开始加载
            beginRefresh()
        }
    }
    
    override func scrollView(contentSizeDidChange change: [NSKeyValueChangeKey : Any]?) {
        super.scrollView(contentSizeDidChange: change)
        guard let scrollView = self.scrollView else { return }
        // 更新位置
        minY = max(scrollView.contentH_mn, scrollView.frame.height - originalInset.top - originalInset.bottom) + offsetY
    }
    
    override var state: MNRefresh.RefreshState {
        get { super.state }
        set {
            let old = super.state
            guard newValue != old else { return }
            super.state = newValue
            refreshFooter(didChangeState: old, to: newValue)
            if newValue == .normal || newValue == .noMoreData {
                if old == .refreshing {
                    // 刷新结束
                    UIView.animate(withDuration: MNRefresh.slowAnimationDuration) { [weak self] in
                        guard let self = self, let scrollView = self.scrollView else { return }
                        scrollView.insetB_mn -= self.delta
                    } completion: { [weak self] _ in
                        // 回调结束刷新
                        self?.callbackEndRefreshing()
                    }
                    // 判断是否需要回滚
                    if let scrollView = self.scrollView, self.heightForContentBreakView > 0.1, abs(scrollView.contentH_mn - self.lastContentHeight) > 0.1 {
                        scrollView.offsetY_mn = scrollView.offsetY_mn
                    }
                }
            } else if newValue == .refreshing {
                // 开始刷新
                if let scrollView = self.scrollView {
                    self.lastContentHeight = scrollView.contentH_mn
                }
                UIView.animate(withDuration: MNRefresh.fastAnimationDuration) { [weak self] in
                    guard let self = self, let scrollView = self.scrollView else { return }
                    var bottom = self.height + self.originalInset.bottom
                    let deltaH = self.heightForContentBreakView
                    if deltaH < 0.0 {
                        bottom -= deltaH
                    }
                    self.delta = bottom - scrollView.insetB_mn
                    scrollView.insetB_mn = bottom
                    scrollView.offsetY_mn = self.happenOffsetY + self.height
                } completion: { [weak self] _ in
                    // 回调开始刷新
                    self?.callbackRefreshing()
                }
            }
        }
    }
    
    /**滑动比率改变*/
    @objc func refreshFooter(didChangePercent percent: CGFloat) {}
    /**状态改变*/
    @objc func refreshFooter(didChangeState old: MNRefresh.RefreshState, to: MNRefresh.RefreshState) {}
}

// MARK: - 公共方法
extension MNRefreshFooter {
    /**结束刷新并解除刷新能力*/
    @objc func endRefreshingWithNoMoreData() {
        DispatchQueue.main.async { [weak self] in
            self?.state = .noMoreData
        }
    }
    /**解除没有更多数据状态*/
    @objc func resetNoMoreData() {
        guard state == .noMoreData else { return }
        DispatchQueue.main.async { [weak self] in
            self?.state = .normal
        }
    }
}

// MARK: - 辅助方法
private extension MNRefreshFooter {
    // scrollView的内容超出view的高度
    @objc var heightForContentBreakView: CGFloat {
        return scrollView!.contentSize.height - scrollView!.bounds.inset(by: originalInset).height
    }
    //刚好看到上拉刷新控件时的contentOffset.y
    @objc var happenOffsetY: CGFloat {
        let deltaH = heightForContentBreakView
        if deltaH > 0.0 {
            return deltaH - originalInset.top
        }
        return -originalInset.top
    }
}
