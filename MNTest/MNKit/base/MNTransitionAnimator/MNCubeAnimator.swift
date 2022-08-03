//
//  MNCubeAnimator.swift
//  MNFoundation
//
//  Created by 冯盼 on 2021/12/8.
//  魔方动画

import UIKit
import QuartzCore.CAAnimation

class MNCubeAnimator: MNTransitionAnimator {
    // 持续时间
    override var duration: TimeInterval { 0.35 }
    override func enterTransitionAnimation() {
        super.enterTransitionAnimation()
        
        toView.transform = .identity
        toView.frame = context.finalFrame(for: toController)
        containerView.insertSubview(toView, aboveSubview: fromView)
        
        let animation = CATransition()
        animation.delegate = self
        animation.duration = transitionDuration(using: context)
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        animation.type = CATransitionType(rawValue: "cube")
        animation.subtype = CATransitionSubtype(rawValue: "fromRight")
        containerView.layer.add(animation, forKey: "cube.enter")
    }
    override func leaveTransitionAnimation() {
        super.leaveTransitionAnimation()
        
        toView.transform = .identity
        toView.frame = context.finalFrame(for: toController)
        containerView.insertSubview(toView, belowSubview: fromView)
        
        fromView.removeFromSuperview()
        
        let animation = CATransition()
        animation.delegate = self
        animation.duration = transitionDuration(using: context)
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        animation.type = CATransitionType(rawValue: "cube")
        animation.subtype = CATransitionSubtype(rawValue: "fromLeft")
        containerView.layer.add(animation, forKey: "cube.leave")
    }
}

extension MNCubeAnimator: CAAnimationDelegate {
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        containerView?.layer.removeAllAnimations()
        context?.completeTransition(flag)
    }
}
