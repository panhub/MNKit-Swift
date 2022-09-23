//
//  MNTailorHandler.swift
//  MNTest
//
//  Created by 冯盼 on 2022/9/23.
//  视频裁剪把手

import UIKit

/// 滑动代理
protocol MNTailorHandlerDelegate: NSObjectProtocol {
    /// 左滑手开始滑动
    /// - Parameter tailorHandler: 滑手
    func tailorLeftHandlerBeginDragging(_ tailorHandler: MNTailorHandler) -> Void
    /// 左滑手滑动中
    /// - Parameter tailorHandler: 滑手
    func tailorLeftHandlerDidDragging(_ tailorHandler: MNTailorHandler) -> Void
    /// 左滑手停止滑动
    /// - Parameter tailorHandler: 滑手
    func tailorLeftHandlerEndDragging(_ tailorHandler: MNTailorHandler) -> Void
    /// 右滑手开始滑动
    /// - Parameter tailorHandler: 滑手
    func tailorRightHandlerBeginDragging(_ tailorHandler: MNTailorHandler) -> Void
    /// 右滑手滑动中
    /// - Parameter tailorHandler: 滑手
    func tailorRightHandlerDidDragging(_ tailorHandler: MNTailorHandler) -> Void
    /// 右滑手停止滑动
    /// - Parameter tailorHandler: 滑手
    func tailorRightHandlerEndDragging(_ tailorHandler: MNTailorHandler) -> Void
}

class MNTailorHandler: UIView {
    
    enum Status {
        case none, left, right
    }
    /// 动画持续时长
    private let AnimationDuration: TimeInterval = 0.2
    /// 拖动状态
    private(set) var status: Status = .none
    /// 正常颜色
    var normalColor: UIColor = .black
    /// 高亮颜色
    var highlightedColor: UIColor = .white
    /// 滑手上线条颜色
    var lineColor: UIColor = .white
    /// 控件大小约束
    var contentInset: UIEdgeInsets = UIEdgeInsets(top: 3.3, left: 22.0, bottom: 3.3, right: 22.0)
    /// 滑手触发区域
    var handlerTouchInset: UIEdgeInsets = .zero
    /// 滑手的路径宽度
    var lineWidth: CGFloat = 3.0
    /// 左滑手
    let leftHandler: UIView = UIView()
    /// 右滑手
    let rightHandler: UIView = UIView()
    /// 顶部分割线
    let topSeparator: UIView = UIView()
    /// 底部分割线
    let bottomSeparator: UIView = UIView()
    /// 最小间隔
    var spacing: CGFloat = 10.0
    /// 是否在拖拽滑手
    var isDragging: Bool = false
    /// 事件代理
    weak var delegate: MNTailorHandlerDelegate?
    /// 左滑手正常层
    private let leftHandlerNormalLayer: CAShapeLayer = CAShapeLayer()
    /// 右滑手正常层
    private let rightHandlerNormalLayer: CAShapeLayer = CAShapeLayer()
    /// 左滑手高亮层
    private let leftHandlerHighlightedLayer: CAShapeLayer = CAShapeLayer()
    /// 右滑手高亮层
    private let rightHandlerHighlightedLayer: CAShapeLayer = CAShapeLayer()
    /// 圆角
    var radius: CGFloat = 5.0 {
        didSet {
            leftHandler.layer.mask(radius: radius, corners: [.topLeft, .bottomLeft])
            rightHandler.layer.mask(radius: radius, corners: [.topRight, .bottomRight])
        }
    }
    /// 是否是高亮状态
    var isHighlighted: Bool = false {
        didSet {
            setHighlighted(isHighlighted, animated: false)
        }
    }
    
    override func willMove(toSuperview newSuperview: UIView?) {
        if let _ = newSuperview, subviews.count <= 0 {
            
            leftHandler.frame = CGRect(x: 0.0, y: 0.0, width: contentInset.left, height: frame.height)
            leftHandler.backgroundColor = normalColor
            addSubview(leftHandler)
            
            let leftHandlerPath = UIBezierPath()
            leftHandlerPath.move(to: CGPoint(x: leftHandler.frame.width/2.0, y: leftHandler.frame.height/4.0 + lineWidth/2.0))
            leftHandlerPath.addLine(to: CGPoint(x: leftHandler.frame.width/2.0 - lineWidth, y: leftHandler.frame.height/2.0))
            leftHandlerPath.addLine(to: CGPoint(x: leftHandler.frame.width/2.0, y: leftHandler.frame.height/4.0*3.0 - lineWidth/2.0))
            
            leftHandlerNormalLayer.path = leftHandlerPath.cgPath
            leftHandlerNormalLayer.lineWidth = lineWidth
            leftHandlerNormalLayer.strokeColor = lineColor.cgColor
            leftHandlerNormalLayer.fillColor = UIColor.clear.cgColor
            leftHandlerNormalLayer.lineCap = .round
            leftHandlerNormalLayer.lineJoin = .round
            leftHandler.layer.addSublayer(leftHandlerNormalLayer)
            
            leftHandlerHighlightedLayer.opacity = 0.0
            leftHandlerHighlightedLayer.path = leftHandlerPath.cgPath
            leftHandlerHighlightedLayer.lineWidth = lineWidth
            leftHandlerHighlightedLayer.strokeColor = normalColor.cgColor
            leftHandlerHighlightedLayer.fillColor = UIColor.clear.cgColor
            leftHandlerHighlightedLayer.lineCap = .round
            leftHandlerHighlightedLayer.lineJoin = .round
            leftHandler.layer.addSublayer(leftHandlerHighlightedLayer)
            
            rightHandler.frame = CGRect(x: frame.width - contentInset.right, y: 0.0, width: contentInset.right, height: frame.height)
            rightHandler.backgroundColor = normalColor
            addSubview(rightHandler)
            
            let rightHandlerPath = UIBezierPath()
            rightHandlerPath.move(to: CGPoint(x: rightHandler.frame.width/2.0, y: rightHandler.frame.height/4.0 + lineWidth/2.0))
            rightHandlerPath.addLine(to: CGPoint(x: rightHandler.frame.width/2.0 + lineWidth, y: rightHandler.frame.height/2.0))
            rightHandlerPath.addLine(to: CGPoint(x: rightHandler.frame.width/2.0, y: rightHandler.frame.height/4.0*3.0 - lineWidth/2.0))
            
            rightHandlerNormalLayer.path = rightHandlerPath.cgPath
            rightHandlerNormalLayer.lineWidth = lineWidth
            rightHandlerNormalLayer.strokeColor = lineColor.cgColor
            rightHandlerNormalLayer.fillColor = UIColor.clear.cgColor
            rightHandlerNormalLayer.lineCap = .round
            rightHandlerNormalLayer.lineJoin = .round
            rightHandler.layer.addSublayer(rightHandlerNormalLayer)
            
            rightHandlerHighlightedLayer.opacity = 0.0
            rightHandlerHighlightedLayer.path = rightHandlerPath.cgPath
            rightHandlerHighlightedLayer.lineWidth = lineWidth
            rightHandlerHighlightedLayer.strokeColor = normalColor.cgColor
            rightHandlerHighlightedLayer.fillColor = UIColor.clear.cgColor
            rightHandlerHighlightedLayer.lineCap = .round
            rightHandlerHighlightedLayer.lineJoin = .round
            rightHandler.layer.addSublayer(rightHandlerHighlightedLayer)
            
            topSeparator.frame = CGRect(x: contentInset.left, y: 0.0, width: frame.width - contentInset.left - contentInset.right, height: contentInset.top)
            topSeparator.backgroundColor = normalColor
            topSeparator.isUserInteractionEnabled = false
            addSubview(topSeparator)
            
            bottomSeparator.frame = CGRect(x: contentInset.left, y: frame.height - contentInset.bottom, width: frame.width - contentInset.left - contentInset.right, height: contentInset.bottom)
            bottomSeparator.backgroundColor = normalColor
            bottomSeparator.isUserInteractionEnabled = false
            addSubview(bottomSeparator)
            
            let radius = radius
            self.radius = radius
        }
        super.willMove(toSuperview: newSuperview)
    }

    func inspectHighlighted(animated: Bool) {
        let isNormal = abs(leftHandler.frame.minX) <= 0.1 && abs(frame.width - rightHandler.frame.maxX) <= 0.1
        if isNormal {
            UIView.animate(withDuration: animated ? AnimationDuration : 0.0, delay: 0.0, options: [.beginFromCurrentState, .curveEaseInOut], animations: { [weak self] in
                guard let self = self else { return }
                self.leftHandler.minX = 0.0
                self.rightHandler.maxX = self.frame.width
                self.topSeparator.minX = self.leftHandler.maxX
                self.topSeparator.width = self.rightHandler.minX - self.leftHandler.maxX
                self.bottomSeparator.minX = self.topSeparator.minX
                self.bottomSeparator.width = self.topSeparator.width
            }, completion: nil)
        }
        if isNormal == isHighlighted {
            setHighlighted(isNormal == false, animated: animated)
        }
    }
    
    func setHighlighted(_ highlighted: Bool, animated: Bool) {
        if highlighted == isHighlighted { return }
        isHighlighted = highlighted
        CATransaction.begin()
        CATransaction.setDisableActions(animated == false)
        CATransaction.setAnimationDuration(animated ? AnimationDuration : 0.0)
        leftHandlerNormalLayer.opacity = highlighted ? 0.0 : 1.0
        rightHandlerNormalLayer.opacity = leftHandlerNormalLayer.opacity
        leftHandlerHighlightedLayer.opacity = highlighted ? 1.0 : 0.0
        rightHandlerHighlightedLayer.opacity = leftHandlerHighlightedLayer.opacity
        CATransaction.commit()
        UIView.animate(withDuration: animated ? AnimationDuration : 0.0, delay: 0.0, options: [.beginFromCurrentState, .curveEaseInOut], animations: { [weak self] in
            guard let self = self else { return }
            let color = highlighted ? self.highlightedColor : self.normalColor
            self.leftHandler.backgroundColor = color
            self.rightHandler.backgroundColor = color
            self.topSeparator.backgroundColor = color
            self.bottomSeparator.backgroundColor = color
        }, completion: nil)
    }

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        return leftHandler.frame.inset(by: handlerTouchInset).contains(point) || rightHandler.frame.inset(by: handlerTouchInset).contains(point)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let location = touches.first?.location(in: self) else { return }
        if leftHandler.frame.inset(by: handlerTouchInset).contains(location) {
            status = .left
            delegate?.tailorLeftHandlerBeginDragging(self)
        } else if rightHandler.frame.inset(by: handlerTouchInset).contains(location) {
            status = .right
            delegate?.tailorRightHandlerBeginDragging(self)
        } else {
            status = .none
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard status != .none else { return }
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let previous = touch.previousLocation(in: self)
        let transition = location.x - previous.x
        if status == .left {
            leftHandler.minX += transition
            leftHandler.minX = max(0.0, leftHandler.minX)
            leftHandler.maxX = min(leftHandler.maxX, rightHandler.minX - spacing)
        } else {
            rightHandler.minX += transition
            rightHandler.minX = max(rightHandler.minX, leftHandler.maxX + spacing)
            rightHandler.maxX = min(frame.width, rightHandler.maxX)
        }
        topSeparator.minX = leftHandler.maxX
        topSeparator.width = rightHandler.minX - leftHandler.maxX
        bottomSeparator.minX = topSeparator.minX
        bottomSeparator.width = topSeparator.width
        if status == .left {
            delegate?.tailorLeftHandlerDidDragging(self)
        } else {
            delegate?.tailorRightHandlerDidDragging(self)
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard status != .none else { return }
        status = .none
        if status == .left {
            delegate?.tailorLeftHandlerEndDragging(self)
        } else {
            delegate?.tailorRightHandlerEndDragging(self)
        }
    }
}
