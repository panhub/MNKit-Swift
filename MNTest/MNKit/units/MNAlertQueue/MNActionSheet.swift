//
//  MNAlertField.swift
//  tiescreen
//
//  Created by 冯盼 on 2022/7/8.
//  操作表单

import UIKit
import Foundation

class MNActionSheet: MNAlertQueue {
    /// 按钮高度
    private let actionHeight: CGFloat = 54.0
    /// 分割线高度
    private let separatorHeight: CGFloat = 1.0
    /// 分割线颜色
    private let separatorColor: UIColor = UIColor(red: 244.0/255.0, green: 244.0/255.0, blue: 244.0/255.0, alpha: 1.0)
    
    /// 创建子视图
    override func createViews() {
        if UIDevice.current.userInterfaceIdiom == .phone {
            // iPhone
            contentView.width = height > width ? width : ceil(width/3.0*2.0)
        } else {
            // iPad
            contentView.width = 390.0
        }
        contentView.backgroundColor = .white
        addSubview(contentView)
        
        var y: CGFloat = 0.0
        
        titleLabel.numberOfLines = 0
        titleLabel.textAlignment = .center
        titleLabel.width = contentView.width - 35.0
        titleLabel.midX = contentView.bounds.midX
        if let string = title?.attributedString(font: .systemFont(ofSize: 17.0, weight: .medium), color: .black), string.length > 0 {
            
            // 标题
            titleLabel.minY = 18.0
            titleLabel.attributedText = string
            titleLabel.height = ceil(string.size(width: titleLabel.width).height)
            contentView.addSubview(titleLabel)
            
            y = titleLabel.frame.maxY + titleLabel.frame.minY
        }
        
        textLabel.numberOfLines = 0
        textLabel.textAlignment = .center
        textLabel.width = contentView.width - 35.0
        textLabel.midX = contentView.bounds.midX
        let font: UIFont = titleLabel.height > 0.0 ? .systemFont(ofSize: 15.0, weight: .regular) : .systemFont(ofSize: 16.0, weight: .medium)
        if let string = message?.attributedString(font: font, color: .darkText.withAlphaComponent(0.88)), string.length > 0 {
            
            // 标题
            textLabel.minY = titleLabel.frame.height > 0.0 ? (titleLabel.frame.maxY + 4.0) : 18.0
            textLabel.attributedText = string
            textLabel.height = ceil(string.size(width: textLabel.width).height)
            contentView.addSubview(textLabel)
            
            y = textLabel.frame.maxY + (titleLabel.frame.height > 0.0 ? titleLabel.frame.minY : textLabel.frame.minY)
        }
        
        var cornerRadius: CGFloat = 0.0
        if y > 0.0 {
            
            cornerRadius = 15.0
            
            let separator = UIView()
            separator.minY = y
            separator.height = separatorHeight
            separator.width = contentView.width
            separator.backgroundColor = separatorColor
            contentView.addSubview(separator)
            
            y = separator.frame.maxY
        }
        
        var others: [MNAlertAction] = actions.filter { $0.style == .default }
        others.append(contentsOf: actions.filter { $0.style == .cancel })
        let destructives: [MNAlertAction] = actions.filter { $0.style == .destructive }
        updateActions(others + destructives)
        let groups: [[MNAlertAction]] = [others, destructives]
        
        // 创建按钮
        for (index, group) in groups.enumerated() {
            for (idx, action) in group.enumerated() {
                
                let button: UIButton = UIButton(type: .custom)
                button.minY = y
                button.height = actionHeight
                button.width = contentView.width
                button.setAttributedTitle(action.attributedTitle, for: .normal)
                button.addTarget(self, action: #selector(actionButtonTouchUpInside(_:)), for: .touchUpInside)
                contentView.addSubview(button)
                
                if idx < (group.count - 1) {
                    
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
            
            // 分割线
            if group.count > 0, index < (groups.count - 1) {
                
                let separator = UIView()
                separator.minY = y
                separator.height = 8.0
                separator.width = contentView.width
                separator.backgroundColor = separatorColor
                contentView.addSubview(separator)
                
                y = separator.frame.maxY
            }
        }
        
        // 安全区域
        if MN_TAB_SAFE_HEIGHT > 0.0 {
            
            let separator = UIView()
            separator.minY = y
            separator.height = MN_TAB_SAFE_HEIGHT
            separator.width = contentView.width
            separator.backgroundColor = separatorColor
            contentView.addSubview(separator)
            
            y = separator.frame.maxY
        }
        
        contentView.height = y
        
        // 圆角
        if cornerRadius > 0.0 {
            let path = UIBezierPath(roundedRect: contentView.bounds, byRoundingCorners: [.topLeft, .topRight], cornerRadii: CGSize(width: cornerRadius, height: cornerRadius))
            let mask = CAShapeLayer()
            mask.path = path.cgPath
            contentView.layer.mask = mask
        }
    }
    
    /// 背景点击
    override func backgroundTouchUpInside() {
        dismiss()
    }
    
    /// 展示弹窗
    override func showAnimation() {
        contentView.autoresizingMask = []
        contentView.transform = .identity
        contentView.midX = bounds.midX
        contentView.maxY = bounds.height
        contentView.transform = CGAffineTransform(translationX: 0.0, y: contentView.frame.height)
        UIView.animate(withDuration: 0.25, delay: 0.0, options: [.beginFromCurrentState, .curveEaseInOut]) { [weak self] in
            guard let self = self else { return }
            self.contentView.transform = .identity
            self.backgroundColor = .black.withAlphaComponent(0.4)
        } completion: { [weak self] _ in
            guard let self = self else { return }
            self.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            self.contentView.autoresizingMask = [.flexibleTopMargin, .flexibleLeftMargin, .flexibleRightMargin]
        }
    }
    
    /// 消失动画
    /// - Parameter completion: 动画结束回调
    override func dismissAnimation(completion: @escaping (Bool) -> Void) {
        UIView.animate(withDuration: 0.18, delay: 0.0, options: [.beginFromCurrentState, .curveEaseInOut], animations: { [weak self] in
            guard let self = self else { return }
            self.backgroundColor = .clear
            self.contentView.transform = CGAffineTransform(translationX: 0.0, y: self.contentView.frame.height)
        }, completion: completion)
    }
}


