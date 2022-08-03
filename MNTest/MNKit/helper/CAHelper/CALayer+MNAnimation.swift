//
//  CALayer+MNAnimation.swift
//  MNFoundation
//
//  Created by 冯盼 on 2021/8/9.
//

import QuartzCore
import Foundation

public extension CALayer {
    
    var rotation: Double {
        set {
            setValue(newValue, forKey: "transform.rotation")
        }
        get {
            value(forKey: "transform.rotation") as? Double ?? 0.0
        }
    }
    
    var rotationX: Double {
        set {
            setValue(newValue, forKey: "transform.rotation.x")
        }
        get {
            value(forKey: "transform.rotation.x") as? Double ?? 0.0
        }
    }
    
    var rotationY: Double {
        set {
            setValue(newValue, forKey: "transform.rotation.y")
        }
        get {
            value(forKey: "transform.rotation.y") as? Double ?? 0.0
        }
    }
    
    var rotationZ: Double {
        set {
            setValue(newValue, forKey: "transform.rotation.z")
        }
        get {
            value(forKey: "transform.rotation.z") as? Double ?? 0.0
        }
    }
    
    var scale: CGFloat {
        set {
            setValue(newValue, forKey: "transform.scale")
        }
        get {
            value(forKey: "transform.scale") as? CGFloat ?? 0.0
        }
    }
    
    var scaleX: CGFloat {
        set {
            setValue(newValue, forKey: "transform.scale.x")
        }
        get {
            value(forKey: "transform.scale.x") as? CGFloat ?? 0.0
        }
    }
    
    var scaleY: CGFloat {
        set {
            setValue(newValue, forKey: "transform.scale.y")
        }
        get {
            value(forKey: "transform.scale.y") as? CGFloat ?? 0.0
        }
    }
    
    var scaleZ: CGFloat {
        set {
            setValue(newValue, forKey: "transform.scale.z")
        }
        get {
            value(forKey: "transform.scale.z") as? CGFloat ?? 0.0
        }
    }
    
    var translationX: CGFloat {
        set {
            setValue(newValue, forKey: "transform.translation.x")
        }
        get {
            value(forKey: "transform.translation.x") as? CGFloat ?? 0.0
        }
    }
    
    var translationY: CGFloat {
        set {
            setValue(newValue, forKey: "transform.translation.y")
        }
        get {
            value(forKey: "transform.translation.y") as? CGFloat ?? 0.0
        }
    }
    
    var translationZ: CGFloat {
        set {
            setValue(newValue, forKey: "transform.translation.z")
        }
        get {
            value(forKey: "transform.translation.z") as? CGFloat ?? 0.0
        }
    }
}


public extension CALayer {
    
    static func performWithoutAnimation(_ actionsWithoutAnimation: ()->Void) -> Void {
        animate(withDuration: 0.0, animations: actionsWithoutAnimation)
    }
    
    static func animate(withDuration duration: TimeInterval, animations: () -> Void, completion: (() -> Void)? = nil) -> Void {
        CATransaction.begin()
        CATransaction.setDisableActions(duration <= 0.0)
        CATransaction.setAnimationDuration(duration)
        CATransaction.setCompletionBlock(completion)
        animations()
        CATransaction.commit()
    }
    
    func transition(withDuration duration: TimeInterval, type: CATransitionType, subtype: CATransitionSubtype? = nil, animations: (CALayer)-> Void, completion: (() -> Void)? = nil) -> Void {
        let transition = CATransition()
        transition.type = type
        transition.subtype = subtype
        transition.duration = duration
        transition.autoreverses = false
        transition.timingFunction = CAMediaTimingFunction(name: .linear)
        transition.isRemovedOnCompletion = false
        transition.fillMode = .forwards
        animations(self)
        add(transition, forKey: nil)
        if let _ = completion {
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + duration) {
                completion?()
            }
        }
    }
    
}
