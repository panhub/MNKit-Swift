//
//  MNEmptyView.swift
//  MNFoundation
//
//  Created by 冯盼 on 2021/7/18.
//  空数据占位图

import UIKit

@objc protocol MNEmptyViewDelegate: NSObjectProtocol {
    @objc optional func emptyViewButtonTouchUpInside(_ emptyView: MNEmptyView) -> Void
}

@objc class MNEmptyView: UIView {
    
    /// 事件类型
    @objc enum Event: Int {
        case load, reload, custom
    }
    
    /// 纵向排列方式
    @objc enum Alignment: Int {
        case top, center, bottom
    }
    
    // 事件类型
    @objc var event: MNEmptyView.Event = .reload
    // 交互代理
    @objc weak var delegate: MNEmptyViewDelegate?
    // 图片
    @objc var image: UIImage?
    // 图片显示大小
    @objc var imageSize: CGSize = .zero
    // 控件纵向间隔
    @objc var spacing: CGFloat = 25.0
    // 按钮标题
    var title: MNAttributedStringConvertible?
    // 文字提示
    var text: MNAttributedStringConvertible?
    // 按钮背景颜色
    @objc var buttonBackgroundColor: UIColor = .blue
    // 纵向排列方式
    @objc var alignment: MNEmptyView.Alignment = .center
    // 内容偏移
    @objc var contentOffset: UIOffset = .zero
    // 内容视图
    private var contentView: UIView = UIView()
    // 图片显示
    private var imageView: UIImageView = UIImageView()
    // 文字显示
    private var textLabel: UILabel = UILabel()
    // 按钮
    private var button: UIButton = UIButton(type: .custom)
    // 标题颜色
    @objc var titleColor: UIColor {
        set { button.setTitleColor(newValue, for: .normal) }
        get { button.titleColor(for: .normal) ?? .black }
    }
    // 标题字体
    @objc var titleFont: UIFont {
        set { button.titleLabel?.font = newValue }
        get { button.titleLabel?.font ?? .systemFont(ofSize: 15.0, weight: .medium) }
    }
    // 提示信息颜色
    @objc var textColor: UIColor {
        set { textLabel.textColor = newValue }
        get { textLabel.textColor ?? .darkGray.withAlphaComponent(0.88) }
    }
    // 提示信息字体
    @objc var textFont: UIFont {
        set { textLabel.font = newValue }
        get { textLabel.font ?? .systemFont(ofSize: 17.0) }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        clipsToBounds = true
        backgroundColor = UIColor.clear
        
        contentView = UIView(frame: bounds)
        contentView.backgroundColor = .clear
        addSubview(contentView)
        
        imageView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFit
        contentView.addSubview(imageView)
        
        textLabel.textColor = .darkGray
        textLabel.numberOfLines = 0
        textLabel.clipsToBounds = true
        textLabel.textAlignment = .center
        contentView.addSubview(textLabel)
        
        button.layer.cornerRadius = 5.0
        button.clipsToBounds = true
        button.setTitleColor(.white, for: .normal)
        button.contentVerticalAlignment = .center
        button.contentHorizontalAlignment = .center
        button.addTarget(self, action: #selector(buttonTouchUpInside(_:)), for: .touchUpInside)
        contentView.addSubview(button)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        guard isHidden == false, frame.width > 0.0, frame.height > 0.0 else { return }
        
        // 更新视图
        imageView.image = image
        if let image = imageView.image {
            if imageSize.width > 0.0, imageSize.height > 0.0 {
                imageView.size = imageSize
            } else {
                imageView.width = floor(min(frame.width, frame.height)/5.0*4.0)
                imageView.height = ceil(image.size.height/image.size.width*imageView.frame.width)
            }
        } else {
            imageView.size = .zero
        }
        
        if let attributedText = text?.attributedString(font: textFont, color: textColor), attributedText.length > 0 {
            textLabel.attributedText = attributedText
            textLabel.size = attributedText.boundingRect(with: CGSize(width: frame.width - 40.0, height: .greatestFiniteMagnitude), options: [.usesFontLeading, .usesLineFragmentOrigin], context: nil).size
            textLabel.width = ceil(textLabel.width)
            textLabel.height = ceil(textLabel.height)
            textLabel.minY = imageView.frame.maxY + (imageView.frame.maxY > 0.0 ? spacing : 0.0)
        } else {
            textLabel.size = .zero
            textLabel.minY = imageView.maxY
        }
        
        if let attributedTitle = title?.attributedString(font: titleFont, color: titleColor), attributedTitle.length > 0 {
            button.backgroundColor = buttonBackgroundColor
            button.setAttributedTitle(attributedTitle, for: .normal)
            button.sizeToFit()
            button.height = 40.0
            button.width = ceil(button.width + 30.0)
            button.minY = textLabel.frame.maxY + (textLabel.frame.maxY > 0.0 ? spacing : 0.0)
        } else {
            button.size = .zero
            button.minY = textLabel.maxY
        }
        
        contentView.height = button.maxY
        contentView.width = max(max(textLabel.width, imageView.width), button.width)
        
        button.midX = contentView.width/2.0
        textLabel.midX = contentView.width/2.0
        imageView.midX = contentView.width/2.0
        
        switch alignment {
        case .top:
            contentView.minY = 0.0
        case .center:
            contentView.midY = frame.height/2.0
        case .bottom:
            contentView.maxY = frame.height
        }
        
        contentView.midY += contentOffset.vertical
        contentView.midX = frame.width/2.0 + contentOffset.horizontal
    }
    
    @objc private func buttonTouchUpInside(_ sender: UIButton) -> Void {
        delegate?.emptyViewButtonTouchUpInside?(self)
    }
}
