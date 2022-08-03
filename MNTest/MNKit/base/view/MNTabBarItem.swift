//
//  MNTabBarItem.swift
//  MNFoundation
//
//  Created by 冯盼 on 2021/8/11.
//  标签控制器按钮

import UIKit

public class MNTabBarItem: UIControl {
    /**角标样式*/
    public enum BadgeStyle {
        // 文字
        case normal
        // 圆点
        case mark
        // 文字边距
        fileprivate static let WordMargin: CGFloat = 3.0
        // 默认圆点大小
        fileprivate static let MarkSize = CGSize(width: 3.0, height: 3.0)
    }

    /**标题*/
    public var title: String = "" {
        didSet {
            if isSelected == false {
                titleLabel.text = title
                setNeedsLayout()
            }
        }
    }
    /**选择状态标题*/
    public var selectedTitle: String = "" {
        didSet {
            if isSelected {
                titleLabel.text = selectedTitle
                setNeedsLayout()
            }
        }
    }
    /**标题颜色*/
    public var titleColor: UIColor = .black {
        didSet {
            if isSelected == false {
                titleLabel.textColor = titleColor
            }
        }
    }
    /**选择状态标题颜色*/
    public var selectedTitleColor: UIColor = .gray {
        didSet {
            if isSelected {
                titleLabel.textColor = selectedTitleColor
            }
        }
    }
    /**标题位置*/
    public var titleEdgeInset: UIEdgeInsets = .zero {
        didSet {
            setNeedsLayout()
        }
    }
    /**标题偏移*/
    public var titleOffset: UIOffset = .zero {
        didSet {
            setNeedsLayout()
        }
    }
    /**标题字体*/
    public var titleFont: UIFont = UIFont.systemFont(ofSize: 13.0) {
        didSet {
            titleLabel.font = titleFont
            setNeedsLayout()
        }
    }
    /**图片*/
    public var image: UIImage? {
        didSet {
            imageView.image = image
        }
    }
    /**选择状态图片*/
    public var selectedImage: UIImage? {
        didSet {
            imageView.highlightedImage = selectedImage
        }
    }
    /**图片位置*/
    public var imageEdgeInset: UIEdgeInsets = .zero {
        didSet {
            setNeedsLayout()
        }
    }
    /**图片偏移*/
    public var imageOffset: UIOffset = .zero {
        didSet {
            setNeedsLayout()
        }
    }
    /**标题与图片间隔*/
    public var titleImageInterval: CGFloat = 3.0 {
        didSet {
            setNeedsLayout()
        }
    }
    /**角标字体*/
    public var badgeFont: UIFont = UIFont.systemFont(ofSize: 10.0) {
        didSet {
            badgeLabel.font = badgeFont
            setNeedsLayout()
        }
    }
    /**角标背景色*/
    public var badgeColor: UIColor = UIColor.red {
        didSet {
            badgeLabel.backgroundColor = badgeColor
        }
    }
    /**角标文字颜色*/
    public var badgeTextColor: UIColor = UIColor.white {
        didSet {
            badgeLabel.textColor = badgeTextColor
        }
    }
    /**角标位置*/
    public var badgeEdgeInset: UIEdgeInsets = .zero {
        didSet {
             layoutBadge()
        }
    }
    /**角标偏移*/
    public var badgeOffset: UIOffset = .zero {
        didSet {
            layoutBadge()
        }
    }
    /**角标样式*/
    public var badgeStyle: BadgeStyle = .normal {
        didSet {
            if badgeStyle == .mark {
                badgeLabel.text = ""
            }
            layoutBadge()
        }
    }
    /**角标数值*/
    public var badge: MNBadgeConvertible? {
        didSet {
            updateBadge()
        }
    }
    /**修改状态*/
    public override var isSelected: Bool {
        get { super.isSelected }
        set {
            guard super.isSelected != newValue else { return }
            super.isSelected = newValue
            if newValue {
                titleLabel.text = selectedTitle
                titleLabel.textColor = selectedTitleColor
                imageView.isHighlighted = true
            } else {
                titleLabel.text = title
                titleLabel.textColor = titleColor
                imageView.isHighlighted = false
            }
            setNeedsLayout()
        }
    }
    private lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = image
        imageView.highlightedImage = selectedImage
        imageView.contentMode = .scaleAspectFit
        imageView.contentScaleFactor = UIScreen.main.scale
        imageView.isUserInteractionEnabled = false
        return imageView
    }()
    private lazy var titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = titleFont
        titleLabel.textColor = titleColor
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 1
        titleLabel.isUserInteractionEnabled = false
        return titleLabel
    }()
    private lazy var badgeLabel: UILabel = {
        let badgeLabel = UILabel()
        badgeLabel.font = badgeFont
        badgeLabel.textColor = badgeTextColor
        badgeLabel.backgroundColor = badgeColor
        badgeLabel.textAlignment = .center
        badgeLabel.isHidden = true
        badgeLabel.clipsToBounds = true
        badgeLabel.numberOfLines = 1
        badgeLabel.isUserInteractionEnabled = false
        return badgeLabel
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        addSubview(imageView)
        addSubview(titleLabel)
        addSubview(badgeLabel)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /**对子控件布局*/
    public override func layoutSubviews() {
        super.layoutSubviews()
        
        // 文字位置自适应
        var titleRect: CGRect = .zero
        if titleEdgeInset != .zero {
            titleRect = bounds.inset(by: titleEdgeInset)
        } else {
            titleLabel.sizeToFit()
            titleRect.size = CGSize(width: ceil(titleLabel.bounds.width), height: ceil(titleLabel.bounds.height))
            titleRect.origin.x = (bounds.width - titleRect.width)/2.0
            titleRect.origin.y = bounds.height - titleRect.height
        }
        titleRect.origin.x += titleOffset.horizontal
        titleRect.origin.y += titleOffset.vertical
        
        // 图片位置
        var imageRect: CGRect = .zero
        if imageEdgeInset != .zero {
            imageRect = bounds.inset(by: imageEdgeInset)
        }
        if imageRect == .zero {
            let wh: CGFloat = min(bounds.width, titleRect.minY - titleImageInterval)
            imageRect.size = CGSize(width: wh, height: wh)
            imageRect.origin.x = (bounds.width - wh)/2.0
            imageRect.origin.y = titleRect.minY - titleImageInterval - wh
        }
        imageRect.origin.x += imageOffset.horizontal
        imageRect.origin.y += imageOffset.vertical
        
        titleLabel.frame = titleRect
        imageView.frame = imageRect
    }
    
    /**约束角标*/
    public func layoutBadge() -> Void {
        // 角标位置
        var badgeRect: CGRect = .zero
        if badgeEdgeInset != .zero {
            badgeRect = bounds.inset(by: badgeEdgeInset)
        } else {
            if badgeStyle == .normal {
                let wh = badgeFont.pointSize + BadgeStyle.WordMargin*2.0
                badgeRect.size = CGSize(width: wh, height: wh)
            } else {
                badgeRect.size = BadgeStyle.MarkSize
                badgeLabel.layer.cornerRadius = min(BadgeStyle.MarkSize.width, BadgeStyle.MarkSize.height)/2.0
            }
            badgeRect.origin.x = bounds.width - badgeRect.width
        }
        badgeRect.origin.x += badgeOffset.horizontal
        badgeRect.origin.y += badgeOffset.vertical
        badgeLabel.frame = badgeRect
    }
    
    /**更新角标*/
    public func updateBadge() -> Void {
        let badgeValue = badge?.stringValue
        guard let value = badgeValue, value != "0" else {
            badgeLabel.isHidden = true
            return
        }
        badgeLabel.isHidden = false
        if badgeStyle == .normal {
            let center = badgeLabel.center
            badgeLabel.text = value
            badgeLabel.sizeToFit()
            var badgeSize: CGSize = .zero
            badgeSize.height = ceil(badgeLabel.size.height) + BadgeStyle.WordMargin*2.0
            if badgeLabel.size.width > badgeSize.height/2.0 {
                badgeSize.width = ceil(badgeLabel.size.width) + badgeSize.height/2.0
            } else {
                badgeSize.width = badgeSize.height
            }
            badgeLabel.layer.cornerRadius = badgeSize.width/2.0
            badgeLabel.size = badgeSize
            badgeLabel.center = center
        }
    }
}
