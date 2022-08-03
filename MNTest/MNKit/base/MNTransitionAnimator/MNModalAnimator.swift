//
//  MNModalAnimator.swift
//  MNFoundation
//
//  Created by 冯盼 on 2021/8/17.
//  进栈模式下模态样式

import UIKit

class MNModalAnimator: MNTransitionAnimator {
    // 持续时间
    override var duration: TimeInterval { 0.33 }
    // 进栈
    override func enterTransitionAnimation() {
        // 添加控制器
        toView.frame = context.finalFrame(for: toController)
        toView.transform = CGAffineTransform(translationX: 0.0, y: containerView.bounds.height)
        containerView.insertSubview(toView, aboveSubview: fromView)
        // 背景
        let backgroundColor = containerView.backgroundColor
        containerView.backgroundColor = .black
        // 动画
        UIView.animate(withDuration: transitionDuration(using: context), delay: 0.0, options: .curveEaseInOut) { [weak self] in
            self?.toView.transform = .identity
            self?.fromView.transform = CGAffineTransform(scaleX: 0.93, y: 0.93)
        } completion: { [weak self] finish in
            self?.fromView.transform = .identity
            self?.containerView.backgroundColor = backgroundColor
            self?.completeTransitionAnimation()
        }
    }
    // 出栈
    override func leaveTransitionAnimation() {
        // 添加视图
        toView.transform = .identity
        toView.frame = context.finalFrame(for: toController)
        toView.transform = CGAffineTransform(scaleX: 0.93, y: 0.93)
        containerView.insertSubview(toView, belowSubview: fromView)
        // 背景
        let backgroundColor = containerView.backgroundColor
        containerView.backgroundColor = .black
        // 动画
        let transform = CGAffineTransform(translationX: 0.0, y: containerView.bounds.height)
        UIView.animate(withDuration: transitionDuration(using: context), delay: 0.0, options: .curveEaseInOut) { [weak self] in
            self?.toView.transform = .identity
            self?.fromView.transform = transform
        } completion: { [weak self] finish in
            self?.fromView.transform = .identity
            self?.containerView.backgroundColor = backgroundColor
            self?.completeTransitionAnimation()
        }
    }
}
