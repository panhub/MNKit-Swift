//
//  AHTranslateItem.swift
//  anhe
//
//  Created by 冯盼 on 2022/2/16.
//  翻译语言选择按钮

import UIKit

class TLLanguageView: UIControl {
    
    var mode: TLLanguage.Mode = .from
    
    private lazy var textLabel: UILabel = {
        let textLabel = UILabel()
        textLabel.numberOfLines = 1
        textLabel.textAlignment = .center
        textLabel.isUserInteractionEnabled = false
        textLabel.font = .systemFont(ofSize: 16.0, weight: .medium)
        textLabel.textColor = .black
        return textLabel
    }()
    
    private lazy var imageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "home-down"))
        imageView.isUserInteractionEnabled = false
        imageView.width = 10.0
        imageView.sizeFitToWidth()
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    var language: TLLanguage! {
        didSet {
            let max = maxX
            textLabel.text = language.name
            textLabel.sizeToFit()
            textLabel.width = ceil(textLabel.width)
            textLabel.height = ceil(textLabel.height)
            textLabel.midY = height/2.0
            imageView.midY = textLabel.midY
            imageView.minX = textLabel.maxX + 8.0
            width = imageView.maxX
            if mode == .from {
                maxX = max
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(textLabel)
        addSubview(imageView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
