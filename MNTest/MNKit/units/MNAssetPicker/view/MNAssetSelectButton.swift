//
//  MNAssetSelectButton.swift
//  MNFoundation
//
//  Created by 冯盼 on 2022/2/2.
//  资源选择器选择按钮

import UIKit

class MNAssetSelectButton: UIControl {
    
    private let imageView = UIImageView()
    
    override var isSelected: Bool {
        get { imageView.isHighlighted }
        set {
            imageView.isHighlighted = newValue
            imageView.backgroundColor = newValue ? .white : .clear
        }
    }

    init(frame: CGRect, options: MNAssetPickerOptions?) {
        super.init(frame: frame)
        
        clipsToBounds = true
        layer.cornerRadius = min(frame.width, frame.height)/2.0
        
        imageView.frame = bounds
        imageView.contentMode = .scaleAspectFit
        imageView.isUserInteractionEnabled = false
        imageView.image = MNAssetPicker.image(named: "selectbox")
        imageView.highlightedImage = MNAssetPicker.image(named: "checkbox_fill")?.renderBy(color: options?.color ?? UIColor(red: 23.0/255.0, green: 79.0/255.0, blue: 218.0/255.0, alpha: 1.0))
        imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(imageView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
