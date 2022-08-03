//
//  TLMineTableCell.swift
//  TLChat
//
//  Created by 冯盼 on 2022/7/21.
//  我的-表格

import UIKit

class TLMineTableCell: UITableViewCell {
    
    private let whiteView = UIView()
    
    private let titleLabel: UILabel = UILabel()
    
    private let iconView: UIImageView = UIImageView()
    
    init(reuseIdentifier: String?, size: CGSize) {
        super.init(style: .default, reuseIdentifier: reuseIdentifier)
        
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        self.size = size
        contentView.frame = bounds
        contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        whiteView.frame = contentView.bounds.inset(by: UIEdgeInsets(top: 0.0, left: MN_NAV_ITEM_MARGIN, bottom: 0.0, right: MN_NAV_ITEM_MARGIN))
        whiteView.backgroundColor = .white
        whiteView.layer.cornerRadius = ceil(whiteView.height/3.0)
        whiteView.clipsToBounds = true
        contentView.addSubview(whiteView)
        
        iconView.size = CGSize(width: 25.0, height: 25.0)
        iconView.minX = 15.0
        iconView.midY = whiteView.height/2.0
        iconView.contentMode = .scaleAspectFit
        whiteView.addSubview(iconView)
        
        titleLabel.numberOfLines = 1
        titleLabel.textAlignment = .center
        titleLabel.minX = iconView.maxX + 10.0
        titleLabel.textColor = UIColor(red: 0.18, green: 0.22, blue: 0.36, alpha: 1)
        titleLabel.font = .systemFont(ofSize: 17.0, weight: .medium)
        whiteView.addSubview(titleLabel)
    }
    
    func update(row model: TLMineModel) {
        iconView.image = UIImage(named: model.icon)
        titleLabel.text = model.title
        titleLabel.sizeToFit()
        titleLabel.midY = iconView.midY
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
