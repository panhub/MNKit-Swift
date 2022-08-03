//
//  TLProfile.swift
//  TLChat
//
//  Created by 冯盼 on 2022/7/22.
//  注册相关信息

import Foundation

struct TLProfile {
    /// 聊天号
    var `id`: String = ""
    /// 手机号码
    var phone: String = ""
    /// 验证码
    var code: String = ""
    /// 密码
    var passcode: String = ""
    /// 昵称
    var nickname: String = ""
    /// 头像
    var avatar: String = ""
    /// 开通了几个账号
    var count: Int = 0
}
