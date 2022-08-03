//
//  MNNormalAnimator.swift
//  MNFoundation
//
//  Created by 冯盼 on 2021/8/17.
//  仿系统转场动画

import UIKit

class MNNormalAnimator: MNTransitionAnimator {
    // 持续时间
    override var duration: TimeInterval { 0.3 }
    // 进栈
    override func enterTransitionAnimation() {
        // 黑色背景
        let shadowView = UIView(frame: fromView.bounds)
        shadowView.isUserInteractionEnabled = true
        shadowView.backgroundColor = UIColor.clear
        containerView.insertSubview(shadowView, aboveSubview: fromView)
        // 添加控制器
        toView.addTransitionShadow()
        toView.frame = context.finalFrame(for: toController)
        toView.transform = CGAffineTransform(translationX: containerView.bounds.width, y: 0.0)
        containerView.insertSubview(toView, aboveSubview: shadowView)
        // 动画
        let transform = CGAffineTransform(translationX: -containerView.bounds.width/2.0, y: 0.0)
        UIView.animate(withDuration: transitionDuration(using: context), delay: 0.0, options: .curveEaseInOut) { [weak self] in
            self?.toView.transform = .identity
            self?.fromView.transform = transform
            shadowView.backgroundColor = UIColor.black.withAlphaComponent(0.2)
        } completion: { [weak self] finish in
            shadowView.removeFromSuperview()
            self?.fromView.transform = .identity
            self?.toView.removeTransitionShadow()
            self?.completeTransitionAnimation()
        }
    }
    // 出栈
    override func leaveTransitionAnimation() {
        // 添加控制器
        toView.transform = .identity
        toView.frame = context.finalFrame(for: toController)
        toView.transform = CGAffineTransform(translationX: -containerView.bounds.width/2.0, y: 0.0)
        containerView.insertSubview(toView, belowSubview: fromView)
        // 黑色背景
        let shadowView = UIView(frame: containerView.bounds)
        shadowView.isUserInteractionEnabled = true
        shadowView.backgroundColor = UIColor.black.withAlphaComponent(0.2)
        containerView.insertSubview(shadowView, aboveSubview: toView)
        // 转场阴影
        fromView.addTransitionShadow()
        // 动画
        let transform = CGAffineTransform(translationX: containerView.bounds.width, y: 0.0)
        UIView.animate(withDuration: transitionDuration(using: context), delay: 0.0, options: .curveEaseInOut) { [weak self] in
            self?.toView.transform = .identity
            self?.fromView.transform = transform
            shadowView.backgroundColor = UIColor.clear
        } completion: { [weak self] finish in
            shadowView.removeFromSuperview()
            self?.fromView.transform = .identity
            self?.fromView.removeTransitionShadow()
            self?.completeTransitionAnimation()
        }
    }
    // 交互开始
    override func beginInteractiveTransition() {
        // 添加控制器
        toView.transform = .identity;
        toView.frame = context.finalFrame(for: toController)
        containerView.insertSubview(toView, belowSubview: fromView)
        toView.transform = CGAffineTransform(translationX: -containerView.bounds.width/2.0, y: 0.0)
        // 转场阴影
        fromView.addTransitionShadow()
        // 动画
        UIView.animate(withDuration: transitionDuration(using: context), delay: 0.0, options: .curveEaseInOut) { [weak self] in
            guard let self = self else { return }
            self.toView.transform = .identity
            self.fromView.transform = CGAffineTransform(translationX: self.containerView.bounds.width, y: 0.0)
        } completion: { [weak self] finish in
            self?.completeTransitionAnimation()
        }
    }
}

