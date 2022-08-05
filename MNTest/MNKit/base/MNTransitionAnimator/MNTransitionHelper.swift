//
//  UIView+MNTransitionHelper.swift
//  MNFoundation
//
//  Created by 冯盼 on 2021/8/17.
//  转场辅助

import UIKit
import ObjectiveC.runtime

extension UIView {
    /**获取截图*/
    var transitionSnapshotView: UIView? {
        /*
        let snapshotView = snapshotView(afterScreenUpdates: false)
        snapshotView?.frame = frame
        return snapshotView
        */
        var image: UIImage?
        if #available(iOS 10.0, *) {
            let renderer = UIGraphicsImageRenderer(bounds: bounds)
            image = renderer.image { [weak self] context in
                self?.layer.render(in: context.cgContext)
            }
        } else {
            UIGraphicsBeginImageContextWithOptions(bounds.size, false, layer.contentsScale)
            if let context = UIGraphicsGetCurrentContext() {
                layer.render(in: context)
            }
            image = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
        }
        guard let _ = image else { return nil }
        let imageView = UIImageView(frame: frame)
        imageView.image = image
        imageView.contentScaleFactor = UIScreen.main.scale
        return imageView
    }
    
    /**添加转场阴影*/
    func addTransitionShadow() -> Void {
        layer.shadowOffset = .zero
        layer.shadowOpacity = 1.0
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowPath = UIBezierPath(rect: layer.bounds).cgPath
    }
    /**清除转场阴影*/
    func removeTransitionShadow() -> Void {
        layer.shadowPath = nil
        layer.shadowColor = nil
        layer.shadowOpacity = 0.0
    }
}

extension UIViewController {
    private struct TransitionKey {
        static var tabBar = "com.mn.view.transition.tabbar.key"
        static var snapshot = "com.mn.view.transition.snapshot.key"
        static var customBar = "com.mn.view.transition.tab.bar.key"
        static var backgroundColor = "com.mn.view.transition.background.color.key"
    }
    /**保存标签栏*/
    var transitionTabBar: UIView? {
        get { return objc_getAssociatedObject(self, &TransitionKey.tabBar) as? UIView }
        set { objc_setAssociatedObject(self, &TransitionKey.tabBar, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
    /**保存标签栏截图*/
    var transitionSnapshot: UIView? {
        get { return objc_getAssociatedObject(self, &TransitionKey.snapshot) as? UIView }
        set { objc_setAssociatedObject(self, &TransitionKey.snapshot, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
    /**外界自定义标签栏 */
    var customBar: UIView? {
        get { return objc_getAssociatedObject(self, &TransitionKey.customBar) as? UIView }
        set { objc_setAssociatedObject(self, &TransitionKey.customBar, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
    /**转场背景颜色*/
    var transitionBackgroundColor: UIColor? {
        get { return objc_getAssociatedObject(self, &TransitionKey.backgroundColor) as? UIColor }
        set { objc_setAssociatedObject(self, &TransitionKey.backgroundColor, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
    // 是否允许手动交互返回
    @objc var supportedInteractiveTransition: Bool { true }
    // 定制进栈动画
    @objc var enterTransitionAnimator: MNTransitionAnimator? { nil }
    // 定制出栈动画
    @objc var leaveTransitionAnimator: MNTransitionAnimator? { nil }
}
