//
//  MNAssetProgressView.swift
//  MNFoundation
//
//  Created by 冯盼 on 2021/10/9.
//  进度显示

import UIKit

class MNAssetProgressView: UIView {
    
    private lazy var progressLayer: CAShapeLayer = {
        let radius: CGFloat = layer.cornerRadius - layer.borderWidth
        let bezierPath = UIBezierPath(arcCenter: CGPoint(x: bounds.midX, y: bounds.midY), radius: radius/2.0, startAngle: -.pi/2.0, endAngle: .pi/2.0 + .pi, clockwise: true)
        let progressLayer = CAShapeLayer()
        progressLayer.path = bezierPath.cgPath
        progressLayer.fillColor = UIColor.clear.cgColor
        progressLayer.strokeColor = layer.borderColor
        progressLayer.lineWidth = radius
        progressLayer.strokeStart = 0.0
        progressLayer.strokeEnd = 0.0
        return progressLayer
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        clipsToBounds = true
        isUserInteractionEnabled = false
        backgroundColor = .black.withAlphaComponent(0.15)
        layer.borderWidth = 1.5
        layer.cornerRadius = min(frame.width, frame.height)/2.0
        layer.borderColor = UIColor.white.withAlphaComponent(0.7).cgColor
        
        layer.addSublayer(progressLayer)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - 修改进度
extension MNAssetProgressView {
    
    func set(progress: Double, animated: Bool = false) {
        CATransaction.begin()
        CATransaction.setDisableActions(!animated)
        progressLayer.strokeEnd = CGFloat(progress)
        CATransaction.commit()
    }
}
