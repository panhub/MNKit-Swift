//
//  UIViewController+MNInterface.swift
//  MNFoundation
//
//  Created by 冯盼 on 2021/7/18.
//

import UIKit
import Foundation
import ObjectiveC.runtime

// MARK: - 控制器快捷处理
extension UIViewController {
    /// 内容约束
    struct Edge: OptionSet {
        // 预留顶部
        static let top = Edge(rawValue: 1 << 0)
        // 预留底部
        static let bottom = Edge(rawValue: 1 << 1)
        
        let rawValue: UInt
        init(rawValue: UInt) {
            self.rawValue = rawValue
        }
    }
    /// 获取主控制器
    @objc var rootViewController: UIViewController? {
        var viewController: UIViewController? = self
        while let vc = viewController {
            if vc.isRootViewController { return vc }
            viewController = vc.parent
        }
        return nil
    }
    /// 是否是主控制器
    @objc var isRootViewController: Bool { false }
    /// 是否以子控制器方式加载
    @objc var isChildViewController: Bool { false }
}

// MARK: - 标签栏优化
extension UIViewController {
    /// 按钮大小
    @objc var tabBarItemSize: CGSize { CGSize(width: 50.0, height: 42.0) }
    /// 标签栏标题
    @objc var tabBarItemTitle: String? { nil }
    /// 标题字体
    @objc var tabBarItemTitleFont: UIFont { UIFont.systemFont(ofSize: 12.0) }
    /// 标题颜色
    @objc var tabBarItemTitleColor: UIColor { .gray }
    /// 标题选择颜色
    @objc var tabBarItemSelectedTitleColor: UIColor { .darkText }
    /// 标题图片间隔
    @objc var tabBarItemTitleImageInterval: CGFloat { 0.0 }
    /// 标签栏按钮图片
    @objc var tabBarItemImage: UIImage? { nil }
    /// 标签栏选择按钮图片
    @objc var tabBarItemSelectedImage: UIImage? { nil }
    /// 获取标签按钮
    @objc var tabbarItem: MNTabBarItem? {
        let vc = self.presentingViewController ?? self
        let viewController = vc.navigationController ?? vc
        guard let tabBarController = viewController.tabBarController else { return nil }
        guard let index = tabBarController.viewControllers?.firstIndex(of: viewController) else { return nil }
        return tabBarController.tabbar?.item(for: index)
    }
    /// 角标
    var badge: MNBadgeConvertible? {
        set {
            let vc = self.presentingViewController ?? self
            let viewController = vc.navigationController ?? vc
            guard let tabBarController = viewController.tabBarController else { return }
            guard let index = tabBarController.viewControllers?.firstIndex(of: viewController) else { return }
            tabBarController.tabbar?.set(badge: newValue, index: index)
        }
        get {
            let vc = self.presentingViewController ?? self
            let viewController = vc.navigationController ?? vc
            guard let tabBarController = viewController.tabBarController else { return nil }
            guard let index = tabBarController.viewControllers?.firstIndex(of: viewController) else { return nil }
            return tabBarController.tabbar?.badge(for: index)
        }
    }
}
