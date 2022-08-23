//
//  UITableViewCellEditingView.swift
//  MNTest
//
//  Created by 冯盼 on 2022/8/22.
//

import UIKit

protocol UITableViewCellEditingHandler: NSObjectProtocol {
    
    /// 按钮第一次点击事件 可选择提交二次视图
    /// - Parameters:
    ///   - editingView: 编辑视图
    ///   - index: 按钮索引
    func editingView(_ editingView: UITableViewCellEditingView, didTouchActionAt index: Int) -> Void
}

class UITableViewCellEditingView: UIView {
    
    /// 配置信息
    @objc let options: UITableViewEditingOptions
    
    /// 事件代理
    weak var delegate: UITableViewCellEditingHandler?
    
    /// 添加的按钮
    @objc private(set) var actions: [UIView] = [UIView]()
    
    /// 当前按钮的总宽度
    @objc var sum: CGFloat { actions.reduce(0.0) { $0 + $1.frame.width } }
    
    /// 依据配置信息构造
    /// - Parameter options: 配置信息
    init(options: UITableViewEditingOptions) {
        self.options = options
        super.init(frame: .zero)
        self.clipsToBounds = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// 添加至父视图时 决定自身高度
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        if let cell = superview as? UITableViewCell {
            var rect = cell.bounds
            rect.origin.x = rect.width - options.contentInset.right
            rect.origin.y = options.contentInset.top
            rect.size.width = 0.0
            rect.size.height = max(0.0, rect.height - options.contentInset.top - options.contentInset.bottom)
            frame = rect
            layer.cornerRadius = options.cornerRadius
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
            control.addTarget(self, action: #selector(buttonTouchUpInside(_:)), for: .touchUpInside)
            action.autoresizingMask = []
            action.isUserInteractionEnabled = false
            action.center = CGPoint(x: control.bounds.midX, y: control.bounds.midY)
            action.autoresizingMask = [.flexibleTopMargin, .flexibleBottomMargin]
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
            guard let self = self, let superview = self.superview else { return }
            let spacing = self.options.contentInset.right
            var rect = subview.frame
            rect.origin = .zero
            rect.size.width = action.frame.width
            subview.frame = rect
            action.center = CGPoint(x: subview.bounds.midX, y: subview.bounds.midY)
            rect = self.frame
            rect.size.width = subview.frame.width
            rect.origin.x = superview.frame.width - spacing - rect.width
            self.frame = rect
        } completion: { [weak self] _ in
            guard let self = self else { return }
            self.isUserInteractionEnabled = true
            action.autoresizingMask = [.flexibleTopMargin, .flexibleBottomMargin]
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
            rect.size.width = ceil(width*scale)
            subview.frame = rect
            x += rect.width
        }
    }
    
    /// 按钮点击事件
    /// - Parameter sender: 按钮
    @objc private func buttonTouchUpInside(_ sender: UIView) {
        guard sender.tag < actions.count else { return }
        delegate?.editingView(self, didTouchActionAt: sender.tag)
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
