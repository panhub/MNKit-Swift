//
//  MNActivityIndicatorView.swift
//  TLChat
//
//  Created by 冯盼 on 2022/7/25.
//  活动指示图

import UIKit

class MNActivityIndicatorView: UIView {
    /// 线条宽度
    var lineWidth: CGFloat = 1.0
    /// 颜色
    var color: UIColor = .black
    /// 动画时长
    var duration: TimeInterval = 0.75
    /// 放置 ShapeLayer
    private let contentView: UIView = UIView()
    /// 显示指示图
    private let indicator: CAShapeLayer = CAShapeLayer()
    /// 设置内部旋转角度
    var rotationAngle: CGFloat {
        get { 0.0 }
        set { contentView.transform = CGAffineTransform(rotationAngle: newValue) }
    }
    
    private var _hidesWhenStopped: Bool = false
    /// 是否停止动画时隐藏指示图
    var hidesWhenStopped: Bool {
        get { _hidesWhenStopped }
        set {
            _hidesWhenStopped = newValue
            if newValue {
                indicator.isHidden = isAnimating == false
            } else {
                indicator.isHidden = false
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        contentView.frame = bounds
        contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(contentView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func willMove(toSuperview newSuperview: UIView?) {
        if let _ = newSuperview {
            /// 制作指示图
            updateIndicatorLayer()
        }
        super.willMove(toSuperview: newSuperview)
    }
    
    /// 更新指示图层
    func updateIndicatorLayer() {
        
        contentView.transform = .identity
        contentView.autoresizingMask = []
        
        indicator.mask = nil
        indicator.resumeAnimation()
        indicator.removeAllAnimations()
        indicator.removeFromSuperlayer()
        
        let lineWidth: CGFloat = max(self.lineWidth, 1.0)
        let sideWidth: CGFloat = min(bounds.width, bounds.height)
        
        contentView.frame = CGRect(x: (bounds.width - sideWidth)/2.0, y: (bounds.height - sideWidth)/2.0, width: sideWidth, height: sideWidth)
        
        let bezierPath = UIBezierPath(arcCenter: CGPoint(x: sideWidth/2.0, y: sideWidth/2.0), radius: (sideWidth - lineWidth)/2.0, startAngle: 0.0, endAngle: .pi*2.0, clockwise: true)
        
        indicator.frame = contentView.bounds
        indicator.contentsScale = UIScreen.main.scale
        indicator.fillColor = UIColor.clear.cgColor
        indicator.strokeColor = color.cgColor
        indicator.lineWidth = lineWidth
        indicator.lineCap = .round
        indicator.lineJoin = .round
        indicator.path = bezierPath.cgPath
        indicator.strokeEnd = 1.0
        
        let mask = CALayer()
        mask.frame = indicator.bounds
        mask.contentsScale = UIScreen.main.scale
        mask.contents = Bundle.indicator.image(named: "mask")?.cgImage
        indicator.mask = mask
        
        contentView.layer.addSublayer(indicator)
        
        let animation = CABasicAnimation(keyPath: "transform.rotation")
        animation.duration = duration
        animation.fromValue = 0.0
        animation.toValue = Double.pi*2.0
        animation.autoreverses = false
        animation.repeatCount = MAXFLOAT
        animation.isRemovedOnCompletion = false
        animation.fillMode = .forwards
        animation.beginTime = CACurrentMediaTime()
        animation.timingFunction = CAMediaTimingFunction(name: .linear)

        indicator.add(animation, forKey: "com.mn.indicator.animation")
        
        stopAnimating()
    }
}

// MARK: - 暂停/继续动画
extension MNActivityIndicatorView {
    
    /// 是否在动画
    var isAnimating: Bool {
        indicator.speed == 1.0
    }
    
    /// 开始动画
    func startAnimating() {
        indicator.isHidden = false
        indicator.resumeAnimation()
    }
    
    /// 停止动画
    func stopAnimating() {
        indicator.isHidden = hidesWhenStopped
        indicator.pauseAnimation()
    }
}

extension Bundle {
    
    /// 指示器资源束
    static let indicator: Bundle = {
        guard let path = Bundle(for: MNActivityIndicatorView.self).path(forResource: "MNActivityIndicatorView", ofType: "bundle") else { return .main }
        return Bundle(path: path)!
    }()
}
