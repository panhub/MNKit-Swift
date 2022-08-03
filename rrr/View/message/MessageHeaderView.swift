//
//  MessageHeaderView.swift
//  TLChat
//
//  Created by 冯盼 on 2022/7/22.
//  消息表头

import UIKit

class MessageHeaderView: UIView {
    
    /// 输入框
    let textField: UITextField = UITextField()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = .white
        
        textField.frame = CGRect(x: MN_NAV_ITEM_MARGIN, y: 10.0, width: frame.width - MN_NAV_ITEM_MARGIN*2.0, height: 38.0)
        //textField.delegate = self
        textField.font = .systemFont(ofSize: 17.0)
        textField.textColor = UIColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1.0)
        textField.backgroundColor = UIColor(red: 0.95, green: 0.95, blue: 0.95, alpha: 1.0)
        textField.borderStyle = .none
        textField.clipsToBounds = true
        textField.layer.cornerRadius = textField.height/2.0
        textField.clearButtonMode = .never
        textField.keyboardType = .default
        textField.returnKeyType = .search
        textField.contentVerticalAlignment = .center
        textField.contentHorizontalAlignment = .center
        //textField.tintColor = UIColor(r: 69.0, g: 94.0, b: 229.0, a: 1.0)
        textField.attributedPlaceholder = NSAttributedString(string: "搜索", attributes: [.font:textField.font!, .foregroundColor: UIColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1.0)])
        let leftView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: 35.0, height: textField.height))
        let search = UIImageView(image: UIImage(named: "message-search"))
        search.size = CGSize(width: 17.0, height: 17.0)
        search.midY = leftView.height/2.0
        search.maxX = leftView.width - 5.0
        search.contentMode = .scaleAspectFit
        leftView.addSubview(search)
        textField.leftView = leftView
        textField.leftViewMode = .always
        textField.rightView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: leftView.width, height: textField.height))
        textField.rightViewMode = .always
        addSubview(textField)
        
        height = textField.maxY + 20.0
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
