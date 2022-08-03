//
//  MNSecureOptions.swift
//  anhe
//
//  Created by 冯盼 on 2022/5/5.
//  配置

import UIKit

class MNSecureOptions: NSObject {
    
    /// 边框样式
    enum BorderStyle {
        case none  // 不考虑边框
        case square // 方格
        case grid // 网格样式 不考虑圆角
        case shadow // 底部线条 不考虑圆角
    }
    
    /**密码位数*/
    var capacity: Int = 4
    /**密码位间隔*/
    var interval: CGFloat = 0.0
    /**边框颜色*/
    var borderColor: UIColor?
    /**高亮边框颜色*/
    var highlightBorderColor: UIColor?
    /**边框宽度*/
    var borderWidth: CGFloat = 1.0
    /**边框样式*/
    var borderStyle: BorderStyle = .none
    /**明文字体*/
    var font: UIFont? = .systemFont(ofSize: 17.0, weight: .medium)
    /**明文颜色*/
    var textColor: UIColor? = .black
     /**背景缩放方式*/
    var bgImageMode: UIView.ContentMode = .scaleAspectFill
    /**自定义密文缩放方式*/
    var textImageMode: UIView.ContentMode = .scaleAspectFill
    /**边角*/
    var cornerRadius: CGFloat = 0.0
    /**自定义密文*/
    var textImage: UIImage?
    /**背景图片*/
    var bgImage: UIImage?
    /**是否以密文显示*/
    var isSecureTextEntry: Bool = false
    /**只能输入数字*/
    var isNumberTextEntry: Bool = false
}
