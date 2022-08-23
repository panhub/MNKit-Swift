//
//  MNNavigationBar.swift
//  MNFoundation
//
//  Created by 冯盼 on 2021/7/14.
//  导航条

import UIKit
import Foundation
import CoreGraphics

// 定义导航按钮大小
public let MN_NAV_ITEM_SIZE: CGFloat = 20.0
// 定义导航按钮左右间距
public let MN_NAV_ITEM_SPACING: CGFloat = 18.0

// 导航条事件代理
@objc public protocol MNNavigationBarDelegate: NSObjectProtocol {
    // 获取左按钮视图
    @objc optional func navigationBarShouldCreateLeftBarItem() -> UIView?
    // 获取右按钮视图
    @objc optional func navigationBarShouldCreateRightBarItem() -> UIView?
    // 是否创建返回按钮
    @objc optional func navigationBarShouldDrawBackBarItem() -> Bool
    // 左按钮点击事件
    @objc optional func navigationBarLeftBarItemTouchUpInside(_ leftBarItem: UIView!) -> Void
    // 右按钮点击事件
    @objc optional func navigationBarRightBarItemTouchUpInside(_ rightBarItem: UIView!) -> Void
    // 已经添加完子视图
    @objc optional func navigationBarDidCreatedBarItems(_ navigationBar: MNNavigationBar) -> Void
}

public class MNNavigationBar: UIView {
    // 事件代理
    @objc weak var delegate: MNNavigationBarDelegate?
    // 毛玻璃视图
    private lazy var blurView: UIVisualEffectView = {
        let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .light))
        blurView.frame = bounds
        blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        return blurView
    }()
    // 左按钮
    @objc lazy var leftBarItem: UIView = {
        var barItem: UIView!
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
    // 右按钮
    @objc lazy var rightBarItem: UIView = {
        var barItem: UIView!
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
    // 底部分割线
    @objc lazy var shadowView: UIView = {
        let shadowView = UIView(frame: CGRect(x: 0.0, y: bounds.height - 0.7, width: bounds.width, height: 0.7))
        shadowView.autoresizingMask = .flexibleTopMargin
        shadowView.backgroundColor = .gray.withAlphaComponent(0.15)
        return shadowView
    }()
    // 标题
    @objc lazy var titleLabel: UILabel = {
        let x = max(leftBarItem.maxX, width - rightBarItem.minX) + MN_NAV_ITEM_SPACING
        let titleLabel = UILabel(frame: bounds.inset(by: UIEdgeInsets(top: MN_STATUS_BAR_HEIGHT, left: x, bottom: 0.0, right: x)))
        titleLabel.numberOfLines = 0
        titleLabel.textAlignment = .center
        titleLabel.textColor = UIColor.black
        titleLabel.lineBreakMode = .byTruncatingMiddle
        titleLabel.font = .systemFont(ofSize: 18.0, weight: .medium)
        //titleLabel.autoresizingMask = [.flexibleWidth, .flexibleHeight]
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
            delegate?.navigationBarDidCreatedBarItems?(self)
        }
        super.willMove(toSuperview: newSuperview)
    }
}

// MARK: -
extension MNNavigationBar {
    
    // 是否添加毛玻璃效果
    @objc var translucent: Bool {
        set { blurView.isHidden = newValue == false }
        get { blurView.isHidden == false }
    }
    
    // 设置标题字体
    @objc var title: String? {
        set { titleLabel.text = newValue }
        get { titleLabel.text }
    }
    
    // 设置标题字体
    @objc var titleFont: UIFont? {
        set { titleLabel.font = newValue }
        get { titleLabel.font }
    }
    
    // 设置标题颜色
    @objc var titleColor: UIColor? {
        set { titleLabel.textColor = newValue }
        get { titleLabel.textColor }
    }
    
    // 返回按钮颜色
    @objc var backColor: UIColor? {
        get { nil }
        set { leftItemImage = UIImage(unicode: .back, color: newValue ?? .black, size: MN_NAV_ITEM_SIZE) }
    }
    
    // 左按钮图片
    @objc var leftItemImage: UIImage? {
        set { leftBarItem.background = newValue }
        get { leftBarItem.background }
    }
    
    // 右按钮图片
    @objc var rightItemImage: UIImage? {
        set { rightBarItem.background = newValue }
        get { rightBarItem.background }
    }
    
    // 阴影线位置
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
