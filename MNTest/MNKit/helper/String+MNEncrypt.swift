//
//  String+MNMD5.swift
//  MNFoundation
//
//  Created by 冯盼 on 2022/1/17.
//  字符串加密

import Foundation
import CommonCrypto

extension String {
    
    // MD5加密类型
    enum MD5Mode: Int {
        case lowercase, uppercase
    }
    
    /**小写MD5*/
    var md5: String { md5(.lowercase) }
    
    /**大写MD5*/
    var MD5: String { md5(.uppercase) }
    
    func md5(_ mode: MD5Mode) -> String {
        guard count > 0 else { return "" }
        // 1.把待加密的字符串转成char类型数据 因为MD5加密是C语言加密
        guard let chars = cString(using: .utf8) else { return "" }
        // 2.创建一个字符串数组接受MD5的值
        var array = [UInt8](repeating: 0, count: Int(CC_MD5_DIGEST_LENGTH))
        // 3.计算MD5的值
        /*
        第一个参数:要加密的字符串
        第二个参数: 获取要加密字符串的长度
        第三个参数: 接收结果的数组
        */
        CC_MD5(chars, CC_LONG(chars.count - 1), &array)
        // 转换字符串
        switch mode {
        case .lowercase:
            return array.reduce("") { $0 + String(format: "%02x", $1) }
        case .uppercase:
            return array.reduce("") { $0 + String(format: "%02X", $1) }
        }
    }
}
