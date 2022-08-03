//
//  MNErectedAnimator.swift
//  MNFoundation
//
//  Created by 冯盼 on 2021/12/5.
//  3D动画

import UIKit

class MNErectedAnimator: MNTransitionAnimator {
    // 持续时间
    override var duration: TimeInterval { 0.35 }
    //
    override func enterTransitionAnimation() {
        super.enterTransitionAnimation()
        
        toView.transform = .identity
        toView.frame = context.finalFrame(for: toController)
        containerView.insertSubview(toView, aboveSubview: fromView)
        
        let position = toView.layer.position
        let anchorPoint = toView.layer.anchorPoint

        toView.layer.anchorPoint = CGPoint(x: 0.0, y: 0.5)
        toView.layer.position = CGPoint(x: toView.frame.width, y: toView.frame.height*0.5)

        var transform = CATransform3DIdentity
        transform.m34 = -1.0/500.0
        toView.layer.transform = CATransform3DRotate(transform, .pi/3.0, 0.0, 1.0, 0.0)

        UIView.animate(withDuration: transitionDuration(using: context)) { [weak self] in
            guard let self = self else { return }
            self.toView.layer.transform = CATransform3DIdentity
            self.toView.layer.position = CGPoint(x: 0.0, y: self.toView.frame.height*0.5)
        } completion: { [weak self] _ in
            self?.toView.layer.position = position
            self?.toView.layer.anchorPoint = anchorPoint
            self?.completeTransitionAnimation()
        }
    }
    override func leaveTransitionAnimation() {
        super.leaveTransitionAnimation()
        
        toView.transform = .identity
        toView.frame = context.finalFrame(for: toController)
        containerView.insertSubview(toView, belowSubview: fromView)
        
        let position = fromView.layer.position
        let anchorPoint = fromView.layer.anchorPoint
        
        toView.layer.anchorPoint = CGPoint(x: 0.0, y: 0.5)
        toView.layer.position = CGPoint(x: 0.0, y: fromView.bounds.height*0.5)
        
        var transform = CATransform3DRotate(CATransform3DIdentity, -.pi/2.0, 0.0, 1.0, 0.0)
        transform.m34 = -1.0/500.0
        
        UIView.animate(withDuration: transitionDuration(using: context)) { [weak self] in
            guard let self = self else { return }
            self.fromView.layer.transform = transform
            self.fromView.layer.position = CGPoint(x: self.fromView.bounds.width, y: self.fromView.bounds.height*0.5)
        } completion: { [weak self] _ in
            self?.fromView.layer.position = position
            self?.fromView.layer.anchorPoint = anchorPoint
            self?.fromView.removeFromSuperview()
            self?.completeTransitionAnimation()
        }
    }
}
