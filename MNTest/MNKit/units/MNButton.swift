//
//  MNButton.swift
//  MNTest
//
//  Created by 冯盼 on 2022/9/13.
//  自定义按钮

import UIKit

class MNButton: UIControl {
    
    // 布局方向
    enum Axis: Int {
        case horizontal, vertical
    }
    
    // 布局方式
    enum Placement: Int {
        case leading, trailing
    }
    
    // 对齐方式
    enum Alignment: Int {
        case center, leading, trailing, top, bottom
    }
    
    // 标题
    let titleLabel: UILabel = UILabel()
    // 图片
    let imageView: UIImageView = UIImageView()
    // 背景图
    private let backgroundView: UIImageView = UIImageView()
    // 图片与标题间隔
    var spacing: CGFloat = 3.0 {
        didSet {
            setNeedsLayout()
        }
    }
    // 对齐方式
    var alignment: MNButton.Alignment = .center {
        didSet {
            setNeedsLayout()
        }
    }
    // 布局方向
    var axis: MNButton.Axis = .horizontal {
        didSet {
            setNeedsLayout()
        }
    }
    // 图片位置
    var imagePlacement: Placement = .leading {
        didSet {
            setNeedsLayout()
        }
    }
    // 背景图片
    var backgroundImage: UIImage? {
        get { backgroundView.image }
        set { backgroundView.image = newValue }
    }
    // 背景缩放方式
    override var contentMode: UIView.ContentMode {
        get { backgroundView.contentMode }
        set { backgroundView.contentMode = newValue }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundView.frame = bounds
        backgroundView.clipsToBounds = true
        backgroundView.contentMode = .scaleToFill
        backgroundView.isUserInteractionEnabled = false
        backgroundView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(backgroundView)
        
        imageView.clipsToBounds = true
        imageView.contentMode = .scaleToFill
        imageView.isUserInteractionEnabled = false
        addSubview(imageView)
        
        titleLabel.isUserInteractionEnabled = false
        titleLabel.font = .systemFont(ofSize: 15.0, weight: .regular)
        titleLabel.textColor = .black
        titleLabel.numberOfLines = 1
        titleLabel.textAlignment = .center
        addSubview(titleLabel)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func sizeToFit() {
        
        titleLabel.sizeToFit()
        titleLabel.width = ceil(titleLabel.width)
        titleLabel.height = ceil(titleLabel.height)
        
        if axis == .horizontal {
            // 横向布局
            height = max(titleLabel.frame.height, imageView.frame.height)
            width = titleLabel.frame.width + imageView.frame.width + spacing
        } else {
            // 纵向布局
            width = max(titleLabel.frame.width, imageView.frame.width)
            height = titleLabel.frame.height + imageView.frame.height + spacing
        }
        
        setNeedsLayout()
        layoutIfNeeded()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        titleLabel.sizeToFit()
        titleLabel.width = ceil(titleLabel.width)
        titleLabel.height = ceil(titleLabel.height)
        
        if axis == .horizontal {
            // 横向布局
            var x: CGFloat = 0.0
            switch alignment {
            case .trailing:
                x = frame.width - titleLabel.frame.width - imageView.frame.width - spacing
            case .center:
                x = (frame.width - titleLabel.frame.width - imageView.frame.width - spacing)/2.0
            default: break
            }
            if imagePlacement == .leading {
                imageView.minX = x
                titleLabel.minX = imageView.maxX + spacing
            } else {
                titleLabel.minX = x
                imageView.minX = titleLabel.maxX + spacing
            }
            titleLabel.midY = frame.height/2.0
            imageView.midY = frame.height/2.0
        } else {
            // 纵向布局
            var y: CGFloat = 0.0
            switch alignment {
            case .bottom:
                y = frame.height - titleLabel.frame.height - imageView.frame.height - spacing
            case .center:
                y = (frame.height - titleLabel.frame.height - imageView.frame.height - spacing)/2.0
            default: break
            }
            if imagePlacement == .leading {
                imageView.minY = y
                titleLabel.minY = imageView.maxY + spacing
            } else {
                titleLabel.minY = y
                imageView.minY = titleLabel.maxY + spacing
            }
            titleLabel.midX = frame.width/2.0
            imageView.midX = frame.width/2.0
        }
    }
}
