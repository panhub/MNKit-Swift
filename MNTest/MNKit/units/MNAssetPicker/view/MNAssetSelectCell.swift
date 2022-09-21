//
//  MNAssetSelectCell.swift
//  MNFoundation
//
//  Created by 冯盼 on 2022/2/4.
//  资源选择cell

import UIKit

class MNAssetSelectCell: UICollectionViewCell {
    // 显示截图
    private let imageView: UIImageView = UIImageView()
    // 边框
    let borderView: UIView = UIView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        imageView.frame = bounds
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.isUserInteractionEnabled = false
        imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        contentView.addSubview(imageView)
        
        borderView.frame = contentView.bounds
        borderView.clipsToBounds = true
        borderView.layer.borderWidth = 3.0
        borderView.backgroundColor = .clear
        borderView.isUserInteractionEnabled = false
        borderView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        contentView.addSubview(borderView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func update(asset: MNAsset) {
        imageView.image = asset.thumbnail ?? asset.degradedImage
    }
    
    func update(selected isSelected: Bool) {
        borderView.isHidden = isSelected == false
    }
}
