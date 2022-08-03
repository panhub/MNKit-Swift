//
//  TLMineModel.swift
//  TLChat
//
//  Created by 冯盼 on 2022/7/21.
//  我的-列表

import UIKit

class TLMineModel: NSObject {
    
    enum Event {
        case favorite, version, logout
    }
    
    /// 事件类型
    var event: Event = .favorite
    /// 图标
    var icon: String = ""
    /// 标题
    var title: String = ""
}
