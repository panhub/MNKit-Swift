//
//  MNAssetSelectControl.swift
//  MNFoundation
//
//  Created by 冯盼 on 2021/10/28.
//  资源选择按钮

import UIKit

class MNAssetSelectControl: UIControl {
    // 选择索引
    var index: Int = 0
    // 配置
    var options: MNAssetPickerOptions!
    // 选中视图
    private lazy var imageView: UIImageView = {
        let imageView = UIImageView(frame: bounds)
        imageView.clipsToBounds = true
        imageView.backgroundColor = .clear
        imageView.contentMode = .scaleAspectFit
        imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        imageView.image = MNAssetPicker.image(named: "checkbox")?.renderBy(color: UIColor(red: 220.0/255.0, green: 220.0/255.0, blue: 220.0/255.0, alpha: 1.0))
        return imageView
    }()
    // 显示索引
    private lazy var textLabel: UILabel = {
        let textLabel = UILabel(frame: bounds)
        textLabel.isHidden = true
        textLabel.clipsToBounds = true
        textLabel.textAlignment = .center
        textLabel.isUserInteractionEnabled = false
        textLabel.font = UIFont.systemFont(ofSize: 12.0)
        textLabel.layer.cornerRadius = textLabel.bounds.height/2.0
        textLabel.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        textLabel.textColor = UIColor(red: 251.0/255.0, green: 251.0/255.0, blue: 251.0/255.0, alpha: 1.0)
        return textLabel
    }()
    // 是否选中
    override var isSelected: Bool {
        get { super.isSelected }
        set {
            super.isSelected = newValue
            if newValue {
                if index == 0 {
                    textLabel.isHidden = true
                    imageView.isHidden = false
                    imageView.isHighlighted = true
                    imageView.backgroundColor = .white
                } else {
                    textLabel.text = "\(index)"
                    textLabel.isHidden = false
                    imageView.isHidden = true
                }
            } else {
                textLabel.isHidden = true
                imageView.isHidden = false
                imageView.isHighlighted = false
                imageView.backgroundColor = UIColor(white: 0.0, alpha: 0.07)
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: CGRect(x: frame.minX, y: frame.minY, width: 20.0, height: 20.0))
        
        clipsToBounds = true
        layer.cornerRadius = min(bounds.width, bounds.height)/2.0
        
        addSubview(imageView)
        addSubview(textLabel)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension MNAssetSelectControl {
    
    func update(options: MNAssetPickerOptions) {
        self.options = options
        textLabel.backgroundColor = options.color
        imageView.highlightedImage = MNAssetPicker.image(named: "checkbox_fill")?.renderBy(color: options.color)
    }
}
