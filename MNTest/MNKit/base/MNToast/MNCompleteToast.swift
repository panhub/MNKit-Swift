//
//  MNCompleteToast.swift
//  MNFoundation
//
//  Created by 冯盼 on 2021/9/10.
//  完成弹窗

import UIKit

class MNCompleteToast: MNToast {
    
    private var complete: CAShapeLayer!
    
    override func createView() {
        super.createView()
        
        container.size = CGSize(width: 55.0, height: 31.0)
        
        let lineWidth: CGFloat = 2.5
        
        let path = UIBezierPath()
        path.move(to: CGPoint(x: lineWidth/2.0, y: lineWidth/2.0))
        path.addLine(to: CGPoint(x: container.bounds.midX, y: container.bounds.height - lineWidth/2.0))
        path.addLine(to: CGPoint(x: container.bounds.width - lineWidth/2.0, y: lineWidth/2.0))
        
        let complete = CAShapeLayer()
        complete.frame = container.bounds
        complete.contentsScale = UIScreen.main.scale
        complete.fillColor = UIColor.clear.cgColor
        complete.strokeColor = Self.tintColor.cgColor
        complete.lineWidth = lineWidth
        complete.lineCap = .round
        complete.lineJoin = .round
        complete.path = path.cgPath
        complete.strokeStart = 0.2
        complete.strokeEnd = 0.2
        container.layer.addSublayer(complete)
        self.complete = complete
    }
    
    override func start() {
        let animation = CABasicAnimation(keyPath: "strokeEnd")
        animation.duration = 0.5
        animation.toValue = 1.0
        //这两个属性设定保证在动画执行之后不自动还原
        animation.fillMode = .forwards
        animation.isRemovedOnCompletion = false
        animation.timingFunction = CAMediaTimingFunction(name: .easeIn)
        complete.add(animation, forKey: nil)
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
