//
//  TLShare.swift
//  TLChat
//
//  Created by 冯盼 on 2022/7/21.
//  配置信息

import UIKit

class TLConfigure: NSObject {
    
    /// 禁止外界直接实例化
    private override init() {
        super.init()
    }
    
    /// 实例化入口
    static let shared: TLConfigure = TLConfigure()
}
