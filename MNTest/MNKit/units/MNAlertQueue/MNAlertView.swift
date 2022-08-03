//
//  AHAlertView.swift
//  anhe
//
//  Created by 冯盼 on 2022/3/10.
//  弹窗

import UIKit
import Foundation

/// 输入框
struct MNAlertField {
    
    /// 配置回调
    private let configurationHandler: ((UITextField)->Void)?
    
    /// 构造弹窗输入框
    /// - Parameter configurationHandler: 配置回调
    init(configurationHandler: ((UITextField)->Void)?) {
        self.configurationHandler = configurationHandler
    }
    
    /// 回调输入框
    /// - Parameter textField: 输入框
    fileprivate func execute(_ textField: UITextField) {
        configurationHandler?(textField)
    }
}

class MNAlertView: MNAlertQueue {
    /// 按钮高度
    private let actionHeight: CGFloat = 47.0
    /// 输入框配置集合
    private var fields: [MNAlertField] = [MNAlertField]()
    /// 输入框集合
    private var alertFields: [UITextField] = [UITextField]()
    /// 分割线高度
    private let separatorHeight: CGFloat = 1.0
    /// 分割线颜色
    private let separatorColor: UIColor = UIColor(red: 235.0/255.0, green: 235.0/255.0, blue: 235.0/255.0, alpha: 1.0)//UIColor(red: 220.0/255.0, green: 220.0/255.0, blue: 220.0/255.0, alpha: 1.0)
    
    /// 创建子视图
    override func createViews() {
        
        contentView.width = 270.0
        contentView.clipsToBounds = true
        contentView.backgroundColor = .white
        contentView.layer.cornerRadius = 15.0
        addSubview(contentView)
        
        let x: CGFloat = 18.0
        
        // 标题
        titleLabel.numberOfLines = 0
        titleLabel.textAlignment = .center
        titleLabel.width = contentView.width - x*2.0
        titleLabel.midX = contentView.bounds.midX
        if let string = title?.attributedString(font: .systemFont(ofSize: 18.0, weight: .medium), color: .black), string.length > 0 {
            
            titleLabel.attributedText = string
            titleLabel.height = ceil(string.size(width: titleLabel.width).height)
            contentView.addSubview(titleLabel)
        }
        
        // 提示信息
        textLabel.numberOfLines = 0
        textLabel.textAlignment = .center
        textLabel.width = contentView.width - x*2.0
        textLabel.midX = contentView.bounds.midX
        let font: UIFont = titleLabel.height > 0.0 ? .systemFont(ofSize: 15.0, weight: .regular) : .systemFont(ofSize: 16.0, weight: .medium)
        if let string = message?.attributedString(font: font, color: .darkText.withAlphaComponent(0.88)), string.length > 0 {
            
            textLabel.attributedText = string
            textLabel.height = ceil(string.size(width: textLabel.width).height)
            contentView.addSubview(textLabel)
        }
        
        // 计算位置
        // 标题与提示信息间隔
        let textSpacing: CGFloat = (titleLabel.height > 0.0 && textLabel.height > 0.0) ? 4.0 : 0.0
        // 输入框与提示信息间隔
        let textFieldSpacing: CGFloat = ((titleLabel.height + textLabel.height) > 0.0 && fields.count > 0) ? 15.0 : 0.0
        // 输入框高度
        let textFieldHeight: CGFloat = 39.0
        // 输入框之间间隔
        let textFieldInterval: CGFloat = 8.0
        // 输入框总体高度
        let textFieldTotalHeight: CGFloat = CGFloat(fields.count)*textFieldHeight + CGFloat(max(fields.count - 1, 0))*textFieldInterval
        // 内容高度
        let contentTotalHeight: CGFloat = titleLabel.height + textSpacing + textLabel.height + textFieldSpacing + textFieldTotalHeight
        // 内容高度 + 上下间隔
        let totalHeight: CGFloat = max(contentTotalHeight + 40.0, 75.0)
        
        titleLabel.minY = (totalHeight - contentTotalHeight)/2.0
        textLabel.minY = titleLabel.maxY + textSpacing
        var y: CGFloat = textLabel.maxY + textFieldSpacing
        
        // 输入框
        for (idx, field) in fields.enumerated() {
            
            let rect = CGRect(x: x, y: y, width: contentView.width - x*2.0, height: textFieldHeight)
            let textField = UITextField(frame: rect)
            textField.keyboardType = .default
            textField.returnKeyType = .done
            textField.font = .systemFont(ofSize: 16.0)
            field.execute(textField)
            
            textField.frame = rect
            textField.borderStyle = .none
            textField.clipsToBounds = true
            textField.layer.cornerRadius = 6.0
            textField.layer.borderWidth = separatorHeight
            textField.layer.borderColor = separatorColor.cgColor
            contentView.addSubview(textField)
            
            alertFields.append(textField)
            
            y = textField.maxY + (idx < (fields.count - 1) ? textFieldInterval : 0.0)
        }
        
        // 分割线
        let separator = UIView()
        separator.minY = totalHeight
        separator.height = separatorHeight
        separator.width = contentView.width
        separator.backgroundColor = separatorColor
        contentView.addSubview(separator)
        
        y = separator.frame.maxY
        
        // 按钮
        if actions.count == 1 {
            
            let button: UIButton = UIButton(type: .custom)
            button.minY = y
            button.width = contentView.width
            button.height = actionHeight
            button.setAttributedTitle(actions.first?.attributedTitle, for: .normal)
            button.addTarget(self, action: #selector(actionButtonTouchUpInside(_:)), for: .touchUpInside)
            contentView.addSubview(button)
            
            y = button.frame.maxY
            
        } else if actions.count == 2 {
            
            let left: UIButton = UIButton(type: .custom)
            left.minY = y
            left.width = contentView.width/2.0
            left.height = actionHeight
            left.setAttributedTitle(actions.first?.attributedTitle, for: .normal)
            left.addTarget(self, action: #selector(actionButtonTouchUpInside(_:)), for: .touchUpInside)
            contentView.addSubview(left)
            
            let right: UIButton = UIButton(type: .custom)
            right.tag = 1
            right.frame = left.frame
            right.minX = left.frame.maxX
            right.setAttributedTitle(actions.last?.attributedTitle, for: .normal)
            right.addTarget(self, action: #selector(actionButtonTouchUpInside(_:)), for: .touchUpInside)
            contentView.addSubview(right)
            
            let separator = UIView()
            separator.minY = left.minY
            separator.height = actionHeight
            separator.width = separatorHeight
            separator.midX = contentView.bounds.midX
            separator.backgroundColor = separatorColor
            contentView.addSubview(separator)
            
            y = left.frame.maxY
            
        } else {
            
            for (idx, action) in actions.enumerated() {
                
                let button: UIButton = UIButton(type: .custom)
                button.tag = idx
                button.minY = y
                button.width = contentView.width
                button.height = actionHeight
                button.setAttributedTitle(action.attributedTitle, for: .normal)
                button.addTarget(self, action: #selector(actionButtonTouchUpInside(_:)), for: .touchUpInside)
                contentView.addSubview(button)
                
                if idx < (actions.count - 1) {
                    
                    let separator = UIView()
                    separator.minY = button.frame.maxY
                    separator.height = separatorHeight
                    separator.width = contentView.width
                    separator.backgroundColor = separatorColor
                    contentView.addSubview(separator)
                    
                    y = separator.frame.maxY
                    
                } else {
                    y = button.frame.maxY
                }
            }
        }
        
        contentView.height = y
        
        // 注册键盘通知
        if fields.count > 0 {
            NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChangeFrame(_:)), name: UIApplication.keyboardWillChangeFrameNotification, object: nil)
        }
    }
    
    /// 背景点击
    override func backgroundTouchUpInside() {
        for alertField in alertFields {
            if alertField.isFirstResponder {
                alertField.resignFirstResponder()
                break
            }
        }
    }
    
    /// 展示弹窗
    override func showAnimation() {
        contentView.alpha = 0.0
        contentView.autoresizingMask = []
        contentView.transform = .identity
        contentView.center = CGPoint(x: bounds.midX, y: bounds.midY)
        contentView.transform = CGAffineTransform(scaleX: 1.05, y: 1.05)
        UIView.animate(withDuration: 0.17, delay: 0.0, options: [.beginFromCurrentState, .curveEaseInOut]) { [weak self] in
            guard let self = self else { return }
            self.contentView.alpha = 1.0
            self.contentView.transform = .identity
            self.backgroundColor = .black.withAlphaComponent(0.4)
        } completion: { [weak self] _ in
            guard let self = self else { return }
            self.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            self.contentView.autoresizingMask = [.flexibleTopMargin, .flexibleBottomMargin, .flexibleLeftMargin, .flexibleRightMargin]
            self.alertFields.first?.becomeFirstResponder()
        }
    }
    
    /// 弹窗消失动画
    /// - Parameter completion: 动画结束回调
    override func dismissAnimation(completion: @escaping (Bool) -> Void) {
        UIView.animate(withDuration: 0.17, delay: 0.0, options: [.beginFromCurrentState, .curveEaseInOut], animations: { [weak self] in
            guard let self = self else { return }
            self.contentView.alpha = 0.0
            self.backgroundColor = .clear
            self.contentView.transform = CGAffineTransform(scaleX: 1.05, y: 1.05)
        }, completion: completion)
    }
}

// MARK: - Components
extension MNAlertView {
    
    /// 输入框集合
    var textFields: [UITextField]? { alertFields.count > 0 ? alertFields : nil }
    
    /// 获取指定输入框
    /// - Parameter index: 指定索引
    /// - Returns: 输入框
    final func textField(index: Int) -> UITextField? {
        guard alertFields.count > 0, index < alertFields.count else { return nil }
        return alertFields[index]
    }
    
    /// 添加输入框
    /// - Parameter alertField: 输入框
    final func addTextField(_ alertField: MNAlertField) {
        fields.append(alertField)
    }
    
    /// 添加输入框
    /// - Parameter configurationHandler: 输入框配置
    final func addTextField(configurationHandler: ((UITextField) -> Void)? = nil) {
        addTextField(MNAlertField(configurationHandler: configurationHandler))
    }
}

// MARK: - Notification
private extension MNAlertView {
    
    /// 键盘位置变化
    /// - Parameter notify: 通知
    @objc func keyboardWillChangeFrame(_ notify: Notification) {
        guard let superview = superview, alertFields.count > 0 else { return }
        guard let userInfo = notify.userInfo else { return }
        guard let rect = userInfo[UIWindow.keyboardFrameEndUserInfoKey] as? CGRect else { return }
        // superview即UIWindow, 避免后期自身位置与UIWindow大小不同, 这里做一次转换
        let frame: CGRect = superview.convert(rect, to: self)
        let midY: CGFloat = min(frame.minY - 10.0 - contentView.frame.height/2.0, bounds.height/2.0)
        guard midY != contentView.frame.midY else { return }
        let duration: TimeInterval = userInfo[UIWindow.keyboardAnimationDurationUserInfoKey] as? TimeInterval ?? 0.25
        let autoresizingMask: UIView.AutoresizingMask = contentView.autoresizingMask
        UIView.animate(withDuration: duration, delay: 0.0, options: [.beginFromCurrentState, .curveEaseInOut]) {
            [weak self] in
            self?.contentView.midY = midY
        } completion: { [weak self] _ in
            self?.contentView.autoresizingMask = autoresizingMask
        }
    }
}

