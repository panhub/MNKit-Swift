//
//  TLMineHeaderView.swift
//  TLChat
//
//  Created by 冯盼 on 2022/7/21.
//  我的-表头

import UIKit

class TLMineHeaderView: MNAdsorbHeader {
    /// 聊天号ID
    private let idLabel: UILabel = UILabel()
    /// 昵称
    private let nickLabel: UILabel = UILabel()
    /// 头像
    private let avatarButton: UIButton = UIButton(type: .custom)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        imageView.image = UIImage(named: "view-bg")
        
        avatarButton.size = CGSize(width: 75.0, height: 75.0)
        avatarButton.minY = MN_TOP_BAR_HEIGHT
        avatarButton.midX = contentView.width/2.0
        avatarButton.layer.cornerRadius = avatarButton.height/2.0
        avatarButton.clipsToBounds = true
        avatarButton.adjustsImageWhenHighlighted = false
        avatarButton.setBackgroundImage(UIImage(named: "mine-avatar"), for: .normal)
        contentView.addSubview(avatarButton)
        
        nickLabel.numberOfLines = 1
        nickLabel.text = "您还未登录"
        nickLabel.textColor = .black
        nickLabel.textAlignment = .center
        nickLabel.font = .systemFont(ofSize: 20.0, weight: .medium)
        contentView.addSubview(nickLabel)
        
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

extension TLMineHeaderView {
    
    func updateUserInfo() {
        if TLUser.shared.isLogin {
            // 登录
            nickLabel.text = TLUser.shared.nickname
            //nickLabel.font = .systemFont(ofSize: 20.0, weight: .medium)
            nickLabel.sizeToFit()
            nickLabel.width = ceil(nickLabel.width)
            nickLabel.height = ceil(nickLabel.height)
            idLabel.text = "ID: \(TLUser.shared.uid)"
            idLabel.sizeToFit()
            idLabel.width = ceil(idLabel.width)
            idLabel.height = ceil(idLabel.height)
            
            nickLabel.midX = avatarButton.midX
            nickLabel.minY = (contentView.height - avatarButton.maxY - nickLabel.height - idLabel.height - 3.0)/2.0 + avatarButton.maxY
            idLabel.isHidden = false
            idLabel.minY = nickLabel.maxY + 3.0
            idLabel.midX = nickLabel.midX
        } else {
            // 未登录
            idLabel.isHidden = true
            nickLabel.text = "您还未登录"
            nickLabel.sizeToFit()
            nickLabel.width = ceil(nickLabel.width)
            nickLabel.height = ceil(nickLabel.height)
            nickLabel.midX = avatarButton.midX
            nickLabel.midY = (contentView.height - avatarButton.maxY)/2.0 + avatarButton.maxY
        }
    }
}
