//
//  MNProgressToast.swift
//  MNFoundation
//
//  Created by 冯盼 on 2021/9/10.
//  进度弹窗

import UIKit

class MNProgressToast: MNToast {
    
    // 标记进度
    private var percent: UILabel!
    // 进度条
    private var shape: CAShapeLayer!
    // 对钩
    private var complete: CAShapeLayer!
    
    override func createView() {
        super.createView()
        
        container.size = CGSize(width: 46.0, height: 46.0)
        
        percent = UILabel(frame: container.bounds)
        percent.text = "0%"
        percent.numberOfLines = 1
        percent.textAlignment = .center
        percent.textColor = Self.tintColor
        percent.font = UIFont.systemFont(ofSize: 13.0, weight: .medium)
        container.addSubview(percent)
        
        let lineWidth: CGFloat = 2.0
        
        var path = UIBezierPath(arcCenter: CGPoint(x: container.bounds.width/2.0, y: container.bounds.height/2.0), radius: (container.bounds.width - lineWidth)/2.0, startAngle: -.pi/2.0, endAngle: .pi + .pi/2.0, clockwise: true)
        
        shape = CAShapeLayer()
        shape.frame = container.bounds
        shape.contentsScale = UIScreen.main.scale
        shape.fillColor = UIColor.clear.cgColor
        shape.strokeColor = Self.tintColor.cgColor
        shape.lineWidth = lineWidth
        shape.lineCap = .round
        shape.lineJoin = .round
        shape.path = path.cgPath
        shape.strokeEnd = 0.0
        container.layer.addSublayer(shape)
        
        // 定义对钩范围
        let rect = container.bounds.inset(by: UIEdgeInsets(top: 12.0, left: 5.0, bottom: 12.0, right: 5.0))
        
        path = UIBezierPath()
        path.move(to: CGPoint(x: rect.minX + lineWidth/2.0, y: rect.minY + lineWidth/2.0))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY - lineWidth/2.0))
        path.addLine(to: CGPoint(x: rect.maxX - lineWidth/2.0, y: rect.minY + lineWidth/2.0))
        
        complete = CAShapeLayer()
        complete.frame = container.bounds
        complete.contentsScale = UIScreen.main.scale
        complete.fillColor = UIColor.clear.cgColor
        complete.strokeColor = Self.tintColor.cgColor
        complete.lineWidth = lineWidth
        complete.lineCap = .round
        complete.lineJoin = .round
        complete.path = path.cgPath
        complete.strokeStart = 0.17
        complete.strokeEnd = 0.17
        complete.isHidden = true
        container.layer.addSublayer(complete)
    }
    
    // 更新进度
    func update(progress: CGFloat) {
        guard complete.isHidden else { return }
        let pro: CGFloat = min(1.0, max(0.0, progress))
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        shape.strokeEnd = pro
        CATransaction.commit()
        let behavior: NSDecimalNumberHandler = NSDecimalNumberHandler(roundingMode: .down, scale: 0, raiseOnExactness: false, raiseOnOverflow: false, raiseOnUnderflow: false, raiseOnDivideByZero: false)
        let result: NSDecimalNumber = NSDecimalNumber(value: pro).multiplying(by: NSDecimalNumber(value: 100.0), withBehavior: behavior)
        let value: Int = result.intValue
        percent.text = "\(value)%"
        if value >= 100 {
            complete.isHidden = false
            self.perform(#selector(self.success), with: nil, afterDelay: 0.5)
        }
    }
    
    @objc func success() {
        guard complete.isHidden else { return }
        complete.isHidden = false
        UIView.animate(withDuration: 0.2) { [weak self] in
            self?.percent.alpha = 0.0
        }
        let animation = CABasicAnimation(keyPath: "strokeEnd")
        animation.duration = 0.5
        animation.toValue = 0.95
        //这两个属性设定保证在动画执行之后不自动还原
        animation.fillMode = .forwards
        animation.isRemovedOnCompletion = false
        animation.timingFunction = CAMediaTimingFunction(name: .easeIn)
        complete.add(animation, forKey: nil)
        self.perform(#selector(self.stop), with: nil, afterDelay: 1.2)
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
        Self.self.cancelPreviousPerformRequests(withTarget: self, selector: #selector(self.success), object: nil)
    }
}
