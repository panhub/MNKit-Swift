//
//  MineHeaderView.swift
//  TLChat
//
//  Created by 冯盼 on 2022/7/22.
//  我的-表头

import UIKit

class MineHeaderView: MNAdsorbHeader {
    /// 聊天号ID
    private let idLabel: UILabel = UILabel()
    /// 昵称
    private let nickLabel: UILabel = UILabel()
    /// 头像
    let avatarButton: UIButton = UIButton(type: .custom)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        imageView.autoresizingMask = []
        imageView.image = UIImage(named: "mine-bg")
        imageView.sizeFitToWidth()
        
        avatarButton.size = CGSize(width: 78.0, height: 78.0)
        avatarButton.midY = imageView.maxY
        avatarButton.minX = MN_NAV_ITEM_MARGIN
        avatarButton.clipsToBounds = true
        avatarButton.layer.cornerRadius = avatarButton.height/2.0
        avatarButton.layer.borderWidth = 1.5
        avatarButton.layer.borderColor = UIColor(r: 247.0, g: 242.0, b: 230.0, a: 1.0).cgColor
        avatarButton.adjustsImageWhenHighlighted = false
        avatarButton.setBackgroundImage(UIImage(named: "mine-avatar"), for: .normal)
        contentView.addSubview(avatarButton)
        
        nickLabel.minX = avatarButton.minX
        nickLabel.numberOfLines = 1
        nickLabel.text = "您还未登录"
        nickLabel.textColor = .black
        nickLabel.textAlignment = .center
        nickLabel.font = .systemFont(ofSize: 20.0, weight: .medium)
        contentView.addSubview(nickLabel)
        
        idLabel.minX = avatarButton.minX
        idLabel.numberOfLines = 1
        idLabel.textAlignment = .center
        idLabel.textColor = UIColor(red: 0.4, green: 0.4, blue: 0.4, alpha: 1.0)
        idLabel.font = .systemFont(ofSize: 15.0, weight: .regular)
        contentView.addSubview(idLabel)
        
        height = avatarButton.maxY + 63.0
        
        updateUserInfo()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension MineHeaderView {
    
    func updateUserInfo() {
        
        if TLUser.shared.isLogin {
            // 登录
            nickLabel.text = TLUser.shared.nickname
            nickLabel.sizeToFit()
            nickLabel.width = ceil(nickLabel.width)
            nickLabel.height = ceil(nickLabel.height)
            idLabel.text = "ID: \(TLUser.shared.uid)"
            idLabel.sizeToFit()
            idLabel.width = ceil(idLabel.width)
            idLabel.height = ceil(idLabel.height)
            
            nickLabel.minY = (contentView.height - avatarButton.maxY - nickLabel.height - idLabel.height - 3.0)/2.0 + avatarButton.maxY
            idLabel.isHidden = false
            idLabel.minY = nickLabel.maxY + 3.0
        } else {
            // 未登录
            idLabel.isHidden = true
            nickLabel.text = "您还未登录"
            nickLabel.sizeToFit()
            nickLabel.width = ceil(nickLabel.width)
            nickLabel.height = ceil(nickLabel.height)
            nickLabel.midY = (contentView.height - avatarButton.maxY)/2.0 + avatarButton.maxY
        }
    }
}
