//
//  MNTransitionDelegate.swift
//  anhe
//
//  Created by 冯盼 on 2022/6/23.
//  导航转场代理

import UIKit

class MNTransitionDelegate: NSObject {
    /**标签栏*/
    @objc weak var tabBar: UIView?
    /**导航控制器*/
    private weak var navigationController: UINavigationController?
    /**转发代理事件*/
    private weak var delegate: UINavigationControllerDelegate?
    /**交互返回驱动*/
    private var transitionDriver: UIPercentDrivenInteractiveTransition?
    
    /// 应用于导航控制器
    /// - Parameter navigationController: 导航控制器
    @objc func using(to navigationController: UINavigationController) {
        delegate = navigationController.delegate
        navigationController.delegate = self
        navigationController.transitionDelegate = self
        self.navigationController = navigationController
        // 拦截交互手势
        if let recognizer = navigationController.interactivePopGestureRecognizer {
            recognizer.delegate = self
            recognizer.removeTarget(nil, action: nil)
            (recognizer as? UIScreenEdgePanGestureRecognizer)?.edges = .left
            (recognizer as? UIPanGestureRecognizer)?.maximumNumberOfTouches = 1
            if #available(iOS 11.0, *) {
                recognizer.name = "com.mn.navigation.interactive.pop"
            }
            recognizer.addTarget(self, action: #selector(handleNavigationTransition(_:)))
        }
    }
    
    /// 处理导航交互式Pop
    /// - Parameter recognizer: 交互手势
    @objc private func handleNavigationTransition(_ recognizer: UIScreenEdgePanGestureRecognizer) {
        switch recognizer.state {
        case .began:
            transitionDriver = UIPercentDrivenInteractiveTransition()
            navigationController?.popViewController(animated: true)
        case .changed:
            let x: CGFloat = recognizer.translation(in: recognizer.view).x
            let rate: CGFloat = max(0.01, min(1.0, x/recognizer.view!.bounds.width))
            transitionDriver?.update(rate)
        case .cancelled:
            transitionDriver?.cancel()
            transitionDriver = nil
        case .ended:
            if let percent = transitionDriver?.percentComplete, percent >= 0.3 {
                transitionDriver!.finish()
            } else {
                transitionDriver?.cancel()
            }
            transitionDriver = nil
        default:
            transitionDriver = nil
        }
    }
}

// MARK: - UINavigationControllerDelegate
extension MNTransitionDelegate: UINavigationControllerDelegate {
    func navigationController(_ navigationController: UINavigationController, interactionControllerFor animationController: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        transitionDriver
    }
    func navigationController(_ navigationController: UINavigationController, animationControllerFor operation: UINavigationController.Operation, from fromVC: UIViewController, to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        guard operation != .none else { return nil }
        let animator: MNTransitionAnimator = (operation == .push ? toVC.enterTransitionAnimator : fromVC.leaveTransitionAnimator) ?? MNTransitionAnimator.animator()
        animator.tabBar = (operation == .push ? fromVC.customBar : nil) ?? tabBar
        animator.tabBarAnimation = .move
        animator.operation = MNTransitionAnimator.TransitionOperation(rawValue: operation.rawValue) ?? .enter
        return animator
    }
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        MNTransitionAnimator.navigationController(navigationController, willShow: viewController, animated: animated, tabBar: tabBar)
    }
    func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
        MNTransitionAnimator.navigationController(navigationController, didShow: viewController, animated: animated)
    }
    func navigationControllerSupportedInterfaceOrientations(_ navigationController: UINavigationController) -> UIInterfaceOrientationMask {
        guard let mask = delegate?.navigationControllerSupportedInterfaceOrientations?(navigationController) else {
            return .portrait
        }
        return mask
    }
    func navigationControllerPreferredInterfaceOrientationForPresentation(_ navigationController: UINavigationController) -> UIInterfaceOrientation {
        guard let orientation = delegate?.navigationControllerPreferredInterfaceOrientationForPresentation?(navigationController) else {
            return .portrait
        }
        return orientation
    }
}

// MARK: - UIGestureRecognizerDelegate
extension MNTransitionDelegate: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        guard let nav = navigationController, nav.viewControllers.count > 1 else { return false }
        return nav.viewControllers.last!.supportedInteractiveTransition
    }
}
