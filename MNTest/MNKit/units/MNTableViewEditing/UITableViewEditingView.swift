//
//  UITableViewEditingView.swift
//  MNTest
//
//  Created by 冯盼 on 2022/8/22.
//  表格编辑视图

import UIKit

protocol UITableViewEditingHandler: NSObjectProtocol {
    
    /// 按钮第一次点击事件 可选择提交二次视图
    /// - Parameters:
    ///   - editingView: 编辑视图
    ///   - index: 按钮索引
    func editingView(_ editingView: UITableViewEditingView, actionTouchUpInsideAt index: Int) -> Void
}

class UITableViewEditingView: UIView {
    
    /// 配置信息
    @objc let options: UITableViewEditingOptions
    
    /// 当前的拖拽方向
    private(set) var direction: UITableViewCell.EditingDirection = .left
    
    /// 事件代理
    weak var delegate: UITableViewEditingHandler?
    
    /// 添加的按钮
    @objc private(set) var actions: [UIView] = [UIView]()
    
    /// 当前按钮的总宽度
    @objc var sum: CGFloat { actions.reduce(0.0) { $0 + $1.frame.width } }
    
    /// 依据配置信息构造
    /// - Parameter options: 配置信息
    init(options: UITableViewEditingOptions) {
        self.options = options
        super.init(frame: .zero)
        clipsToBounds = true
        backgroundColor = options.backgroundColor
        layer.cornerRadius = options.cornerRadius
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// 添加至父视图时 决定自身高度
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        if let superview = superview {
            var rect = superview.bounds
            if direction == .left {
                rect.origin.x = rect.width - options.contentInset.right
            } else {
                rect.origin.x = options.contentInset.left
            }
            rect.size.width = 0.0
            rect.origin.y = options.contentInset.top
            rect.size.height = max(0.0, rect.height - options.contentInset.top - options.contentInset.bottom)
            autoresizingMask = []
            frame = rect
            autoresizingMask = [.flexibleHeight]
        }
    }
    
    /// 更新编辑方向
    /// - Parameter direction: 指定方向
    func update(direction: UITableViewCell.EditingDirection) {
        guard direction != .none, self.direction != direction else { return }
        self.direction = direction
        // 更新子视图
        for subview in subviews {
            guard subview.subviews.count > 0 else { continue }
            let action = subview.subviews.first!
            action.autoresizingMask = []
            var rect = action.frame
            var autoresizingMask: UIView.AutoresizingMask = []
            if direction == .left {
                rect.origin.x = 0.0
                autoresizingMask = [.flexibleTopMargin, .flexibleBottomMargin]
            } else {
                rect.origin.x = subview.frame.width - rect.width
                autoresizingMask = [.flexibleLeftMargin, .flexibleTopMargin, .flexibleBottomMargin]
            }
            action.frame = rect
            action.autoresizingMask = autoresizingMask
        }
        // 更新位置
        if let superview = superview {
            var rect = frame
            if direction == .left {
                rect.origin.x = superview.frame.width - rect.width - options.contentInset.right
            } else {
                rect.origin.x = options.contentInset.left
            }
            autoresizingMask = []
            frame = rect
            autoresizingMask = [.flexibleHeight]
        }
    }
    
    /// 更新编辑视图(往编辑视图上添加子视图)
    /// - Parameter subviews: 子视图集合
    func update(actions: [UIView]) {
        removeAllActions()
        self.actions.append(contentsOf: actions)
        // 添加子视图
        for (index, action) in actions.enumerated() {
            let control = UIControl(frame: CGRect(x: 0.0, y: 0.0, width: action.frame.width, height: frame.height))
            control.tag = index
            control.clipsToBounds = true
            control.backgroundColor = action.backgroundColor
            control.autoresizingMask = [.flexibleHeight]
            control.addTarget(self, action: #selector(buttonTouchUpInside(_:)), for: .touchUpInside)
            action.autoresizingMask = []
            action.isUserInteractionEnabled = false
            action.center = CGPoint(x: control.bounds.midX, y: control.bounds.midY)
            if direction == .left {
                action.autoresizingMask = [.flexibleTopMargin, .flexibleBottomMargin]
            } else {
                action.autoresizingMask = [.flexibleLeftMargin, .flexibleTopMargin, .flexibleBottomMargin]
            }
            control.addSubview(action)
            addSubview(control)
        }
        // 更新宽度
        update(width: frame.width)
    }
    
    /// 提交二次点击视图
    /// - Parameters:
    ///   - index: 子视图索引
    ///   - action: 替换的子视图
    func replacing(index: Int, action: UIView) {
        let count = subviews.count
        guard index < count else { return }
        actions.removeAll()
        actions.append(action)
        let others: [UIView] = subviews.filter { $0.tag != index }
        let subview = subviews[index]
        subview.tag = 0
        (subview as? UIControl)?.removeTarget(nil, action: nil, for: .touchUpInside)
        for sub in subview.subviews.reversed() {
            sub.removeFromSuperview()
        }
        if let backgroundColor = action.backgroundColor {
            subview.backgroundColor = backgroundColor
        }
        if action.subviews.count <= 0 {
            action.isUserInteractionEnabled = true
        }
        var rect = action.frame
        rect.origin.x = 0.0
        rect.origin.y = (subview.frame.height - rect.height)/2.0
        action.autoresizingMask = []
        action.frame = rect
        subview.addSubview(action)
        bringSubviewToFront(subview)
        isUserInteractionEnabled = false
        UIView.animate(withDuration: 0.7, delay: 0.0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1.0, options: [.beginFromCurrentState, .curveEaseInOut]) { [weak self] in
            guard let self = self else { return }
            var rect = subview.frame
            rect.origin = .zero
            rect.size.width = action.frame.width
            subview.frame = rect
            action.center = CGPoint(x: subview.bounds.midX, y: subview.bounds.midY)
            rect = self.frame
            rect.size.width = subview.frame.width
            if self.direction == .left , let superview = self.superview {
                let spacing = self.options.contentInset.right
                rect.origin.x = superview.frame.width - rect.width - spacing
            }
            self.frame = rect
        } completion: { [weak self] _ in
            guard let self = self else { return }
            self.isUserInteractionEnabled = true
            if self.direction == .left {
                action.autoresizingMask = [.flexibleTopMargin, .flexibleBottomMargin]
            } else {
                action.autoresizingMask = [.flexibleLeftMargin, .flexibleTopMargin, .flexibleBottomMargin]
            }
            for other in others {
                other.removeFromSuperview()
            }
        }
    }
    
    /// 更新编辑视图的宽度
    /// - Parameter width: 指定宽度
    func update(width: CGFloat) {
        var x: CGFloat = 0.0
        let max: CGFloat = sum
        for (index, action) in actions.enumerated() {
            let scale = action.frame.width/max
            let subview = subviews[index]
            var rect = subview.frame
            rect.origin.x = x
            rect.size.width = min(ceil(width*scale), width - x)
            subview.frame = rect
            x += rect.width
        }
    }
    
    /// 按钮点击事件
    /// - Parameter sender: 按钮
    @objc private func buttonTouchUpInside(_ sender: UIView) {
        guard sender.tag < actions.count else { return }
        delegate?.editingView(self, actionTouchUpInsideAt: sender.tag)
    }
    
    /// 删除所有按钮
    func removeAllActions() {
        actions.removeAll()
        for subview in subviews.reversed() {
            subview.removeFromSuperview()
        }
    }

    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */
}
