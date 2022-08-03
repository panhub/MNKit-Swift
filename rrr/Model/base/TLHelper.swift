//
//  TLHelper.swift
//  TLChat
//
//  Created by 冯盼 on 2022/7/21.
//

import UIKit

class TLHelper: NSObject {
    /// 禁止外界直接实例化
    private override init() {
        super.init()
    }
    
    /// 实例化入口
    static let helper: TLHelper = TLHelper()
    
    /// 是否显示隐私协议弹窗
    @UserDefaultsWrapper(key: "com.tl.show.privacy", default: true)
    var isShowPrivacyAlert: Bool
    
    /// 是否显示首页教程
    @UserDefaultsWrapper(key: "com.tl.show.home.course", default: true)
    var isShowHomeCourse: Bool
}
