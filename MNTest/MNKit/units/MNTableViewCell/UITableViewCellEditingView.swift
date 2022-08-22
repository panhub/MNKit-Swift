//
//  UITableViewCellEditingView.swift
//  MNTest
//
//  Created by 冯盼 on 2022/8/22.
//

import UIKit

class UITableViewCellEditingView: UIView {
    
    weak var options: UITableViewEditingOptions!
    
    var action: Selector?
    
    weak var target: NSObjectProtocol?
    
    private var actions: [UIView] = [UIView]()
    
    var sum: CGFloat { actions.reduce(0.0) { $0 + $1.frame.width } }
    
    init(options: UITableViewEditingOptions!) {
        super.init(frame: .zero)
        self.options = options
        self.clipsToBounds = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        if let options = options, let cell = superview as? UITableViewCell {
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
        (subview as? UIControl)?.removeTarget(nil, action: nil, for: .touchUpInside)
        for s in subview.subviews.reversed() {
            s.removeFromSuperview()
        }
        if let backgroundColor = action.backgroundColor {
            subview.backgroundColor = backgroundColor
        }
        let center = subview.center
        var rect = subview.frame
        rect.size.width = min(max(rect.width, action.frame.width), frame.width)
        subview.frame = rect
        subview.center = center
        subview.tag = 0
        action.autoresizingMask = []
        action.center = CGPoint(x: subview.bounds.midX, y: subview.bounds.midY)
        subview.addSubview(action)
        bringSubviewToFront(subview)
        if others.count > 0 {
            isUserInteractionEnabled = false
            action.autoresizingMask = [.flexibleLeftMargin, .flexibleRightMargin, .flexibleTopMargin, .flexibleBottomMargin]
            UIView.animate(withDuration: 0.2, delay: 0.0, options: [.beginFromCurrentState, .layoutSubviews, .curveEaseInOut]) { [weak self] in
                guard let self = self else { return }
                var rect = subview.frame
                rect.origin = .zero
                rect.size.width = self.frame.width
                self.frame = rect
            } completion: { [weak self] _ in
                guard let self = self else { return }
                self.isUserInteractionEnabled = true
                action.autoresizingMask = [.flexibleTopMargin, .flexibleBottomMargin]
                for other in others {
                    other.removeFromSuperview()
                }
            }
        } else {
            action.autoresizingMask = [.flexibleTopMargin, .flexibleBottomMargin]
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
            rect.size.width = min(ceil(width*scale), action.frame.width)
            subview.frame = rect
            x += rect.width
        }
    }
    
    func addTargetForTouchUpInside(_ target: NSObjectProtocol, action: Selector) {
        self.action = action
        self.target = target
    }
    
    @objc private func buttonTouchUpInside(_ sender: UIView) {
        guard sender.tag < actions.count else { return }
        if let target = target, let action = action {
            target.perform(action, with: self, with: actions[sender.tag])
        }
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
