//
//  MNSwitch.swift
//  MNTest
//
//  Created by 冯盼 on 2022/8/28.
//  开关

import UIKit

@objc protocol MNSwitchDelegate: NSObjectProtocol {
    @objc optional func switchShouldChangeValue(_ switch: MNSwitch) -> Bool
    @objc optional func switchValueChanged(_ switch: MNSwitch) -> Void
}

class MNSwitch: UIView {
    /// 内部使用
    private let spacing: CGFloat = 2.0
    /// 默认颜色
    private let color: UIColor = UIColor(red: 230.0/255.0, green: 230.0/255.0, blue: 230.0/255.0, alpha: 1.0)
    /// 滑块
    private let thumb = UIView()
    /// 标记动画期间 拒绝交互
    private var isAnimating: Bool = false
    /// 事件代理
    weak var delegate: MNSwitchDelegate?
    /// 打开时的颜色
    @objc var onTintColor: UIColor = UIColor(red: 0.0/255.0, green: 122.0/255.0, blue: 254.0/255.0, alpha: 1.0) {
        didSet {
            updateColor()
        }
    }
    /// 滑块颜色
    @objc var thumbTintColor: UIColor? {
        get { thumb.backgroundColor }
        set { thumb.backgroundColor = newValue ?? .white }
    }
    /// 正常状态下颜色
    override var tintColor: UIColor! {
        didSet {
            updateColor()
        }
    }
    /// 拒绝设置背景颜色
    override var backgroundColor: UIColor? {
        set {}
        get { super.backgroundColor }
    }
    /// 是否处于开启状态
    @objc var isOn: Bool {
        get { thumb.center.x > bounds.midX }
        set {
            setOn(newValue, animated: false)
        }
    }
    /// 拒绝直接修改尺寸
    override var frame: CGRect {
        get { super.frame }
        set {
            var rect: CGRect = newValue
            let frame: CGRect = super.frame
            if frame.size != .zero {
                rect.size = frame.size
            }
            super.frame = newValue
        }
    }
    
    /// 构造Switch
    /// - Parameter frame: 位置
    override init(frame: CGRect) {
        var rect: CGRect = frame
        if max(frame.width, frame.height) <= 0.0 {
            rect.size = CGSize(width: 45.0, height: 26.0)
        }
        rect.size.height = max(rect.height, spacing*2.0 + 15.0)
        rect.size.width = max(rect.width, rect.height + 15.0)
        super.init(frame: rect)
        
        clipsToBounds = true
        layer.cornerRadius = rect.height/2.0
        super.tintColor = color
        super.backgroundColor = color
        
        thumb.frame = CGRect(x: spacing, y: spacing, width: rect.height - spacing*2.0, height: rect.height - spacing*2.0)
        thumb.clipsToBounds = true
        thumb.layer.cornerRadius = thumb.frame.height/2.0
        thumb.backgroundColor = .white
        thumb.isUserInteractionEnabled = false
        addSubview(thumb)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        setOn(isOn == false, animated: true, interactive: true)
    }
    
    /// 修改Switch的状态
    /// - Parameters:
    ///   - on: 是否开启
    ///   - isAnimated: 是否动画
    ///   - isInteractive: 是否是由交互触发
    @objc func setOn(_ on: Bool, animated isAnimated: Bool, interactive isInteractive: Bool = false) {
        guard isAnimating == false, isOn != on else { return }
        var isAllowChangeValue: Bool = true
        if isInteractive, (delegate?.switchShouldChangeValue?(self) ?? true) == false {
            isAllowChangeValue = false
        }
        guard isAllowChangeValue else { return }
        if isAnimated {
            isAnimating = true
            UIView.animate(withDuration: 0.17, delay: 0.0, options: [.beginFromCurrentState, .curveEaseOut]) { [weak self] in
                guard let self = self else { return }
                self.update(on: on)
            } completion: { [weak self] _ in
                guard let self = self else { return }
                self.isAnimating = false
                guard isInteractive else { return }
                self.delegate?.switchValueChanged?(self)
            }
        } else {
            update(on: on)
        }
    }
    
    /// 更新UI
    /// - Parameter isOn: 是否开启状态
    private func update(on isOn: Bool) {
        var rect: CGRect = thumb.frame
        rect.origin.x = isOn ? (frame.width - rect.width - spacing) : spacing
        thumb.frame = rect
        updateColor()
    }
    
    /// 更新背景颜色
    private func updateColor() {
        super.backgroundColor = isOn ? onTintColor : (tintColor ?? color)
    }
}
