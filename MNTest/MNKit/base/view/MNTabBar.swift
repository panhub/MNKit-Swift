//
//  MNTabBar.swift
//  MNFoundation
//
//  Created by 冯盼 on 2021/8/11.
//  标签栏

import UIKit

@objc public protocol MNTabBarDelegate: NSObjectProtocol {
    @objc optional func tabBar(_ tabBar: MNTabBar, shouldSelectItem index: Int) -> Bool
    @objc func tabBar(_ tabBar: MNTabBar, selectedItem index: Int) -> Void
}

public class MNTabBar: UIView {
    /**交互代理*/
    public weak var delegate: MNTabBarDelegate?
    /**按钮*/
    private var items: [MNTabBarItem] = [MNTabBarItem]()
    /**阴影线*/
    public lazy var shadowView: UIView = {
        let shadowView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: bounds.width, height: 0.7))
        shadowView.autoresizingMask = [.flexibleWidth, .flexibleBottomMargin]
        shadowView.backgroundColor = .gray.withAlphaComponent(0.15)
        return shadowView
    }()
    /**毛玻璃视图*/
    private lazy var blurView: UIVisualEffectView = {
        let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .light))
        blurView.frame = bounds
        blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        return blurView
    }()
    /**选择索引*/
    public var selectedIndex: Int = 0 {
        didSet {
            for index in 0..<items.count {
                items[index].isSelected = index == selectedIndex
            }
        }
    }
    /**按钮偏移*/
    public var itemOffset: UIOffset = .zero {
        didSet {
            setNeedsLayout()
        }
    }
    
    public override init(frame: CGRect) {
        super.init(frame: UIScreen.main.bounds.inset(by: UIEdgeInsets(top: UIScreen.main.bounds.height - MN_TAB_BAR_HEIGHT, left: 0.0, bottom: 0.0, right: 0.0)))
        backgroundColor = .clear
        addSubview(blurView)
        addSubview(shadowView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /**添加控制器*/
    public func add(viewControllers: [UIViewController]?) -> Void {
        for item in items {
            item.removeFromSuperview()
        }
        items.removeAll()
        guard let viewControllers = viewControllers else { return }
        for idx in 0..<viewControllers.count {
            var vc: UIViewController? = viewControllers[idx]
            repeat {
                if vc is UINavigationController {
                    vc = (vc as! UINavigationController).viewControllers.first
                } else if vc is UITabBarController {
                    vc = (vc as! UITabBarController).selectedViewController
                } else {
                    break
                }
            } while vc != nil
            guard let vc = vc else { continue }
            let itemSize = vc.tabBarItemSize
            let item = MNTabBarItem(frame: CGRect(x: 0.0, y: 0.0, width: itemSize.width, height: itemSize.height))
            item.tag = idx
            item.isSelected = idx == selectedIndex
            item.title = vc.tabBarItemTitle ?? ""
            item.selectedTitle = vc.tabBarItemTitle ?? ""
            item.image = vc.tabBarItemImage
            item.selectedImage = vc.tabBarItemSelectedImage
            item.titleColor = vc.tabBarItemTitleColor
            item.selectedTitleColor = vc.tabBarItemSelectedTitleColor
            item.titleFont = vc.tabBarItemTitleFont
            item.titleImageInterval = vc.tabBarItemTitleImageInterval
            item.addTarget(self, action: #selector(itemButtonTouchUpInside(_:)), for: .touchUpInside)
            addSubview(item)
            items.append(item)
        }
        setNeedsLayout()
    }
    
    public override func layoutSubviews() {
        let items: [MNTabBarItem] = self.items.filter { $0.isHidden == false }
        guard items.count > 0 else { return }
        let width: CGFloat = items.reduce(0.0) { $0 + $1.frame.width }
        let m: CGFloat = ceil((bounds.width - width)/CGFloat(items.count + 1))
        var x: CGFloat = m + itemOffset.horizontal
        for item in items {
            item.minX = x
            if MN_TAB_SAFE_HEIGHT > 0.0 {
                item.maxY = bounds.height - MN_TAB_SAFE_HEIGHT + itemOffset.vertical
            } else {
                item.midY = bounds.midY + itemOffset.vertical
            }
            x = item.maxX + m + itemOffset.horizontal
        }
    }
    
    /**点击事件*/
    @objc private func itemButtonTouchUpInside(_ item: MNTabBarItem) -> Void {
        guard (delegate?.tabBar?(self, shouldSelectItem: item.tag) ?? true) else { return }
        delegate?.tabBar(self, selectedItem: item.tag)
    }
}

// MARK: -
public extension MNTabBar {
    
    /// 是否需要毛玻璃效果
    var translucent: Bool {
        get { blurView.isHidden == false }
        set { blurView.isHidden = newValue == false }
    }
    
    ///  阴影线位置
    @objc var shadowInset: UIEdgeInsets {
        get { UIEdgeInsets(top: 0.0, left: shadowView.minX, bottom: frame.height - shadowView.maxY, right: width - shadowView.maxX) }
        set {
            let mask = shadowView.autoresizingMask
            shadowView.autoresizingMask = []
            let rect = bounds.inset(by: UIEdgeInsets(top: 0.0, left: max(newValue.left, 0.0), bottom: frame.height - shadowView.maxY, right: max(newValue.right, 0.0)))
            shadowView.minX = rect.minX
            shadowView.width = rect.width
            shadowView.autoresizingMask = mask
        }
    }
}

// MARK: - 设置角标
public extension MNTabBar {
    
    /// 设置角标
    /// - Parameters:
    ///   - badge: 角标内容
    ///   - index: 索引
    func set(badge: MNBadgeConvertible?, index: Int) {
        guard let item = item(for: index) else { return }
        item.badge = badge
    }
    
    /// 获取角标
    /// - Parameter index: 索引
    /// - Returns: 角标内容
    func badge(for index: Int) -> MNBadgeConvertible? {
        guard let item = item(for: index) else { return nil }
        return item.badge
    }
}

// MARK: - 标签按钮
public extension MNTabBar {
    
    /// 获取标签按钮
    /// - Parameter index: 索引
    /// - Returns: 角标内容
    func item(for index: Int) -> MNTabBarItem? {
        guard index < items.count else { return nil }
        return items[index]
    }
}
