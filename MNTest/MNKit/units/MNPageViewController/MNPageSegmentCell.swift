//
//  MNPageSegmentCell.swift
//  anhe
//
//  Created by 冯盼 on 2022/5/29.
//  分页控制器顶部分段视图Cell

import UIKit

class MNPageSegmentCell: UICollectionViewCell {
    
    /// 标题
    private let titleLabel = UILabel()
    /// 角标
    private let badgeLabel = UILabel(frame: CGRect(x: 0.0, y: 0.0, width: 17.0, height: 17.0))
    /// 配置选项
    private var options: MNSegmentViewOptions!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = .clear
        contentView.frame = bounds
        contentView.backgroundColor = .clear
        contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        titleLabel.numberOfLines = 1
        titleLabel.textAlignment = .center
        titleLabel.backgroundColor = .clear
        titleLabel.isUserInteractionEnabled = false
        contentView.addSubview(titleLabel)
        
        badgeLabel.numberOfLines = 1
        badgeLabel.textAlignment = .center
        badgeLabel.clipsToBounds = true
        badgeLabel.isUserInteractionEnabled = false
        badgeLabel.layer.cornerRadius = badgeLabel.height/2.0
        contentView.addSubview(badgeLabel)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        titleLabel.center = CGPoint(x: contentView.frame.width/2.0, y: contentView.frame.height/2.0)
        if let options = options {
            badgeLabel.center = CGPoint(x: contentView.frame.width + options.badgeOffset.horizontal, y: options.badgeOffset.vertical)
        }
    }
    
    /// 设置分段配置
    /// - Parameter options: 配置
    func setOptions(_ options: MNSegmentViewOptions) {
        self.options = options
        titleLabel.font = options.titleFont
        badgeLabel.font = options.badgeFont
        badgeLabel.backgroundColor = options.backgroundColor
    }
    
    /// 更新标题/角标
    /// - Parameter segment: 配置模型
    func update(segment: MNPageSegment) {
        if let text = segment.badge?.stringValue {
            if text.intValue > 999 {
                badgeLabel.text = "999+"
            }
            let height = badgeLabel.height
            badgeLabel.text = text
            badgeLabel.sizeToFit()
            badgeLabel.height = height
            badgeLabel.width = max(ceil(badgeLabel.width) + 8.0, height)
            badgeLabel.isHidden = false
        } else {
            badgeLabel.isHidden = true
        }
        titleLabel.transform = .identity
        titleLabel.text = segment.title
        if let options = options {
            titleLabel.textColor = segment.isSelected ? options.titleHighlightColor : options.titleColor
        }
        titleLabel.sizeToFit()
        titleLabel.transform = CGAffineTransform(scaleX: segment.scale, y: segment.scale)
        setNeedsLayout()
    }
}
