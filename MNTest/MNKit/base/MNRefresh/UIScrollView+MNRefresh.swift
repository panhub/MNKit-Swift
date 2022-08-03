//
//  UIScrollView+MNRefresh.swift
//  MNFoundation
//
//  Created by 冯盼 on 2021/8/18.
//  UIScrollView处理

import UIKit
import ObjectiveC.runtime

// MARK: - 简化操作
extension UIScrollView {
    
    /**四周预留*/
    var inset_mn: UIEdgeInsets {
        if #available(iOS 11.0, *) {
            return adjustedContentInset
        }
        return contentInset
    }
    
    /**内容高度*/
    var contentH_mn: CGFloat {
        return contentSize.height
    }
    
    /**偏移*/
    var offsetY_mn: CGFloat {
        get { contentOffset.y }
        set {
            var offset = contentOffset
            offset.y = newValue
            contentOffset = offset
        }
    }
    
    /**顶部预留*/
    var insetT_mn: CGFloat {
        get { inset_mn.top }
        set {
            var inset = contentInset
            inset.top = newValue
            if #available(iOS 11.0, *) {
                inset.top -= (adjustedContentInset.top - contentInset.top)
            }
            contentInset = inset
        }
    }
    
    /**底部预留*/
    var insetB_mn: CGFloat {
        get { inset_mn.bottom }
        set {
            var inset = contentInset
            inset.bottom = newValue
            if #available(iOS 11.0, *) {
                inset.bottom -= (adjustedContentInset.bottom - contentInset.bottom)
            }
            contentInset = inset
        }
    }
}

// MARK: - 快速添加
extension UIScrollView {
    
    private struct RefreshAssociatedKey {
        static var footer = "com.mn.scroll.view.load.footer"
        static var header = "com.mn.scroll.view.refresh.header"
    }
    
    var refresh_header: MNRefreshHeader? {
        get { objc_getAssociatedObject(self, &RefreshAssociatedKey.header) as? MNRefreshHeader }
        set {
            let header = refresh_header
            if newValue == nil, header == nil { return }
            if let _ = newValue, let _ = header, newValue! == header! { return }
            header?.removeFromSuperview()
            if let _ = newValue {
                insertSubview(newValue!, at: 0)
            }
            willChangeValue(forKey: "refresh_header")
            objc_setAssociatedObject(self, &RefreshAssociatedKey.header, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            didChangeValue(forKey: "refresh_header")
        }
    }
    
    var load_footer: MNRefreshFooter? {
        get { objc_getAssociatedObject(self, &RefreshAssociatedKey.footer) as? MNRefreshFooter }
        set {
            let footer = load_footer
            if newValue == nil, footer == nil { return }
            if let _ = newValue, let _ = footer, newValue! == footer! { return }
            footer?.removeFromSuperview()
            if let _ = newValue {
                insertSubview(newValue!, at: 0)
            }
            willChangeValue(forKey: "load_footer")
            objc_setAssociatedObject(self, &RefreshAssociatedKey.footer, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            didChangeValue(forKey: "load_footer")
        }
    }
    
    @objc func setRefreshHeader(_ header: MNRefreshHeader?) {
        refresh_header = header
    }
    
    @objc func setRefreshFooter(_ footer: MNRefreshFooter?) {
        load_footer = footer
    }
    
    @objc func endRefreshing() {
        refresh_header?.endRefreshing()
    }
    
    @objc func endLoadMore() {
        load_footer?.endRefreshing()
    }
    
    @objc func noMoreData() {
        load_footer?.endRefreshingWithNoMoreData()
    }
    
    @objc var isLoading: Bool {
        return (isRefreshing || isLoadMore)
    }
    
    @objc var isRefreshing: Bool {
        guard let header = refresh_header else { return false }
        return header.isRefreshing
    }
    
    @objc var isLoadMore: Bool {
        guard let footer = load_footer else { return false }
        return footer.isRefreshing
    }
    
    @objc var isRefreshEnabled: Bool {
        guard let header = refresh_header else { return false }
        return header.state != .noMoreData
    }
    
    @objc var isLoadMoreEnabled: Bool {
        guard let footer = load_footer else { return false }
        return footer.state != .noMoreData
    }
}
