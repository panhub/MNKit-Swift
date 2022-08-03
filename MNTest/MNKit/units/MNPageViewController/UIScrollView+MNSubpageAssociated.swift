//
//  UIScrollView+MNSubpageInfo.swift
//  anhe
//
//  Created by 冯盼 on 2022/6/3.
//

import UIKit
import ObjectiveC.runtime

extension UIScrollView {
    
    private struct SubpageAssociatedKey {
        static var appear = "com.mn.subpage.scroll.appear"
        static var subpageIndex = "com.mn.subpage.scroll.index"
        static var subpageInserted = "com.mn.subpage.scroll.subpage.inserted"
        static var subpageObserved = "com.mn.subpage.scroll.subpage.observed"
        static var contentSizeReached = "com.mn.subpage.scroll.content.size.reached"
        static var subpageMinContentSize = "com.mn.subpage.scroll.subpage.min.contentSize"
    }
    
    /// 页面索引
    var subpageIndex: Int {
        get { return objc_getAssociatedObject(self, &SubpageAssociatedKey.subpageIndex) as? Int ?? 0 }
        set {
            objc_setAssociatedObject(self, &SubpageAssociatedKey.subpageIndex, newValue, .OBJC_ASSOCIATION_ASSIGN)
        }
    }
    
    /// 是否允许修改偏移
    var isAppear: Bool {
        get { return objc_getAssociatedObject(self, &SubpageAssociatedKey.appear) as? Bool ?? false }
        set {
            objc_setAssociatedObject(self, &SubpageAssociatedKey.appear, newValue, .OBJC_ASSOCIATION_ASSIGN)
        }
    }
    
    /// 内容尺寸是否满足条件
    var isContentSizeReached: Bool {
        get { return objc_getAssociatedObject(self, &SubpageAssociatedKey.contentSizeReached) as? Bool ?? false }
        set {
            objc_setAssociatedObject(self, &SubpageAssociatedKey.contentSizeReached, newValue, .OBJC_ASSOCIATION_ASSIGN)
        }
    }
    
    /// 是否已监听
    var isObserved: Bool {
        get { return objc_getAssociatedObject(self, &SubpageAssociatedKey.subpageObserved) as? Bool ?? false }
        set {
            objc_setAssociatedObject(self, &SubpageAssociatedKey.subpageObserved, newValue, .OBJC_ASSOCIATION_ASSIGN)
        }
    }
    
    /// 是否已插入边距
    var isInserted: Bool {
        get { return objc_getAssociatedObject(self, &SubpageAssociatedKey.subpageInserted) as? Bool ?? false }
        set {
            objc_setAssociatedObject(self, &SubpageAssociatedKey.subpageInserted, newValue, .OBJC_ASSOCIATION_ASSIGN)
        }
    }
    
    /// 猜想最小内容尺寸
    var guessMinContentSize: CGSize {
        get { return objc_getAssociatedObject(self, &SubpageAssociatedKey.subpageMinContentSize) as? CGSize ?? .zero }
        set {
            objc_setAssociatedObject(self, &SubpageAssociatedKey.subpageMinContentSize, newValue, .OBJC_ASSOCIATION_ASSIGN)
        }
    }
}
