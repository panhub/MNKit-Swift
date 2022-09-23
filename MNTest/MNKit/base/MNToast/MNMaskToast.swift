//
//  MNMaskToast.swift
//  MNFoundation
//
//  Created by 冯盼 on 2021/9/10.
//  Mask弹窗

import UIKit

class MNMaskToast: MNToast {
    
    private var indicator: CALayer!

    override func createView() {
        super.createView()
        
        container.size = CGSize(width: 42.0, height: 42.0)
        
        let lineWidth: CGFloat = 2.0
        
        let path = UIBezierPath(arcCenter: CGPoint(x: container.bounds.width/2.0, y: container.bounds.height/2.0), radius: (container.bounds.width - lineWidth)/2.0, startAngle: 0.0, endAngle: .pi*2.0, clockwise: true)
        let indicator = CAShapeLayer()
        indicator.frame = container.bounds
        indicator.contentsScale = UIScreen.main.scale
        indicator.fillColor = UIColor.clear.cgColor
        indicator.strokeColor = Self.tintColor.cgColor
        indicator.lineWidth = lineWidth
        indicator.lineCap = .round
        indicator.lineJoin = .round
        indicator.path = path.cgPath
        indicator.strokeEnd = 1.0
        
        let mask = CALayer()
        mask.frame = indicator.bounds
        mask.contentsScale = UIScreen.main.scale
        mask.contents = MNToast.image(named: "mask")?.cgImage
        indicator.mask = mask
        
        container.layer.addSublayer(indicator)
        self.indicator = indicator
        
        let animation = CABasicAnimation(keyPath: "transform.rotation")
        animation.duration = 0.75
        animation.fromValue = 0.0
        animation.toValue = Double.pi*2.0
        animation.repeatCount = MAXFLOAT
        animation.isRemovedOnCompletion = false
        animation.fillMode = .forwards
        animation.autoreverses = false
        animation.timingFunction = CAMediaTimingFunction(name: .linear)

        indicator.add(animation, forKey: "rotation")
    }
    
    override func removeFromSuperview() {
        indicator?.removeAllAnimations()
        super.removeFromSuperview()
    }
}
