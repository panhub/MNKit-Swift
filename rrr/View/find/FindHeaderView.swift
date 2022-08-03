//
//  FindHeaderView.swift
//  TLChat
//
//  Created by 冯盼 on 2022/7/25.
//  发现-表头

import UIKit

class FindHeaderView: UIView {
    /// 显示外形
    private lazy var shapeLayer: CAShapeLayer = {
        let shapeLayer: CAShapeLayer = CAShapeLayer()
        shapeLayer.strokeColor = UIColor.clear.cgColor
        shapeLayer.contentsScale = UIScreen.main.scale
        shapeLayer.lineCap = .round
        shapeLayer.lineJoin = .round
        shapeLayer.strokeEnd = 1.0
        return shapeLayer
    }()
    /// 记录父视图
    private(set) weak var scrollView: UIScrollView?
    /// 记录图片原始位置
    private var imageViewY: CGFloat = 0.0
    /// 监听的key
    private let observeKeyPath: String = "contentOffset"
    /// 底部高度
    var margin: CGFloat = 50.0
    /// 颜色
    var color: UIColor = .red
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        layer.addSublayer(shapeLayer)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        guard let scrollView = superview as? UIScrollView else { return }
        self.scrollView = scrollView
        scrollView.alwaysBounceVertical = true
        scrollView.addObserver(self, forKeyPath: observeKeyPath, options: .new, context: nil)
    }
    
    override func removeFromSuperview() {
        if let scrollView = superview as? UIScrollView {
            self.scrollView = nil
            scrollView.removeObserver(self, forKeyPath: observeKeyPath)
        }
        super.removeFromSuperview()
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard let keyPath = keyPath, keyPath == observeKeyPath else { return }
        updateShapeLayer()
    }
    
    private func updateShapeLayer() {
        guard let scrollView = scrollView else { return }
        let contentOffset: CGPoint = scrollView.contentOffset
        let offsetY: CGFloat = contentOffset.y
        let top: CGFloat = scrollView.contentInset.top
        guard offsetY <= -top else { return }
        
        var frame = bounds
        frame.size.height = frame.height - offsetY
        frame.origin.y = bounds.height - frame.height
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        CATransaction.setAnimationDuration(0.0)
        shapeLayer.frame = frame
        CATransaction.commit()
        
        let path = UIBezierPath()
        path.move(to: .zero)
        path.addLine(to: CGPoint(x: 0.0, y: frame.height - margin))
        path.addQuadCurve(to: CGPoint(x: frame.width, y: frame.height - margin), controlPoint: CGPoint(x: frame.width/2.0, y: frame.height))
        path.addLine(to: CGPoint(x: frame.width, y: 0.0))
        path.close()
        
        shapeLayer.path = path.cgPath
        shapeLayer.fillColor = color.cgColor
    }
}
