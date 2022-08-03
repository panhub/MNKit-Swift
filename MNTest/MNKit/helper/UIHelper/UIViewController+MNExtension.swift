//
//  UIViewController+MNHelper.swift
//  MNFoundation
//
//  Created by 冯盼 on 2021/8/15.
//

import UIKit

public extension UIViewController {
    
    /// 从父控制器中移除自身
    @objc func removeFromParentController() {
        guard let _ = parent else { return }
        willMove(toParent: nil)
        view.willMove(toSuperview: nil)
        view.removeFromSuperview()
        removeFromParent()
        didMove(toParent: nil)
    }
    
    /// 添加子控制器到指定视图上
    /// - Parameters:
    ///   - childController: 自控制器
    ///   - superview: 指定视图
    @objc func addChild(_ childController: UIViewController, to superview: UIView) {
        childController.willMove(toParent: self)
        childController.view.willMove(toSuperview: superview)
        superview.addSubview(childController.view)
        childController.view.didMoveToSuperview()
        addChild(childController)
        childController.didMove(toParent: self)
    }
    
    // 当前控制器
    static var current: UIViewController? {
        guard let viewController = UIApplication.shared.delegate?.window??.rootViewController else { return nil }
        var vc: UIViewController? = viewController
        repeat {
            if let presented = vc!.presentedViewController {
                vc = presented
            } else if vc is UINavigationController {
                let nav = vc as! UINavigationController
                vc = nav.viewControllers.last
            } else if vc is UITabBarController {
                let tab = vc as! UITabBarController
                vc = tab.selectedViewController
            } else { break }
        } while (vc != nil)
        return vc
    }
}
