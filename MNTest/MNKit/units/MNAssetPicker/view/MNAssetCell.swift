//
//  MNAssetCell.swift
//  MNFoundation
//
//  Created by 冯盼 on 2021/10/28.
//  资源列表

import UIKit

// 资源选择回调
protocol MNAssetSelectDelegate: NSObjectProtocol {
    func update(asset: MNAsset) -> Void
}

class MNAssetCell: UICollectionViewCell {
    // 间隔
    private let margin: CGFloat = 6.0
    // 媒体资源模型
    var asset: MNAsset!
    // 事件代理
    weak var delegate: MNAssetSelectDelegate?
    // 配置信息
    var options: MNAssetPickerOptions {
        get { indexLabel.options }
        set { indexLabel.update(options: newValue) }
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
    // 选择索引展示
    private lazy var indexLabel: MNAssetIndexLabel = {
        let indexLabel = MNAssetIndexLabel(frame: contentView.bounds)
        indexLabel.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        return indexLabel
    }()
    // 云端标识
    private lazy var cloudView: MNStateView = {
        let cloudView = MNStateView(frame: CGRect(x: margin, y: margin, width: 17.0, height: 17.0))
        cloudView.setImage(MNAssetPicker.image(named: "cloud")?.renderBy(color: .white.withAlphaComponent(0.78)), for: .normal)
        cloudView.setImage(MNAssetPicker.image(named: "cloud_download")?.renderBy(color: .white.withAlphaComponent(0.78)), for: .highlighted)
        cloudView.autoresizingMask = [.flexibleRightMargin, .flexibleBottomMargin]
        return cloudView
    }()
//    // 选择按钮
//    private lazy var selectControl: MNAssetSelectControl = {
//        let selectControl = MNAssetSelectControl()
//        selectControl.minY = cloudView.minY
//        selectControl.maxX = contentView.bounds.width - margin
//        selectControl.addTarget(self, action: #selector(select(sender:)), for: .touchUpInside)
//        selectControl.autoresizingMask = [.flexibleLeftMargin, .flexibleBottomMargin]
//        return selectControl
//    }()
    // 资源类型
    private lazy var badgeView: MNStateView = {
        let badgeView = MNStateView(frame: cloudView.frame)
        badgeView.maxY = contentView.bounds.height - margin
        badgeView.setImage(MNAssetPicker.image(named: "video")?.renderBy(color: UIColor(red: 251.0/255.0, green: 251.0/255.0, blue: 251.0/255.0, alpha: 1.0)), for: .normal)
        badgeView.setImage(MNAssetPicker.image(named: "livephoto")?.renderBy(color: UIColor(red: 251.0/255.0, green: 251.0/255.0, blue: 251.0/255.0, alpha: 1.0)), for: .highlighted)
        badgeView.setImage(MNAssetPicker.image(named: "gif")?.renderBy(color: UIColor(red: 251.0/255.0, green: 251.0/255.0, blue: 251.0/255.0, alpha: 1.0)), for: .selected)
        badgeView.autoresizingMask = [.flexibleRightMargin, .flexibleTopMargin]
        return badgeView
    }()
    // 文件大小
    private lazy var fileSizeLabel: UILabel = {
        let fileSizeLabel = UILabel()
        fileSizeLabel.maxX = contentView.bounds.width - margin
        fileSizeLabel.midY = badgeView.midY
        fileSizeLabel.numberOfLines = 1
        fileSizeLabel.textAlignment = .right
        fileSizeLabel.isUserInteractionEnabled = false
        fileSizeLabel.font = UIFont.systemFont(ofSize: 12.0)
        fileSizeLabel.textColor = UIColor(red: 251.0/255.0, green: 251.0/255.0, blue: 251.0/255.0, alpha: 1.0)
        return fileSizeLabel
    }()
    // 资源时长
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
    // 资源无效
    private lazy var holdView: UIView = {
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
        //contentView.addSubview(selectControl)
        contentView.addSubview(badgeView)
        contentView.addSubview(durationLabel)
        contentView.addSubview(fileSizeLabel)
        contentView.addSubview(indexLabel)
        contentView.addSubview(holdView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func update(asset: MNAsset) {
        self.asset = asset
        asset.container = imageView
        
        topShadow.isHidden = false
        bottomShadow.isHidden = false
        imageView.image = asset.thumbnail ?? asset.image
        holdView.isHidden = asset.isEnabled
        cloudView.isHidden = asset.source != .cloud
        if cloudView.isHidden == false {
            cloudView.state = asset.state == .downloading ? .highlighted : .normal
        }
        fileSizeLabel.isHidden = true
        if options.isShowFileSize, asset.fileSize > 0 {
            updateFileSize()
        }
//        if asset.isEnabled == false || asset.isTaking || (options.isAllowsPreview == false && (options.maxPickingCount <= 1 || (asset.type == .photo && options.isAllowsMultiplePickingPhoto == false) || (asset.type == .video && options.isAllowsMultiplePickingVideo == false) || (asset.type == .gif && options.isAllowsMultiplePickingGif == false) || (asset.type == .livePhoto && options.isAllowsMultiplePickingLivePhoto == false))) {
//            selectControl.isHidden = true
//        } else {
//            selectControl.isHidden = false
//            selectControl.index = asset.index
//            selectControl.isSelected = asset.isSelected
//        }
        
        switch asset.type {
        case .video:
            badgeView.state = .normal
            badgeView.isHidden = false
            if options.isShowFileSize, asset.fileSize > 0 {
                durationLabel.isHidden = true
            } else {
                durationLabel.text = asset.durationValue
                durationLabel.sizeToFit()
                durationLabel.midY = badgeView.midY
                durationLabel.isHidden = false
            }
        case .livePhoto:
            badgeView.state = .highlighted
            badgeView.isHidden = false
            durationLabel.isHidden = true
        case .gif:
            badgeView.state = .selected
            badgeView.isHidden = false
            durationLabel.isHidden = true
        default:
            badgeView.isHidden = true
            durationLabel.isHidden = true
        }
        
        if asset.isSelected {
            indexLabel.text = "\(asset.index)"
            indexLabel.isHidden = false
            topShadow.isHidden = true
            bottomShadow.isHidden = true
            badgeView.isHidden = true
            durationLabel.isHidden = true
        } else {
            indexLabel.isHidden = true
        }
        
        asset.thumbnailUpdateHandler = nil
        asset.thumbnailUpdateHandler = { [weak self] m in
            guard let self = self, let _ = self.asset, m == self.asset else { return }
            self.imageView.image = m.thumbnail ?? m.image
        }
        
        asset.sourceUpdateHandler = nil
        asset.sourceUpdateHandler = { [weak self] m in
            guard let self = self, let _ = self.asset, m == self.asset else { return }
            self.cloudView.isHidden = m.source != .cloud
        }
        
        asset.stateUpdateHandler = nil
        asset.stateUpdateHandler = { [weak self] m in
            guard let self = self, let _ = self.asset, m == self.asset else { return }
            self.cloudView.state = m.state == .downloading ? .highlighted : .normal
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
        fileSizeLabel.maxX = contentView.bounds.width - margin
        fileSizeLabel.midY = badgeView.midY
        fileSizeLabel.isHidden = false
        durationLabel.isHidden = true
    }
    
    func endDisplaying() {
        asset?.container = nil
        asset?.stateUpdateHandler = nil
        asset?.sourceUpdateHandler = nil
        asset?.fileSizeUpdateHandler = nil
        asset?.thumbnailUpdateHandler = nil
        asset?.cancelRequest()
    }
}

extension MNAssetCell {
    @objc func select(sender: MNAssetSelectControl) {
        delegate?.update(asset: asset)
    }
}
