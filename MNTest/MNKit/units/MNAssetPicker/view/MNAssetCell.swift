//
//  MNAssetCell.swift
//  MNFoundation
//
//  Created by 冯盼 on 2021/10/28.
//  资源列表

import UIKit

protocol MNAssetCellDelegate: NSObjectProtocol {
    
    /// 预览资源回调
    /// - Parameter cell: 资源表格
    func assetCellShouldPreviewAsset(_ cell: MNAssetCell) -> Void
}

class MNAssetCell: UICollectionViewCell {
    // 控件间隔
    private let spacing: CGFloat = 6.0
    // 媒体资源模型
    private(set) var asset: MNAsset!
    // 事件代理
    weak var delegate: MNAssetCellDelegate?
    // 配置信息
    var options: MNAssetPickerOptions! {
        didSet {
            indexLabel.backgroundColor = options?.color.withAlphaComponent(0.38)
        }
    }
    // 顶部阴影
    private lazy var topShadow: UIImageView = {
        let topShadow = UIImageView(frame: CGRect(x: 0.0, y: 0.0, width: contentView.bounds.width, height: 30.0))
        topShadow.image = MNAssetPicker.image(named: "top_shadow")
        topShadow.contentMode = .scaleToFill
        topShadow.backgroundColor = .clear
        topShadow.isUserInteractionEnabled = false
        topShadow.autoresizingMask = [.flexibleWidth, .flexibleBottomMargin]
        return topShadow
    }()
    // 底部阴影
    private lazy var bottomShadow: UIImageView = {
        let bottomShadow = UIImageView(frame: topShadow.frame)
        bottomShadow.maxY = contentView.bounds.height
        bottomShadow.image = MNAssetPicker.image(named: "bottom_shadow")
        bottomShadow.contentMode = .scaleToFill
        bottomShadow.backgroundColor = .clear
        bottomShadow.isUserInteractionEnabled = false
        bottomShadow.autoresizingMask = [.flexibleWidth, .flexibleTopMargin]
        return bottomShadow
    }()
    // 资源展示
    private lazy var imageView: UIImageView = {
        let imageView = UIImageView(frame: contentView.bounds)
        imageView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFill
        imageView.isUserInteractionEnabled = false
        imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        return imageView
    }()
    // 云端标识
    private lazy var cloudView: UIImageView = {
        let cloudView = UIImageView(frame: CGRect(x: spacing, y: spacing, width: 17.0, height: 17.0))
        cloudView.isUserInteractionEnabled = false
        cloudView.image = MNAssetPicker.image(named: "cloud")?.renderBy(color: .white.withAlphaComponent(0.85))
        cloudView.autoresizingMask = [.flexibleRightMargin, .flexibleBottomMargin]
        return cloudView
    }()
    // 预览按钮
    private lazy var checkButton: UIControl = {
        let checkButton = UIControl(frame: CGRect(x: 0.0, y: 0.0, width: 25.0, height: 25.0))
        checkButton.maxX = contentView.bounds.width
        checkButton.autoresizingMask = [.flexibleLeftMargin, .flexibleBottomMargin]
        checkButton.addTarget(self, action: #selector(preview), for: .touchUpInside)
        let imageView = UIImageView(image: MNAssetPicker.image(named: "preview")?.renderBy(color: .white.withAlphaComponent(0.85)))
        imageView.size = CGSize(width: ceil(180.0/121.0*13.0), height: 13.0)
        imageView.midY = cloudView.midY
        imageView.maxX = checkButton.bounds.width - spacing
        checkButton.addSubview(imageView)
        return checkButton
    }()
    // 资源类型
    private lazy var badgeView: MNStateView = {
        let badgeView = MNStateView(frame: cloudView.frame)
        badgeView.maxY = contentView.bounds.height - spacing
        badgeView.setImage(MNAssetPicker.image(named: "video")?.renderBy(color: UIColor(red: 251.0/255.0, green: 251.0/255.0, blue: 251.0/255.0, alpha: 1.0)), for: .normal)
        badgeView.setImage(MNAssetPicker.image(named: "livephoto")?.renderBy(color: UIColor(red: 251.0/255.0, green: 251.0/255.0, blue: 251.0/255.0, alpha: 1.0)), for: .highlighted)
        badgeView.setImage(MNAssetPicker.image(named: "gif")?.renderBy(color: UIColor(red: 251.0/255.0, green: 251.0/255.0, blue: 251.0/255.0, alpha: 1.0)), for: .selected)
        badgeView.autoresizingMask = [.flexibleRightMargin, .flexibleTopMargin]
        return badgeView
    }()
    // 视频时长
    private lazy var durationLabel: UILabel = {
        let durationLabel = UILabel()
        durationLabel.minX = badgeView.maxX + 5.0
        durationLabel.numberOfLines = 1
        durationLabel.textAlignment = .right
        durationLabel.isUserInteractionEnabled = false
        durationLabel.font = UIFont.systemFont(ofSize: 12.0)
        durationLabel.textColor = UIColor(red: 251.0/255.0, green: 251.0/255.0, blue: 251.0/255.0, alpha: 1.0)
        return durationLabel
    }()
    // 文件大小
    private lazy var fileSizeLabel: UILabel = {
        let fileSizeLabel = UILabel()
        fileSizeLabel.maxX = contentView.bounds.width - spacing
        fileSizeLabel.midY = badgeView.midY
        fileSizeLabel.numberOfLines = 1
        fileSizeLabel.textAlignment = .right
        fileSizeLabel.isUserInteractionEnabled = false
        fileSizeLabel.font = UIFont.systemFont(ofSize: 12.0)
        fileSizeLabel.textColor = UIColor(red: 251.0/255.0, green: 251.0/255.0, blue: 251.0/255.0, alpha: 1.0)
        return fileSizeLabel
    }()
    // 选择索引
    private lazy var indexLabel: UILabel = {
        let indexLabel = UILabel(frame: contentView.bounds)
        indexLabel.textColor = .white
        indexLabel.numberOfLines = 1
        indexLabel.textAlignment = .center
        indexLabel.backgroundColor = .clear
        indexLabel.isUserInteractionEnabled = false
        indexLabel.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        indexLabel.font = UIFont(name: "Trebuchet MS Bold", size: 30.0)
        return indexLabel
    }()
    // 资源无效
    private lazy var disableView: UIView = {
        let holdView = UIView(frame: contentView.bounds)
        holdView.isHidden = true
        holdView.isUserInteractionEnabled = false
        holdView.backgroundColor = .white.withAlphaComponent(0.8)
        holdView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        return holdView
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        contentView.frame = bounds
        contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        contentView.backgroundColor = .white
        
        contentView.addSubview(imageView)
        contentView.addSubview(topShadow)
        contentView.addSubview(bottomShadow)
        contentView.addSubview(cloudView)
        contentView.addSubview(checkButton)
        contentView.addSubview(badgeView)
        contentView.addSubview(durationLabel)
        contentView.addSubview(fileSizeLabel)
        contentView.addSubview(indexLabel)
        contentView.addSubview(disableView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func update(asset: MNAsset) {
        self.asset = asset
        asset.container = imageView
        
        imageView.image = asset.thumbnail
        
        topShadow.isHidden = false
        bottomShadow.isHidden = false
        fileSizeLabel.isHidden = true
        durationLabel.isHidden = true
        cloudView.isHidden = asset.source != .cloud
        checkButton.isHidden = options.isAllowsPreview == false
        
        if options.isShowFileSize, asset.fileSize > 0 {
            updateFileSize()
        }
        
        switch asset.type {
        case .video:
            badgeView.state = .normal
            badgeView.isHidden = false
            if options.isShowFileSize == false || asset.fileSize <= 0 {
                durationLabel.text = asset.durationValue
                durationLabel.sizeToFit()
                durationLabel.midY = badgeView.midY
                durationLabel.isHidden = false
            }
        case .livePhoto:
            badgeView.state = .highlighted
            badgeView.isHidden = false
        case .gif:
            badgeView.state = .selected
            badgeView.isHidden = false
        default:
            badgeView.isHidden = true
        }
        
        if asset.isEnabled {
            disableView.isHidden = true
        } else {
            disableView.isHidden = false
            indexLabel.isHidden = true
            cloudView.isHidden = true
            badgeView.isHidden = true
            topShadow.isHidden = true
            checkButton.isHidden = true
            fileSizeLabel.isHidden = true
            durationLabel.isHidden = true
            bottomShadow.isHidden = true
        }
        
        if asset.isSelected {
            indexLabel.text = "\(asset.index)"
            indexLabel.isHidden = false
            disableView.isHidden = true
            cloudView.isHidden = true
            badgeView.isHidden = true
            topShadow.isHidden = true
            checkButton.isHidden = true
            fileSizeLabel.isHidden = true
            durationLabel.isHidden = true
            bottomShadow.isHidden = true
        } else {
            indexLabel.isHidden = true
        }
        
        asset.thumbnailUpdateHandler = nil
        asset.thumbnailUpdateHandler = { [weak self] m in
            guard let self = self, let _ = self.asset, m == self.asset else { return }
            self.imageView.image = m.thumbnail
        }
        
        asset.sourceUpdateHandler = nil
        asset.sourceUpdateHandler = { [weak self] m in
            guard let self = self, let _ = self.asset, m == self.asset else { return }
            self.cloudView.isHidden = m.source != .cloud
        }
        
        asset.fileSizeUpdateHandler = nil
        asset.fileSizeUpdateHandler = { [weak self] m in
            guard let self = self, self.options.isShowFileSize, let _ = self.asset, m == self.asset, m.fileSize > 0 else { return }
            self.updateFileSize()
        }
        
        MNAssetHelper.profile(asset: asset, options: options)
    }
    
    func updateFileSize() {
        fileSizeLabel.text = asset.fileSizeValue
        fileSizeLabel.sizeToFit()
        fileSizeLabel.maxX = contentView.bounds.width - spacing
        fileSizeLabel.midY = badgeView.midY
        fileSizeLabel.isHidden = false
        durationLabel.isHidden = true
    }
    
    func endDisplaying() {
        asset?.container = nil
        asset?.sourceUpdateHandler = nil
        asset?.fileSizeUpdateHandler = nil
        asset?.thumbnailUpdateHandler = nil
        asset?.cancelRequest()
    }
}

// MARK: - Event
private extension MNAssetCell {
    
    @objc func preview() {
        delegate?.assetCellShouldPreviewAsset(self)
    }
}
