//
//  MNTransitionAnimator.swift
//  MNFoundation
//
//  Created by 冯盼 on 2021/8/16.
//  转场动画控制者

import UIKit
import Foundation

class MNTransitionAnimator: NSObject {
    /**转场样式*/
    @objc enum TransitionAnimation: Int {
        case normal, drawer, flip, portal, modal, erected, cube
    }
    /**转场方向*/
    @objc enum TransitionOperation: Int {
        case enter = 1
        case leave = 2
    }
    /**标签栏转场类型*/
    @objc enum TabBarAnimation: Int {
        case none, adsorb, move
    }
    /**转场时间*/
    var duration: TimeInterval { 0.3 }
    /**转场方向*/
    @objc var operation: TransitionOperation = .enter
    /**标签栏转场类型*/
    @objc var tabBarAnimation: TabBarAnimation = .adsorb
    /**标签栏*/
    @objc weak var tabBar: UIView?
    /**是否交互转场*/
    private var isInteractive: Bool = false
    /**交互转场是否结束*/
    private var isInteractiveEnd: Bool = false
    /**内部记录标签栏*/
    private weak var tabView: UIView?
    /**起始控制器视图*/
    weak private(set) var fromView: UIView!
    /**起始控制器*/
    weak private(set) var fromController: UIViewController!
    /**目标控制器视图*/
    weak private(set) var toView: UIView!
    /**目标控制器*/
    weak private(set) var toController: UIViewController!
    /**转场视图*/
    weak private(set) var containerView: UIView!
    /**转场上下文*/
    weak private(set) var context: UIViewControllerContextTransitioning!
    /**转场类*/
    private static let Animations: [String] = ["MNNormalAnimator", "MNDrawerAnimator", "MNFlipAnimator", "MNPortalAnimator", "MNModalAnimator", "MNErectedAnimator", "MNCubeAnimator"]
    
    required override init() {
        super.init()
    }
    
    /**实例化转场动画*/
    static func animator(animation: TransitionAnimation = .normal) -> MNTransitionAnimator {
        // 获取命名空间
        let spage = Bundle.main.infoDictionary!["CFBundleExecutable"] as! String
        // 转换为类
        let cls = NSClassFromString("\(spage).\(MNTransitionAnimator.Animations[animation.rawValue])")! as! MNTransitionAnimator.Type
        return cls.init()
    }
    
    /**初始化转场参数*/
    func beginTransition(using transitionContext: UIViewControllerContextTransitioning) -> Void {
        context = transitionContext
        isInteractive = transitionContext.isInteractive
        containerView = transitionContext.containerView
        containerView.backgroundColor = .red;
        fromController = transitionContext.viewController(forKey: .from)
        toController = transitionContext.viewController(forKey: .to)
        fromView = fromController.view
        toView = toController.view
        // 进栈时寻找标签栏
        if operation == .enter, tabBarAnimation != .none, let tabBarController = fromController.tabBarController, let firstController = fromController.navigationController?.viewControllers.first, fromController == firstController {
            tabView = tabBar ?? tabBarController.tabBar
        }
    }
}

// MARK: - 转场代理
extension MNTransitionAnimator: UIViewControllerAnimatedTransitioning {
    /**转场时长*/
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval { duration }
    /**开始转场*/
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        beginTransition(using: transitionContext)
        if isInteractive {
            // 交互转场
            leaveTabBarTransition()
            beginInteractiveTransition()
        } else if operation == .enter {
            // 进栈转场
            enterTabBarTransition()
            enterTransitionAnimation()
        } else {
            // 出栈转场
            leaveTabBarTransition()
            leaveTransitionAnimation()
        }
    }
    /**转场结束*/
    func animationEnded(_ transitionCompleted: Bool) {
        if isInteractive {
            // 结束交互
            isInteractiveEnd = true
            endInteractiveTransition(transitionCompleted)
        } else if operation == .enter {
            // 删除标签栏
            guard let snapshotView = fromController.transitionSnapshot else { return }
            snapshotView.removeFromSuperview()
        } else if tabBarAnimation == .adsorb {
            // 恢复标签栏
            if let tabbar = toController.transitionTabBar {
                tabbar.isHidden = false
                toController.transitionTabBar = nil
            }
            if let snapshotView = toController.transitionSnapshot {
                snapshotView.removeFromSuperview()
                toController.transitionSnapshot = nil
            }
        }
    }
}

// MARK: - 定制转场动画
extension MNTransitionAnimator {
    @objc func enterTransitionAnimation() {}
    @objc func leaveTransitionAnimation() {}
    @objc func enterTabBarTransition() {
        // 标签栏处理
        guard let tabview = tabView, let snapshotView = tabview.transitionSnapshotView else { return }
        tabview.isHidden = true
        fromController.transitionTabBar = tabview
        fromController.transitionSnapshot = snapshotView
        if tabBarAnimation == .adsorb {
            // 随控制器一块儿转场
            fromView.addSubview(snapshotView)
        } else {
            // 标签栏单独动画
            tabview.superview?.addSubview(snapshotView)
            UIView.animate(withDuration: transitionDuration(using: context), delay: 0.0, options: .curveEaseOut, animations: {
                snapshotView.transform = CGAffineTransform(translationX: 0.0, y: snapshotView.bounds.height)
            }, completion: nil)
        }
    }
    @objc func leaveTabBarTransition() {
        // 重置标签栏位置
        guard let snapshotView = toController.transitionSnapshot else { return }
        if isInteractiveEnd == false {
            snapshotView.transform = .identity
            snapshotView.frame = toView.bounds.inset(by: UIEdgeInsets(top: toView.bounds.height - snapshotView.bounds.height, left: 0.0, bottom: 0.0, right: 0.0))
        }
        if tabBarAnimation == .adsorb {
            if isInteractiveEnd {
                snapshotView.removeFromSuperview()
                toController.transitionTabBar?.isHidden = false
                toController.transitionSnapshot = nil
                toController.transitionTabBar = nil
            } else {
                toView.addSubview(snapshotView)
            }
        } else {
            let tabbar = toController.transitionTabBar
            snapshotView.transform = CGAffineTransform(translationX: 0.0, y: snapshotView.bounds.height)
            tabbar?.superview?.addSubview(snapshotView)
            if isInteractive, isInteractiveEnd == false { return }
            toController.transitionTabBar = nil
            toController.transitionSnapshot = nil
            UIView.animate(withDuration: transitionDuration(using: context), delay: 0.0, options: .curveEaseOut) {
                snapshotView.transform = .identity
            } completion: { _ in
                tabbar?.isHidden = false
                snapshotView.removeFromSuperview()
            }
        }
    }
    @objc func beginInteractiveTransition() {
        // 添加视图
        toView.transform = .identity;
        toView.frame = context.finalFrame(for: toController)
        toView.transform = CGAffineTransform(scaleX: 0.93, y: 0.93)
        containerView.insertSubview(toView, belowSubview: fromView)
        // 添加阴影
        fromView.addTransitionShadow()
        // 动画
        let backgroundColor = containerView.backgroundColor
        let transform = CGAffineTransform(translationX: containerView.bounds.width, y: 0.0)
        containerView.backgroundColor = .black
        UIView.animate(withDuration: transitionDuration(using: context)) { [weak self] in
            guard let self = self else { return }
            self.toView.transform = .identity
            self.fromView.transform = transform
        } completion: { [weak self] _ in
            guard let self = self else { return }
            self.containerView.backgroundColor = backgroundColor
            self.completeTransitionAnimation()
        }
    }
    @objc func endInteractiveTransition(_ completed: Bool) -> Void {
        fromView.transform = .identity
        fromView.removeTransitionShadow()
        if completed {
            // 完成转场 还原视图
            leaveTabBarTransition()
        } else {
            // 取消转场 恢复视图
            toView.transform = .identity;
            cancelInteractiveTransition()
        }
    }
    @objc func cancelInteractiveTransition() {
        guard let snapshotView = toController.transitionSnapshot else { return }
        snapshotView.removeFromSuperview()
    }
    @objc func completeTransitionAnimation() -> Void {
        context.completeTransition(context.transitionWasCancelled == false)
    }
}

// MARK: - 无转场动画处理
extension MNTransitionAnimator {
    
    /// 保存标签栏
    /// - Parameters:
    ///   - navigationController: 导航控制器
    ///   - viewController: 显示的控制器
    ///   - animated: 是否使用了动态转场
    ///   - tabBar: 外界指定标签栏
    static func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool, tabBar: UIView? = nil) {
        guard animated == false, let index = navigationController.viewControllers.firstIndex(of: viewController), index > 0 else { return }
        guard let tabBar = tabBar ?? navigationController.tabBarController?.tabBar, tabBar.isHidden == false, tabBar.alpha == 1.0 else { return }
        let first = navigationController.viewControllers.first!
        if let snapshotView = tabBar.transitionSnapshotView {
            tabBar.isHidden = true
            first.transitionTabBar = tabBar
            first.transitionSnapshot = snapshotView
        }
    }
    
    /// 恢复标签栏
    /// - Parameters:
    ///   - navigationController: 导航控制器
    ///   - viewController: 已展示的控制器
    ///   - animated: 是否使用了动态转场
    static func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
        guard animated == false, let index = navigationController.viewControllers.firstIndex(of: viewController), index == 0 else { return }
        // 恢复标签栏
        if let tabbar = viewController.transitionTabBar {
            tabbar.isHidden = false
            viewController.transitionTabBar = nil
        }
        if let snapshotView = viewController.transitionSnapshot {
            snapshotView.removeFromSuperview()
            viewController.transitionSnapshot = nil
        }
    }
}
