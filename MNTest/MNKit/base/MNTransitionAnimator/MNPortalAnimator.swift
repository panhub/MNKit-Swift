//
//  MNPortalAnimator.swift
//  MNFoundation
//
//  Created by 冯盼 on 2021/8/17.
//  开关门

import UIKit

class MNPortalAnimator: MNTransitionAnimator {
    // 持续时间
    override var duration: TimeInterval { 0.35 }
    // 进栈
    override func enterTransitionAnimation() {
        // 添加控制器
        toView.frame = context.finalFrame(for: toController)
        toView.transform = CGAffineTransform(scaleX: 0.93, y: 0.93)
        containerView.insertSubview(toView, belowSubview: fromView)
        // 截图
        let leftRect = fromView.bounds.inset(by: UIEdgeInsets(top: 0.0, left: 0.0, bottom: 0.0, right: fromView.bounds.width/2.0))
        let fromLeftView = fromView.resizableSnapshotView(from: leftRect, afterScreenUpdates: false, withCapInsets: .zero)
        if let _ = fromLeftView {
            fromLeftView!.frame = leftRect
            containerView.addSubview(fromLeftView!)
        }
        let rightRect = fromView.bounds.inset(by: UIEdgeInsets(top: 0.0, left: fromView.bounds.width/2.0, bottom: 0.0, right: 0.0))
        let fromRightView = fromView.resizableSnapshotView(from: rightRect, afterScreenUpdates: false, withCapInsets: .zero)
        if let _ = fromRightView {
            fromRightView!.frame = rightRect
            containerView.addSubview(fromRightView!)
        }
        // 动画
        fromView.isHidden = true
        let margin = containerView.bounds.width/2.0
        let backgroundColor = containerView.backgroundColor
        containerView.backgroundColor = .black
        UIView.animate(withDuration: transitionDuration(using: context), delay: 0.0, options: .curveEaseInOut) { [weak self] in
            self?.toView.transform = .identity
            fromLeftView?.transform = CGAffineTransform(translationX: -margin, y: 0.0)
            fromRightView?.transform = CGAffineTransform(translationX: margin, y: 0.0)
        } completion: { [weak self] finish in
            self?.fromView.isHidden = false
            self?.containerView.backgroundColor = backgroundColor
            fromLeftView?.removeFromSuperview()
            fromRightView?.removeFromSuperview()
            self?.completeTransitionAnimation()
        }
    }
    // 出栈
    override func leaveTransitionAnimation() {
        // 添加控制器
        toView.transform = .identity
        toView.frame = context.finalFrame(for: toController)
        containerView.insertSubview(toView, aboveSubview: fromView)
        // 截图
        let margin = containerView.bounds.width/2.0
        let leftRect = toView.bounds.inset(by: UIEdgeInsets(top: 0.0, left: 0.0, bottom: 0.0, right: toView.bounds.width/2.0))
        let toLeftView = toView.resizableSnapshotView(from: leftRect, afterScreenUpdates: false, withCapInsets: .zero)
        if let _ = toLeftView {
            toLeftView!.frame = leftRect
            toLeftView!.transform = CGAffineTransform(translationX: -margin, y: 0.0)
            containerView.addSubview(toLeftView!)
        }
        let rightRect = toView.bounds.inset(by: UIEdgeInsets(top: 0.0, left: toView.bounds.width/2.0, bottom: 0.0, right: 0.0))
        let toRightView = toView.resizableSnapshotView(from: rightRect, afterScreenUpdates: false, withCapInsets: .zero)
        if let _ = toRightView {
            toRightView!.frame = rightRect
            toRightView!.transform = CGAffineTransform(translationX: margin, y: 0.0)
            containerView.addSubview(toRightView!)
        }
        // 动画
        toView.isHidden = true
        let backgroundColor = containerView.backgroundColor
        containerView.backgroundColor = .black
        UIView.animate(withDuration: transitionDuration(using: context), delay: 0.0, options: .curveEaseInOut) { [weak self] in
            toLeftView?.transform = .identity
            toRightView?.transform = .identity
            self?.fromView.transform = CGAffineTransform(scaleX: 0.93, y: 0.93)
        } completion: { [weak self] finish in
            self?.toView.isHidden = false
            self?.fromView.transform = .identity
            self?.containerView.backgroundColor = backgroundColor
            toLeftView?.removeFromSuperview()
            toRightView?.removeFromSuperview()
            self?.completeTransitionAnimation()
        }
    }
}
