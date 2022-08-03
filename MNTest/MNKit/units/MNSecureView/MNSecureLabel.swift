//
//  MNSecureLabel.swift
//  anhe
//
//  Created by 冯盼 on 2022/5/5.
//

import UIKit

class MNSecureLabel: UIControl {
    // 背景
    private let bgView: UIImageView = UIImageView()
    // 自定义密文密码
    private let textView: UIImageView = UIImageView()
    // 明文密码
    private let label: UILabel = UILabel()
    // 密文密码
    private let blur: UIView = UIView()
    // 边框
    private let borderLayer: CAShapeLayer = CAShapeLayer()
    // 高亮边框
    private let highlightBorderLayer: CAShapeLayer = CAShapeLayer()
    // 绑定的配置
    private var options: MNSecureOptions!
    // 索引
    var index: Int = 0
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        clipsToBounds = true
        
        bgView.frame = bounds
        bgView.isUserInteractionEnabled = false
        bgView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(bgView)
        
        textView.frame = bounds
        textView.isUserInteractionEnabled = false
        textView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(textView)
        
        label.frame = bounds
        label.isUserInteractionEnabled = false
        label.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        label.numberOfLines = 1
        label.textAlignment = .center
        addSubview(label)
        
        blur.frame = CGRect(x: 0.0, y: 0.0, width: 10.0, height: 10.0)
        blur.center = CGPoint(x: bounds.midX, y: bounds.midY)
        blur.backgroundColor = .black
        blur.layer.cornerRadius = blur.frame.height/2.0
        blur.clipsToBounds = true
        blur.isUserInteractionEnabled = false
        blur.autoresizingMask = [.flexibleTopMargin, .flexibleBottomMargin, .flexibleLeftMargin, .flexibleRightMargin]
        addSubview(blur)
        
        layer.addSublayer(borderLayer)
        layer.addSublayer(highlightBorderLayer)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// 绑定配置
    /// - Parameter options: 配置
    func update(options: MNSecureOptions) {
        self.options = options
        label.text = ""
        label.font = options.font
        label.textColor = options.textColor
        label.isHidden = options.isSecureTextEntry
        blur.isHidden = true
        blur.backgroundColor = options.textColor
        bgView.image = options.bgImage
        bgView.contentMode = options.bgImageMode
        textView.isHidden = true
        textView.image = options.textImage
        textView.contentMode = options.textImageMode
        highlightBorderLayer.isHidden = true
        updateBorder(borderLayer, color: options.borderColor ?? .black)
        updateBorder(highlightBorderLayer, color: options.highlightBorderColor ?? .black)
    }
    
    func updateBorder(_ layer: CAShapeLayer, color: UIColor) {
        var path: UIBezierPath!
        switch options.borderStyle {
        case .square:
            path = UIBezierPath(roundedRect: bounds.inset(by: UIEdgeInsets(top: options.borderWidth/2.0, left: options.borderWidth/2.0, bottom: options.borderWidth/2.0, right: options.borderWidth/2.0)), cornerRadius: options.cornerRadius)
        case .shadow:
            path = UIBezierPath()
            path.move(to: CGPoint(x: 0.0, y: frame.height - options.borderWidth/2.0))
            path.addLine(to: CGPoint(x: frame.width, y: frame.height - options.borderWidth/2.0))
        case .grid:
            let rect: CGRect = bounds.inset(by: UIEdgeInsets(top: options.borderWidth/2.0, left: options.borderWidth/2.0, bottom: options.borderWidth/2.0, right: options.borderWidth/2.0))
            path = UIBezierPath(roundedRect: rect, edges: index == 0 ? .all : [.top, .right, .bottom])
        default:
            path = nil
        }
        layer.path = path?.cgPath
        layer.lineWidth = options.borderWidth
        layer.fillColor = UIColor.clear.cgColor
        layer.strokeColor = color.cgColor
        layer.lineCap = .square
    }
    
    /// 更新文字
    /// - Parameter text: 文字
    func update(text: String) {
        if options.isSecureTextEntry {
            if let _ = textView.image {
                textView.isHidden = text.count <= 0
            } else {
                blur.isHidden = text.count <= 0
            }
        } else {
            label.text = text
        }
        highlightBorderLayer.isHidden = text.count <= 0
    }
}
