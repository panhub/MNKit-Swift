//
//  TLUser.swift
//  TLChat
//
//  Created by 冯盼 on 2022/7/21.
//  用户信息

import Foundation

class TLUser: NSObject {
    
    /// 用户信息缓存
    @UserDefaultsWrapper(key: "com.tl.user", default: [String:Any]())
    private static var userInfo: [String:Any]
    
    /// 默认用户入口
    static let shared: TLUser = TLUser(userInfo: TLUser.userInfo)
    /// 禁止直接实例化
    private override init() {
        super.init()
    }
    /// 构造密友
    convenience init(userInfo: [String:Any]) {
        self.init()
        update(userInfo: userInfo)
    }
    
    
    /// 是否处于登录状态
    var isLogin: Bool { uid.count > 0 && token.count > 0 }
    /// 用户标识
    private(set) var uid: String = ""
    /// 用户token
    private(set) var token: String = ""
    /// 头像
    private(set) var avatar: String = ""
    /// 昵称
    private(set) var nickname: String = ""
    
    /// 更新用户信息
    /// - Parameter userInfo: 用户数据
    private func update(userInfo: [String:Any]) {
        let json = JSON(userInfo)
        uid = json["uid"].stringValue
        token = json["token"].stringValue
        avatar = json["avatar"].stringValue
        nickname = json["nickname"].stringValue
    }
}
