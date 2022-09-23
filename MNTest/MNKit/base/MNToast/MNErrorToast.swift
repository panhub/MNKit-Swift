//
//  MNErrorToast.swift
//  MNFoundation
//
//  Created by 冯盼 on 2021/9/10.
//  错误弹窗

import UIKit

class MNErrorToast: MNToast {
    
    private var error: CAShapeLayer!
    
    override func createView() {
        super.createView()
        
        container.size = CGSize(width: 35.0, height: 34.0)
        
        let lineWidth: CGFloat = 2.5
        
        let rect = container.bounds.inset(by: UIEdgeInsets(top: lineWidth/2.0, left: lineWidth/2.0, bottom: lineWidth/2.0, right: lineWidth/2.0))
        
        let path = UIBezierPath()
        path.move(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        
        let error = CAShapeLayer()
        error.frame = container.bounds
        error.contentsScale = UIScreen.main.scale
        error.fillColor = UIColor.clear.cgColor
        error.strokeColor = Self.tintColor.cgColor
        error.lineWidth = lineWidth
        error.lineCap = .round
        error.lineJoin = .round
        error.path = path.cgPath
        error.strokeEnd = 0.0
        container.layer.addSublayer(error)
        self.error = error
    }
    
    override func start() {
        let animation = CABasicAnimation(keyPath: "strokeEnd")
        animation.duration = 0.5
        animation.fromValue = 0.0
        animation.toValue = 1.0
        //这两个属性设定保证在动画执行之后不自动还原
        animation.fillMode = .forwards
        animation.isRemovedOnCompletion = false
        animation.timingFunction = CAMediaTimingFunction(name: .easeIn)
        error.add(animation, forKey: nil)
        self.perform(#selector(self.stop), with: nil, afterDelay: MNToast.duration(status: string?.string))
    }
    
    override func stop() {
        UIView.animate(withDuration: Self.fadeAnimationDuration, delay: 0.0, options: .curveEaseOut) { [weak self] in
            self?.contentView.alpha = 0.0
            self?.contentView.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        } completion: { [weak self] finish in
            guard let self = self else { return }
            self.removeFromSuperview()
        }
    }
    
    override func cancel() {
        Self.self.cancelPreviousPerformRequests(withTarget: self, selector: #selector(self.stop), object: nil)
    }
}
