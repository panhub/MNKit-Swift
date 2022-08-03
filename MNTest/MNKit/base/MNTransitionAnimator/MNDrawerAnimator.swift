//
//  MNDrawerAnimator.swift
//  MNFoundation
//
//  Created by 冯盼 on 2021/8/17.
//  远近切换

import UIKit

class MNDrawerAnimator: MNTransitionAnimator {
    // 进栈
    override func enterTransitionAnimation() {
        // 添加控制器
        toView.transform = .identity
        toView.frame = context.finalFrame(for: toController)
        containerView.insertSubview(toView, aboveSubview: fromView)
        toView.transform = CGAffineTransform(translationX: containerView.bounds.width, y: 0.0)
        // 阴影
        toView.addTransitionShadow()
        fromView.removeTransitionShadow()
        // 动画
        let backgroundColor = containerView.backgroundColor
        containerView.backgroundColor = fromController.transitionBackgroundColor ?? .white
        UIView.animate(withDuration: transitionDuration(using: context), delay: 0.0, options: .curveEaseInOut) { [weak self] in
            self?.toView.transform = .identity
            self?.fromView.transform = CGAffineTransform(scaleX: 0.93, y: 0.93)
        } completion: { [weak self] finish in
            self?.fromView.transform = .identity
            self?.containerView.backgroundColor = backgroundColor
            self?.toView.removeTransitionShadow()
            self?.completeTransitionAnimation()
        }
    }
    // 出栈
    override func leaveTransitionAnimation() {
        // 添加视图
        toView.transform = .identity
        toView.frame = context.finalFrame(for: toController)
        containerView.insertSubview(toView, belowSubview: fromView)
        toView.transform = CGAffineTransform(scaleX: 0.93, y: 0.93)
        // 添加阴影
        fromView.addTransitionShadow()
        toView.removeTransitionShadow()
        // 动画
        let backgroundColor = containerView.backgroundColor
        containerView.backgroundColor = toController.transitionBackgroundColor ?? .white
        let transform = CGAffineTransform(translationX: containerView.bounds.width, y: 0.0)
        UIView.animate(withDuration: transitionDuration(using: context), delay: 0.0, options: .curveEaseInOut) { [weak self] in
            self?.toView.transform = .identity
            self?.fromView.transform = transform
        } completion: { [weak self] finish in
            self?.fromView.transform = .identity
            self?.containerView.backgroundColor = backgroundColor
            self?.fromView.removeTransitionShadow()
            self?.completeTransitionAnimation()
        }
    }
    // 交互转场
    override func beginInteractiveTransition() {
        // 添加视图
        toView.transform = .identity
        toView.frame = context.finalFrame(for: toController)
        containerView.insertSubview(toView, belowSubview: fromView)
        toView.transform = CGAffineTransform(scaleX: 0.93, y: 0.93)
        // 添加阴影
        fromView.addTransitionShadow()
        toView.removeTransitionShadow()
        // 动画
        let backgroundColor = containerView.backgroundColor
        let transform = CGAffineTransform(translationX: containerView.bounds.width, y: 0.0)
        containerView.backgroundColor = toController.transitionBackgroundColor ?? .white
        UIView.animate(withDuration: duration) { [weak self] in
            self?.toView.transform = .identity
            self?.fromView.transform = transform
        } completion: { [weak self] _ in
            self?.containerView.backgroundColor = backgroundColor
            self?.completeTransitionAnimation()
        }
    }
}
