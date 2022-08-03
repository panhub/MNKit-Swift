//
//  MNAssetIndexLabel.swift
//  anhe
//
//  Created by 冯盼 on 2022/5/27.
//  适配暗盒 资源选择标记视图

import UIKit

class MNAssetIndexLabel: UIView {
    
    private let label: UILabel = UILabel()
    
    private(set) var options: MNAssetPickerOptions!
    
    var text: String? {
        set { label.text = newValue }
        get { label.text }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        isUserInteractionEnabled = false
        
        label.frame = bounds
        label.textColor = .white
        label.numberOfLines = 1
        label.textAlignment = .center
        label.backgroundColor = .clear
        label.isUserInteractionEnabled = false
        label.font = UIFont(name: "Trebuchet MS Bold", size: 30.0)
        label.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(label)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension MNAssetIndexLabel {
    
    func update(options: MNAssetPickerOptions) {
        self.options = options
        backgroundColor = options.color.withAlphaComponent(0.35)
    }
}
