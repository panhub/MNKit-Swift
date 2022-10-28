//
//  MNMenuView.swift
//  MNTest
//
//  Created by 冯盼 on 2022/9/30.
//  菜单弹窗

import UIKit

class MNMenuView: UIView {
    
    /// 箭头方向
    enum ArrowDirection {
        case up, bottom, left, right
    }
    
    /// 动画类型
    enum AnimationType {
        case fade, zoom, move
    }
    /// 箭头大小
    var arrowSize: CGSize = CGSize(width: 12.0, height: 10.0)
    /// 箭头偏移
    var arrowOffset: UIOffset = .zero
    /// 边角大小
    var cornerRadius: CGFloat = 5.0
    /// 内容边距
    var contentInsets: UIEdgeInsets = UIEdgeInsets(top: 5.0, left: 5.0, bottom: 5.0, right: 5.0)
    /// 动画时长
    var animationDuration: TimeInterval = 0.23
    /// 填充颜色
    var fillColor: UIColor? = UIColor(red: 76.0/255.0, green: 76.0/255.0, blue: 76.0/255.0, alpha: 1.0)
    /// 边框颜色
    var borderColor: UIColor? = UIColor(red: 50.0/255.0, green: 50.0/255.0, blue: 50.0/255.0, alpha: 1.0)
    /// 边框宽度
    var borderWidth: CGFloat = 2.0
    /// 箭头方向
    var arrowDirection: MNMenuView.ArrowDirection = .up
    /// 动画类型
    var animationType: MNMenuView.AnimationType = .zoom
    /// 点击事件回调
    private var touchHandler: ((UIControl) -> Void)?
    /// 布局方向
    var axis: NSLayoutConstraint.Axis = .vertical
    /// 目标视图
    var targetView: UIView!
    /// 点击背景取消
    var dismissWhenTapped: Bool = true
    /// 内容视图
    private let contentView: UIView = UIView()
    /// 动画视图
    private let animatedView: UIView = UIView()
    /// 子菜单按钮集合
    private let arrangedView: UIView = UIView()
    
    /// 构造菜单视图
    /// - Parameters:
    ///   - views: 子视图集合
    ///   - axis: 布局方向
    init(arrangedViews views: [UIView], axis: NSLayoutConstraint.Axis) {
        super.init(frame: .zero)
        let maxWidth: CGFloat = views.reduce(0.0) { max($0, $1.frame.width) }
        let maxHeight: CGFloat = views.reduce(0.0) { max($0, $1.frame.height) }
        let totalWidth: CGFloat = views.reduce(0.0) { $0 + $1.frame.width }
        let totalHeight: CGFloat = views.reduce(0.0) { $0 + $1.frame.height }
        arrangedView.frame = CGRect(x: 0.0, y: 0.0, width: axis == .vertical ? maxWidth : totalWidth, height: axis == .vertical ? totalHeight : maxHeight)
        var x: CGFloat = 0.0
        var y: CGFloat = 0.0
        for view in views {
            var rect = view.frame
            if axis == .vertical {
                rect.origin.y = y
                rect.origin.x = arrangedView.frame.width/2.0 - rect.width/2.0
                y = rect.maxY
            } else {
                rect.origin.x = x
                rect.origin.y = arrangedView.frame.height/2.0 - rect.height/2.0
                x = rect.maxX
            }
            view.frame = rect
            if view is UIControl, let control = view as? UIControl, control.allTargets.count <= 0 {
                control.addTarget(self, action: #selector(menuTouchUpInside(_:)), for: .touchUpInside)
            }
            arrangedView.addSubview(view)
        }
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(backgroundTouchUpInside))
        tap.delegate = self
        tap.numberOfTapsRequired = 1
        addGestureRecognizer(tap)
    }
    
    /// 构造菜单视图
    /// - Parameters:
    ///   - titles: 标题集合
    ///   - axis: 布局方向
    convenience init(titles: String..., axis: NSLayoutConstraint.Axis) {
        let elements: [String] = titles.reduce(into: [String]()) { $0.append($1) }
        self.init(titles: elements, axis: axis)
    }
    
    /// 构造菜单视图
    /// - Parameters:
    ///   - titles: 标题集合
    ///   - axis: 布局方向
    convenience init(titles: [String], axis: NSLayoutConstraint.Axis) {
        let font: UIFont = .systemFont(ofSize: 16.0, weight: .medium)
        let width: CGFloat = titles.reduce(0.0) { max($0, ceil(($1 as NSString).size(withAttributes: [.font:font]).width)) }
        let height: CGFloat = axis == .vertical ? 45.0 : 30.0
        var arrangedViews: [UIView] = [UIView]()
        for (index, title) in titles.enumerated() {
            let button = UIButton(type: .custom)
            button.tag = index
            button.frame = CGRect(x: 0.0, y: 0.0, width: axis == .vertical ? width : ceil((title as NSString).size(withAttributes: [.font:font]).width), height: height)
            button.titleLabel?.font = font
            button.setTitle(title, for: .normal)
            button.setTitleColor(.white.withAlphaComponent(0.9), for: .normal)
            button.contentVerticalAlignment = .center
            button.contentHorizontalAlignment = .center
            arrangedViews.append(button)
            if index < (titles.count - 1) {
                let separator = UIView(frame: CGRect(x: 0.0, y: 0.0, width: (axis == .vertical ? button.frame.width : 1.0), height: (axis == .vertical ? 1.0 : (font.pointSize + 5.0))))
                separator.backgroundColor = UIColor(red: 50.0/255.0, green: 50.0/255.0, blue: 50.0/255.0, alpha: 1.0)
                arrangedViews.append(separator)
            }
        }
        self.init(arrangedViews: arrangedViews, axis: axis)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension MNMenuView {
    
    /// 显示菜单视图
    /// - Parameters:
    ///   - superview: 展示的父视图
    ///   - animated: 是否使用动画
    ///   - touchHandler: 按钮点击回调
    func show(in superview: UIView? = nil, animated: Bool = true, handler touchHandler: ((UIControl) -> Void)? = nil) {
        guard self.superview == nil else { return }
        guard arrangedView.frame.width > 0.0, arrangedView.frame.height > 0.0 else { return }
        guard let targetView = targetView else { return }
        guard let superview = superview ?? UIWindow.current else { return }
        guard let rect = targetView.superview?.convert(targetView.frame, to: superview) else { return }
        
        frame = superview.bounds
        superview.addSubview(self)
        self.touchHandler = touchHandler
        
        let arrowSize = arrowSize
        let arrowOffset = arrowOffset
        let borderWidth = borderWidth
        let cornerRadius = cornerRadius
        let contentInsets = contentInsets
        
        // 寻找分割线
        if borderWidth > 0.0, let borderColor = borderColor {
            for subview in arrangedView.subviews {
                guard min(subview.frame.width, subview.frame.height) == 1.0 else { continue }
                subview.backgroundColor = borderColor
            }
        }
        
        var anchorPoint: CGPoint = CGPoint(x: 0.5, y: 0.5)
        
        let bezierPath: UIBezierPath = UIBezierPath()
        
        switch arrowDirection {
        case .up:
            contentView.frame = CGRect(x: 0.0, y: 0.0, width: arrangedView.frame.width + contentInsets.left + contentInsets.right, height: arrangedView.frame.height + contentInsets.top + contentInsets.bottom + arrowSize.height)
            arrangedView.frame = CGRect(x: contentInsets.left, y: arrowSize.height + contentInsets.top, width: arrangedView.frame.width, height: arrangedView.frame.height)
            contentView.midX = rect.midX - arrowOffset.horizontal
            contentView.minY = rect.maxY + arrowOffset.vertical
            bezierPath.move(to: CGPoint(x: borderWidth/2.0, y: arrowSize.height + borderWidth + cornerRadius))
            bezierPath.addArc(withCenter: CGPoint(x: borderWidth + cornerRadius, y: arrowSize.height + borderWidth + cornerRadius), radius: cornerRadius + borderWidth/2.0, startAngle: .pi, endAngle: .pi/2.0 + .pi, clockwise: true)
            bezierPath.addLine(to: CGPoint(x: contentView.frame.width/2.0 - arrowSize.width/2.0 + borderWidth/2.0 + arrowOffset.horizontal, y: arrowSize.height + borderWidth/2.0))
            bezierPath.addLine(to: CGPoint(x: contentView.frame.width/2.0 + arrowOffset.horizontal, y: borderWidth/2.0))
            bezierPath.addLine(to: CGPoint(x: contentView.frame.width/2.0 + arrowSize.width/2.0 - borderWidth/2.0 + arrowOffset.horizontal, y: arrowSize.height + borderWidth/2.0))
            bezierPath.addLine(to: CGPoint(x: contentView.frame.width - borderWidth - cornerRadius, y: arrowSize.height + borderWidth/2.0))
            bezierPath.addArc(withCenter: CGPoint(x: contentView.frame.width - borderWidth - cornerRadius, y: arrowSize.height + borderWidth + cornerRadius), radius: cornerRadius + borderWidth/2.0, startAngle: -.pi/2.0, endAngle: 0.0, clockwise: true)
            bezierPath.addLine(to: CGPoint(x: contentView.frame.width - borderWidth/2.0, y: contentView.frame.height - borderWidth - cornerRadius))
            bezierPath.addArc(withCenter: CGPoint(x: contentView.frame.width - borderWidth - cornerRadius, y: contentView.frame.height - borderWidth - cornerRadius), radius: cornerRadius + borderWidth/2.0, startAngle: 0.0, endAngle: .pi/2.0, clockwise: true)
            bezierPath.addLine(to: CGPoint(x: borderWidth + cornerRadius, y: contentView.frame.height - borderWidth/2.0))
            bezierPath.addArc(withCenter: CGPoint(x: borderWidth + cornerRadius, y: contentView.frame.height - borderWidth - cornerRadius), radius: cornerRadius + borderWidth/2.0, startAngle: .pi/2.0, endAngle: .pi, clockwise: true)
            bezierPath.close()
            anchorPoint.y = 0.0
            anchorPoint.x = (contentView.frame.width/2.0 + arrowOffset.horizontal)/contentView.frame.width
        case .left:
            contentView.frame = CGRect(x: 0.0, y: 0.0, width: arrangedView.frame.width + contentInsets.left + contentInsets.right + arrowSize.height, height: arrangedView.frame.height + contentInsets.top + contentInsets.bottom)
            arrangedView.frame = CGRect(x: contentInsets.left + arrowSize.height, y: contentInsets.top, width: arrangedView.frame.width, height: arrangedView.frame.height)
            contentView.minX = rect.maxX + arrowOffset.horizontal
            contentView.midY = rect.midY - arrowOffset.vertical
            bezierPath.move(to: CGPoint(x: arrowSize.height + borderWidth/2.0, y: cornerRadius + borderWidth))
            bezierPath.addArc(withCenter: CGPoint(x: arrowSize.height + borderWidth + cornerRadius, y: borderWidth + cornerRadius), radius: cornerRadius + borderWidth/2.0, startAngle: .pi, endAngle: .pi/2.0 + .pi, clockwise: true)
            bezierPath.addLine(to: CGPoint(x: contentView.frame.width - borderWidth - cornerRadius, y: borderWidth/2.0))
            bezierPath.addArc(withCenter: CGPoint(x: contentView.frame.width - borderWidth - cornerRadius, y: borderWidth + cornerRadius), radius: cornerRadius + borderWidth/2.0, startAngle: -.pi/2.0, endAngle: 0.0, clockwise: true)
            bezierPath.addLine(to: CGPoint(x: contentView.frame.width - borderWidth/2.0, y: contentView.frame.height - cornerRadius - borderWidth))
            bezierPath.addArc(withCenter: CGPoint(x: contentView.frame.width - cornerRadius - borderWidth, y: contentView.frame.height - cornerRadius - borderWidth), radius: cornerRadius + borderWidth/2.0, startAngle: 0.0, endAngle: .pi/2.0, clockwise: true)
            bezierPath.addLine(to: CGPoint(x: arrowSize.width + borderWidth + cornerRadius, y: contentView.frame.height - borderWidth/2.0))
            bezierPath.addArc(withCenter: CGPoint(x: arrowSize.height + borderWidth + cornerRadius, y: contentView.frame.height - borderWidth - cornerRadius), radius: cornerRadius + borderWidth/2.0, startAngle: .pi/2.0, endAngle: .pi, clockwise: true)
            bezierPath.addLine(to: CGPoint(x: arrowSize.height + borderWidth/2.0, y: contentView.frame.height/2.0 + arrowSize.width/2.0 - borderWidth/2.0 + arrowOffset.vertical))
            bezierPath.addLine(to: CGPoint(x: borderWidth/2.0, y: contentView.frame.height/2.0 + arrowOffset.vertical))
            bezierPath.addLine(to: CGPoint(x: arrowSize.height + borderWidth/2.0, y: contentView.frame.height/2.0 - arrowSize.width/2.0 + borderWidth/2.0 + arrowOffset.vertical))
            bezierPath.close()
            anchorPoint.x = 0.0
            anchorPoint.y = (contentView.frame.height/2.0 + arrowOffset.vertical)/contentView.frame.height
        case .bottom:
            contentView.frame = CGRect(x: 0.0, y: 0.0, width: arrangedView.frame.width + contentInsets.left + contentInsets.right, height: arrangedView.frame.height + contentInsets.top + contentInsets.bottom + arrowSize.height)
            arrangedView.frame = CGRect(x: contentInsets.left, y: contentInsets.top, width: arrangedView.frame.width, height: arrangedView.frame.height)
            contentView.midX = rect.midX - arrowOffset.horizontal
            contentView.maxY = rect.minY + arrowOffset.vertical
            bezierPath.move(to: CGPoint(x: borderWidth/2.0, y: borderWidth + cornerRadius))
            bezierPath.addArc(withCenter: CGPoint(x: borderWidth + cornerRadius, y: borderWidth + cornerRadius), radius: cornerRadius + borderWidth/2.0, startAngle: .pi, endAngle: .pi/2.0 + .pi, clockwise: true)
            bezierPath.addLine(to: CGPoint(x: contentView.frame.width - borderWidth - cornerRadius, y: borderWidth/2.0))
            bezierPath.addArc(withCenter: CGPoint(x: contentView.frame.width - borderWidth - cornerRadius, y: borderWidth + cornerRadius), radius: cornerRadius + borderWidth/2.0, startAngle: -.pi/2.0, endAngle: 0.0, clockwise: true)
            bezierPath.addLine(to: CGPoint(x: contentView.frame.width - borderWidth/2.0, y: contentView.frame.height - arrowSize.height - borderWidth - cornerRadius))
            bezierPath.addArc(withCenter: CGPoint(x: contentView.frame.width - borderWidth - cornerRadius, y: contentView.frame.height - arrowSize.height - borderWidth - cornerRadius), radius: cornerRadius + borderWidth/2.0, startAngle: 0.0, endAngle: .pi/2.0, clockwise: true)
            bezierPath.addLine(to: CGPoint(x: contentView.frame.width/2.0 + arrowSize.width/2.0 - borderWidth/2.0 + arrowOffset.horizontal, y: contentView.frame.height - arrowSize.height - borderWidth/2.0))
            bezierPath.addLine(to: CGPoint(x: contentView.frame.width/2.0 + arrowOffset.horizontal, y: contentView.frame.height - borderWidth/2.0))
            bezierPath.addLine(to: CGPoint(x: contentView.frame.width/2.0 - arrowSize.width/2.0 + borderWidth/2.0, y: contentView.frame.height - arrowSize.height - borderWidth/2.0))
            bezierPath.addLine(to: CGPoint(x: cornerRadius + borderWidth, y: contentView.frame.height - arrowSize.height - borderWidth/2.0))
            bezierPath.addArc(withCenter: CGPoint(x: cornerRadius + borderWidth, y: contentView.frame.height - arrowSize.height - borderWidth - cornerRadius), radius: cornerRadius + borderWidth/2.0, startAngle: .pi/2.0, endAngle: .pi, clockwise: true)
            bezierPath.close()
            anchorPoint.y = 1.0
            anchorPoint.x = (contentView.frame.width/2.0 + arrowOffset.horizontal)/contentView.frame.width
        case .right:
            contentView.frame = CGRect(x: 0.0, y: 0.0, width: arrangedView.frame.width + contentInsets.left + contentInsets.right + arrowSize.height, height: arrangedView.frame.height + contentInsets.top + contentInsets.bottom)
            arrangedView.frame = CGRect(x: contentInsets.left, y: contentInsets.top, width: arrangedView.frame.width, height: arrangedView.frame.height)
            contentView.maxX = rect.minX + arrowOffset.horizontal
            contentView.midY = rect.midY - arrowOffset.vertical
            bezierPath.move(to: CGPoint(x: borderWidth/2.0, y: cornerRadius + borderWidth))
            bezierPath.addArc(withCenter: CGPoint(x: borderWidth + cornerRadius, y: borderWidth + cornerRadius), radius: cornerRadius + borderWidth/2.0, startAngle: .pi, endAngle: .pi/2.0 + .pi, clockwise: true)
            bezierPath.addLine(to: CGPoint(x: contentView.frame.width - arrowSize.height - borderWidth - cornerRadius, y: borderWidth/2.0))
            bezierPath.addArc(withCenter: CGPoint(x: contentView.frame.width - arrowSize.height - borderWidth - cornerRadius, y: borderWidth + cornerRadius), radius: cornerRadius + borderWidth/2.0, startAngle: -.pi/2.0, endAngle: 0.0, clockwise: true)
            bezierPath.addLine(to: CGPoint(x: contentView.frame.width - arrowSize.height - borderWidth/2.0, y: contentView.frame.height/2.0 - arrowSize.width/2.0 + borderWidth/2.0 + arrowOffset.vertical))
            bezierPath.addLine(to: CGPoint(x: contentView.frame.width - borderWidth/2.0, y: contentView.frame.height/2.0 + arrowOffset.vertical))
            bezierPath.addLine(to: CGPoint(x: contentView.frame.width - arrowSize.height - borderWidth/2.0, y: contentView.frame.height/2.0 + arrowSize.width/2.0 - borderWidth/2.0 + arrowOffset.vertical))
            bezierPath.addLine(to: CGPoint(x: contentView.frame.width - arrowSize.height - borderWidth/2.0, y: contentView.frame.height - borderWidth - cornerRadius))
            bezierPath.addArc(withCenter: CGPoint(x: contentView.frame.width - arrowSize.height - borderWidth - cornerRadius, y: contentView.frame.height - borderWidth - cornerRadius), radius: cornerRadius + borderWidth/2.0, startAngle: 0.0, endAngle: .pi/2.0, clockwise: true)
            bezierPath.addLine(to: CGPoint(x: cornerRadius + borderWidth, y: contentView.frame.height - borderWidth/2.0))
            bezierPath.addArc(withCenter: CGPoint(x: cornerRadius + borderWidth, y: contentView.frame.height - borderWidth - cornerRadius), radius: cornerRadius + borderWidth/2.0, startAngle: .pi/2.0, endAngle: .pi, clockwise: true)
            bezierPath.close()
            anchorPoint.x = 1.0
            anchorPoint.y = (contentView.frame.height/2.0 + arrowOffset.vertical)/contentView.frame.height
        }
        
        let maskLayer = CAShapeLayer()
        maskLayer.path = bezierPath.cgPath
        maskLayer.fillColor = (fillColor ?? .clear).cgColor
        maskLayer.strokeColor = (borderColor ?? .clear).cgColor
        maskLayer.lineWidth = borderWidth
        contentView.clipsToBounds = true
        contentView.layer.insertSublayer(maskLayer, at: 0)
        contentView.addSubview(arrangedView)
        addSubview(contentView)
        
        switch animationType {
        case .zoom:
            let frame = contentView.frame
            let point = contentView.layer.anchorPoint
            let xMargin = anchorPoint.x - point.x
            let yMargin = anchorPoint.y - point.y
            var position = contentView.layer.position
            position.x += xMargin*frame.width
            position.y += yMargin*frame.height
            contentView.layer.anchorPoint = anchorPoint
            contentView.layer.position = position
            contentView.transform = CGAffineTransform(scaleX: 0.001, y: 0.001)
            UIView.animate(withDuration: animated ? animationDuration : .leastNormalMagnitude, delay: 0.0, options: [.beginFromCurrentState, .curveEaseInOut], animations: { [weak self] in
                guard let self = self else { return }
                self.contentView.transform = .identity
            }, completion: nil)
        case .fade:
            contentView.alpha = 0.0
            UIView.animate(withDuration: animated ? animationDuration : .leastNormalMagnitude, delay: 0.0, options: [.beginFromCurrentState, .curveEaseInOut], animations: { [weak self] in
                guard let self = self else { return }
                self.contentView.alpha = 1.0
            }, completion: nil)
        case .move:
            let target = contentView.frame
            var frame = contentView.frame
            var autoresizingMask: UIView.AutoresizingMask = []
            switch arrowDirection {
            case .up:
                frame.size.height = 0.0
                autoresizingMask = [.flexibleTopMargin]
            case .left:
                frame.size.width = 0.0
                autoresizingMask = [.flexibleLeftMargin]
            case .bottom:
                frame.origin.y = frame.maxY
                frame.size.height = 0.0
                autoresizingMask = [.flexibleBottomMargin]
            case .right:
                frame.origin.x = frame.maxX
                frame.size.width = 0.0
                autoresizingMask = [.flexibleRightMargin]
            }
            arrangedView.autoresizingMask = autoresizingMask
            contentView.frame = frame
            UIView.animate(withDuration: animated ? animationDuration : .leastNormalMagnitude, delay: 0.0, options: [.beginFromCurrentState, .curveEaseInOut]) { [weak self] in
                guard let self = self else { return }
                self.contentView.frame = target
            } completion: { [weak self] _ in
                guard let self = self else { return }
                self.arrangedView.autoresizingMask = []
            }
        }
    }
    
    /// 取消菜单视图
    /// - Parameters:
    ///   - animated: 是否显示动画过程
    ///   - completionHandler: 结束回调
    func dismiss(animated: Bool = true, completion completionHandler: (()->Void)? = nil) {
        switch animationType {
        case .zoom:
            UIView.animate(withDuration: animated ? animationDuration : .leastNormalMagnitude, delay: 0.0, options: [.beginFromCurrentState, .curveEaseInOut]) { [weak self] in
                guard let self = self else { return }
                self.contentView.transform = CGAffineTransform(scaleX: 0.001, y: 0.001)
            } completion: { [weak self] _ in
                guard let self = self else { return }
                self.removeFromSuperview()
                completionHandler?()
            }
        case .fade:
            UIView.animate(withDuration: animated ? animationDuration : .leastNormalMagnitude, delay: 0.0, options: [.beginFromCurrentState, .curveEaseInOut]) { [weak self] in
                guard let self = self else { return }
                self.contentView.alpha = 0.0
            } completion: { [weak self] _ in
                guard let self = self else { return }
                self.removeFromSuperview()
                completionHandler?()
            }
        case .move:
            var target = contentView.frame
            var autoresizingMask: UIView.AutoresizingMask = []
            switch arrowDirection {
            case .up:
                target.size.height = 0.0
                autoresizingMask = [.flexibleTopMargin]
            case .left:
                target.size.width = 0.0
                autoresizingMask = [.flexibleLeftMargin]
            case .bottom:
                target.origin.y = frame.maxY
                target.size.height = 0.0
                autoresizingMask = [.flexibleBottomMargin]
            case .right:
                target.origin.x = frame.maxX
                target.size.width = 0.0
                autoresizingMask = [.flexibleRightMargin]
            }
            arrangedView.autoresizingMask = autoresizingMask
            UIView.animate(withDuration: animated ? animationDuration : .leastNormalMagnitude, delay: 0.0, options: [.beginFromCurrentState, .curveEaseInOut]) { [weak self] in
                guard let self = self else { return }
                self.contentView.frame = target
            } completion: { [weak self] _ in
                guard let self = self else { return }
                self.removeFromSuperview()
                completionHandler?()
            }
        }
    }
}

// MARK: - Event
private extension MNMenuView {
    
    @objc func menuTouchUpInside(_ sender: UIControl) {
        dismiss(animated: true) { [weak self] in
            guard let self = self else { return }
            self.touchHandler?(sender)
        }
    }
    
    @objc func backgroundTouchUpInside() {
        guard dismissWhenTapped else { return }
        dismiss()
    }
}

// MARK: - UIGestureRecognizerDelegate
extension MNMenuView: UIGestureRecognizerDelegate {
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        let location = touch.location(in: self)
        return contentView.frame.contains(location) == false
    }
}
