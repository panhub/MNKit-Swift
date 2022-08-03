//
//  MNAssetAlbumCell.swift
//  MNFoundation
//
//  Created by 冯盼 on 2022/1/31.
//  资源选择器相册cell

import UIKit

class MNAssetAlbumCell: UITableViewCell {
    // 相簿模型
    private(set) var album: MNAssetAlbum!
    // 标题
    private let titleLabel: UILabel = UILabel()
    // 数量
    private let countLabel: UILabel = UILabel()
    // 封面
    private let coverView: UIImageView = UIImageView()
    // 数量
    private let selectedView: UIImageView = UIImageView()
    
    init(reuseIdentifier: String?, size: CGSize, options: MNAssetPickerOptions) {
        super.init(style: .default, reuseIdentifier: reuseIdentifier)
        
        self.size = size
        selectionStyle = .none
        backgroundColor = .clear
        contentView.frame = bounds
        contentView.backgroundColor = .clear
        contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        coverView.minX = 15.0
        coverView.size = CGSize(width: contentView.height - 20.0, height: contentView.height - 20.0)
        coverView.midY = contentView.bounds.midY
        coverView.clipsToBounds = true
        coverView.isUserInteractionEnabled = false
        coverView.contentMode = .scaleAspectFill
        coverView.backgroundColor = UIColor(white: 0.0, alpha: 0.12)
        contentView.addSubview(coverView)
        
        titleLabel.minX = coverView.maxX + 15.0
        titleLabel.numberOfLines = 1
        titleLabel.isUserInteractionEnabled = false
        titleLabel.font = .systemFont(ofSize: 17.0, weight: .regular)
        titleLabel.textColor = options.mode == .light ? .darkText.withAlphaComponent(0.95) : UIColor(red: 251.0/255.0, green: 251.0/255.0, blue: 251.0/255.0, alpha: 1.0)
        contentView.addSubview(titleLabel)
        
        countLabel.numberOfLines = 1
        countLabel.isUserInteractionEnabled = false
        countLabel.font = .systemFont(ofSize: 16.0, weight: .regular)
        countLabel.textColor = UIColor(red: 74.0/255.0, green: 74.0/255.0, blue: 74.0/255.0, alpha: 1.0)
        contentView.addSubview(countLabel)
        
        selectedView.isHidden = true
        selectedView.isUserInteractionEnabled = false
        selectedView.size = CGSize(width: 23.0, height: 23.0)
        selectedView.midY = contentView.bounds.midY
        selectedView.maxX = contentView.bounds.width - 25.0
        selectedView.image = MNAssetPicker.image(named: "checkmark")?.renderBy(color: options.color)
        contentView.addSubview(selectedView)
        
        separatorInset = UIEdgeInsets(top: 0.0, left: coverView.minX, bottom: 0.0, right: 0.0)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
}

extension MNAssetAlbumCell {
    
    func update(album: MNAssetAlbum) {
        self.album = album
        let selected = album.assets.filter { $0.isSelected }
        titleLabel.text = album.title
        titleLabel.sizeToFit()
        titleLabel.midY = contentView.bounds.midY
        countLabel.text = "(\(selected.count)/\(album.assets.count))"
        countLabel.sizeToFit()
        countLabel.minX = titleLabel.maxX + 5.0
        countLabel.midY = contentView.bounds.midY
        selectedView.isHidden = album.isSelected == false
        coverView.image = nil
        if album.assets.count > 0 {
            MNAssetHelper.thumbnail(asset: album.assets.first!) { [weak self] asset, image in
                DispatchQueue.main.async {
                    guard let album = self?.album, album.assets.count > 0, asset == album.assets.first! else { return }
                    self?.coverView.image = image
                }
            }
        }
    }
    
    func didEndDisplaying() {
        guard let album = album, album.assets.count > 0 else { return }
        album.assets.first!.cancelRequest()
    }
}
