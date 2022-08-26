//
//  CollectionViewCell.swift
//  MNTest
//
//  Created by 冯盼 on 2022/8/26.
//

import UIKit

class CollectionViewCell: UICollectionViewCell {
    
    var bg: UIView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        contentView.backgroundColor = .white
        
        let view = UIView(frame: contentView.bounds.inset(by: UIEdgeInsets(top: 10.0, left: 20.0, bottom: 10.0, right: 20.0)))
        view.layer.cornerRadius = 8.0
        view.clipsToBounds = true
        view.backgroundColor = .gray.withAlphaComponent(0.2)
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        contentView.addSubview(view)
        
        bg = view
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        layoutEditingView()
    }
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        guard let _ = superview else { return }
        allowsEditing = true
    }
}
