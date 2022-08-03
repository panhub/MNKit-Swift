//
//  MNRefreshHeader.swift
//  MNFoundation
//
//  Created by 冯盼 on 2021/8/18.
//  下拉刷新视图

import UIKit

class MNRefreshHeader: MNRefresh {
    /**inset顶部修改的差值*/
    private(set) var delta: CGFloat = 0.0
    /**外界调整入口*/
    @objc var offsetY: CGFloat = 0.0 {
        didSet {
            guard let _ = scrollView else { return }
            minY = offsetY - height
        }
    }
    /**初始化*/
    override func initialized() {
        super.initialized()
        height = MN_NAV_BAR_HEIGHT + (style == .margin ? MN_STATUS_BAR_HEIGHT : 0.0)
    }
    
    override func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)
        guard let _ = newSuperview else { return }
        minY = offsetY - height
    }
    
    override func scrollView(contentOffsetDidChange change: [NSKeyValueChangeKey : Any]?) {
        super.scrollView(contentOffsetDidChange: change)
        
        guard let scrollView = self.scrollView else { return }
        
        if state == .refreshing {
            guard let _ = window else { return }
            // 解决停留问题
            let insetT = min(max(-scrollView.offsetY_mn, originalInset.top), height + originalInset.top)
            scrollView.insetT_mn = insetT
            delta = originalInset.top - insetT
            return
        }
        
        // contentInset可能会随时变
        originalInset = scrollView.inset_mn
        
        // 当前的偏移
        let offsetY = scrollView.offsetY_mn
        // 控件刚好出现(正常状态下)的offsetY
        let happenOffsetY = -originalInset.top
        
        // 如果是向上滚动到看不见头部控件，直接返回
        guard offsetY <= happenOffsetY else { return }
        
        // 普通和即将刷新的临界点
        let pullingOffsetY = happenOffsetY - height
        
        // 更新滑动比率
        if offsetY >= pullingOffsetY {
            refreshHeader(didChangePercent: (happenOffsetY - offsetY)/height)
        }
        
        // 更新状态
        if scrollView.isDragging {
            if state == .normal, offsetY < pullingOffsetY {
                // 置为即将刷新状态
                refreshHeader(didChangePercent: 1.0)
                state = .pulling
            } else if state == .pulling, offsetY >= pullingOffsetY {
                // 置为普通状态
                state = .normal
            }
        } else if state == .pulling {
            // 松手就开始刷新
            beginRefresh()
        }
    }
    
    override var state: MNRefresh.RefreshState {
        get { super.state }
        set {
            let old = super.state
            guard newValue != old else { return }
            super.state = newValue
            refreshHeader(didChangeState: old, to: newValue)
            if newValue == .normal {
                guard old == .refreshing else { return }
                // 恢复视图原始状态
                UIView.animate(withDuration: MNRefresh.slowAnimationDuration) { [weak self] in
                    guard let self = self else { return }
                    self.scrollView?.insetT_mn += self.delta
                } completion: { [weak self] _ in
                    // 回调结束刷新
                    self?.callbackEndRefreshing()
                }
            } else if newValue == .refreshing {
                // 开始刷新
                UIView.animate(withDuration: MNRefresh.fastAnimationDuration) { [weak self] in
                    guard let self = self, let scrollView = self.scrollView else { return }
                    let insetT = self.originalInset.top + self.height
                    scrollView.insetT_mn = insetT
                    scrollView.offsetY_mn = -insetT
                } completion: { [weak self] _ in
                    // 回调开始刷新
                    self?.callbackRefreshing()
                }
            }
        }
    }
    
    /**滑动比率改变*/
    @objc func refreshHeader(didChangePercent percent: CGFloat) {}
    /**状态改变*/
    @objc func refreshHeader(didChangeState old: MNRefresh.RefreshState, to: MNRefresh.RefreshState) {}
}
