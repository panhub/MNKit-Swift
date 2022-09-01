//
//  MNNavigationBar.swift
//  MNFoundation
//
//  Created by 冯盼 on 2021/7/14.
//  导航条

import UIKit
import Foundation
import CoreGraphics

/// 导航按钮大小
public let MN_NAV_ITEM_SIZE: CGFloat = 20.0
/// 导航按钮间距
public let MN_NAV_ITEM_SPACING: CGFloat = 18.0

/// 导航条事件代理
@objc public protocol MNNavigationBarDelegate: NSObjectProtocol {
    /// 获取左按钮视图
    @objc optional func navigationBarShouldCreateLeftBarItem() -> UIView?
    /// 获取右按钮视图
    @objc optional func navigationBarShouldCreateRightBarItem() -> UIView?
    /// 是否创建返回按钮
    @objc optional func navigationBarShouldDrawBackBarItem() -> Bool
    /// 左按钮点击事件
    @objc optional func navigationBarLeftBarItemTouchUpInside(_ leftBarItem: UIView!) -> Void
    /// 右按钮点击事件
    @objc optional func navigationBarRightBarItemTouchUpInside(_ rightBarItem: UIView!) -> Void
    /// 已经添加完子视图
    @objc optional func navigationBarDidLayoutSubitems(_ navigationBar: MNNavigationBar) -> Void
    /// 告知标题更新
    @objc optional func navigationBarDidUpdateTitle(_ navigationBar: MNNavigationBar) -> Void
}

public class MNNavigationBar: UIView {
    /// 事件代理
    @objc weak var delegate: MNNavigationBarDelegate?
    /// 毛玻璃视图
    private lazy var blurView: UIVisualEffectView = {
        let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .light))
        blurView.frame = bounds
        blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        return blurView
    }()
    /// 导航左按钮
    @objc lazy var leftBarItem: UIView = {
        var barItem: UIView
        if let view = delegate?.navigationBarShouldCreateLeftBarItem?() {
            barItem = view
        } else {
            barItem = UIControl()
            barItem.size = CGSize(width: MN_NAV_ITEM_SIZE, height: MN_NAV_ITEM_SIZE)
            if delegate?.navigationBarShouldDrawBackBarItem?() ?? false {
                // 返回按钮
                barItem.background = UIImage(unicode: .back, color: .black, size: MN_NAV_ITEM_SIZE)
                (barItem as! UIControl).addTarget(self, action: #selector(leftBarItemTouchUpInside(_:)), for: UIControl.Event.touchUpInside)
            }
        }
        barItem.minX = MN_NAV_ITEM_SPACING
        var y = (height - UIApplication.StatusBarHeight - barItem.height)/2.0
        y = max(0.0, y)
        y += UIApplication.StatusBarHeight
        barItem.minY = y
        barItem.autoresizingMask = .flexibleTopMargin
        return barItem
    }()
    /// 导航右按钮
    @objc lazy var rightBarItem: UIView = {
        var barItem: UIView
        if let view = delegate?.navigationBarShouldCreateRightBarItem?() {
            barItem = view
        } else {
            barItem = UIControl()
            barItem.size = CGSize(width: MN_NAV_ITEM_SIZE, height: MN_NAV_ITEM_SIZE)
            (barItem as! UIControl).addTarget(self, action: #selector(rightBarItemTouchUpInside(_:)), for: UIControl.Event.touchUpInside)
        }
        var y = (height - UIApplication.StatusBarHeight - barItem.height)/2.0
        y = max(0.0, y)
        y += UIApplication.StatusBarHeight
        barItem.minY = y
        barItem.maxX = width - MN_NAV_ITEM_SPACING
        barItem.autoresizingMask = .flexibleTopMargin
        return barItem
    }()
    /// 导航底部分割线
    @objc lazy var shadowView: UIView = {
        let shadowView = UIView(frame: CGRect(x: 0.0, y: bounds.height - 0.7, width: bounds.width, height: 0.7))
        shadowView.autoresizingMask = .flexibleTopMargin
        shadowView.backgroundColor = .gray.withAlphaComponent(0.15)
        return shadowView
    }()
    /// 导航标题
    private lazy var titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.center = CGPoint(x: frame.width/2.0, y: (frame.height - MN_STATUS_BAR_HEIGHT)/2.0 + MN_STATUS_BAR_HEIGHT)
        titleLabel.numberOfLines = 0
        titleLabel.textAlignment = .center
        titleLabel.textColor = UIColor.black
        titleLabel.lineBreakMode = .byTruncatingMiddle
        titleLabel.font = .systemFont(ofSize: 18.0, weight: .medium)
        return titleLabel
    }()
    
    convenience init(frame: CGRect, delegate: MNNavigationBarDelegate) {
        self.init(frame: frame)
        self.delegate = delegate
    }
    
    public override func willMove(toSuperview newSuperview: UIView?) {
        if let _ = newSuperview, subviews.isEmpty {
            // 毛玻璃
            addSubview(blurView)
            // 导航左按钮
            addSubview(leftBarItem)
            // 导航右按钮
            addSubview(rightBarItem)
            // 标题视图
            addSubview(titleLabel)
            // 阴影线
            addSubview(shadowView)
            // 回调代理
            delegate?.navigationBarDidLayoutSubitems?(self)
        }
        super.willMove(toSuperview: newSuperview)
    }
    
    /// 更新标题
    private func updateTitle() {
        let center: CGPoint = titleLabel.center
        let spacing: CGFloat = ceil(max(leftBarItem.frame.maxX, frame.width - rightBarItem.frame.minX)) + MN_NAV_ITEM_SPACING
        titleLabel.sizeToFit()
        titleLabel.width = min(ceil(titleLabel.width), frame.width - spacing*2.0)
        titleLabel.height = min(ceil(titleLabel.height), frame.height - MN_STATUS_BAR_HEIGHT)
        titleLabel.center = center
        delegate?.navigationBarDidUpdateTitle?(self)
    }
}

// MARK: - Property
extension MNNavigationBar {
    
    /// 导航栏是否启用毛玻璃效果
    @objc var translucent: Bool {
        set { blurView.isHidden = newValue == false }
        get { blurView.isHidden == false }
    }
    
    /// 导航栏标题字体
    @objc var title: String? {
        get { titleLabel.text }
        set {
            titleLabel.text = newValue
            updateTitle()
        }
    }
    
    /// 导航栏富文本标题
    @objc var attributedTitle: NSAttributedString? {
        get { titleLabel.attributedText }
        set {
            titleLabel.attributedText = newValue
            updateTitle()
        }
    }
    
    /// 导航栏标题字体
    @objc var titleFont: UIFont? {
        get { titleLabel.font }
        set {
            titleLabel.font = newValue
            updateTitle()
        }
    }
    
    /// 导航栏标题颜色
    @objc var titleColor: UIColor? {
        get { titleLabel.textColor }
        set { titleLabel.textColor = newValue }
    }
    
    /// 导航栏返回按钮颜色
    @objc var backColor: UIColor? {
        get { nil }
        set { leftItemImage = UIImage(unicode: .back, color: newValue ?? .black, size: MN_NAV_ITEM_SIZE) }
    }
    
    /// 导航栏左按钮图片
    @objc var leftItemImage: UIImage? {
        get { leftBarItem.background }
        set { leftBarItem.background = newValue }
    }
    
    /// 导航栏右按钮图片
    @objc var rightItemImage: UIImage? {
        get { rightBarItem.background }
        set { rightBarItem.background = newValue }
    }
    
    /// 导航栏阴影线位置
    @objc var shadowInset: UIEdgeInsets {
        get { UIEdgeInsets(top: shadowView.minY, left: shadowView.minX, bottom: 0.0, right: width - shadowView.maxX) }
        set {
            let mask = shadowView.autoresizingMask
            shadowView.autoresizingMask = []
            let rect = bounds.inset(by: UIEdgeInsets(top: height - shadowView.height, left: max(newValue.left, 0.0), bottom: 0.0, right: max(newValue.right, 0.0)))
            shadowView.minX = rect.minX
            shadowView.width = rect.width
            shadowView.autoresizingMask = mask
        }
    }
}
 
// MARK: - Event
private extension MNNavigationBar {
    
    @objc func leftBarItemTouchUpInside(_ leftBarItem: UIView) -> Void {
        delegate?.navigationBarLeftBarItemTouchUpInside?(leftBarItem)
    }
    
    @objc func rightBarItemTouchUpInside(_ rightBarItem: UIView) -> Void {
        delegate?.navigationBarRightBarItemTouchUpInside?(rightBarItem)
    }
}
