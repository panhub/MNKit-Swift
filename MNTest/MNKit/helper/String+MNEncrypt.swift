//
//  String+MNMD5.swift
//  MNFoundation
//
//  Created by 冯盼 on 2022/1/17.
//  字符串加/解密

import Foundation
import CommonCrypto

fileprivate struct Digest {
    
    let content: [UInt8]
    
    init(chars: [CChar]) {
        var array = [UInt8](repeating: 0, count: Int(CC_MD5_DIGEST_LENGTH))
        CC_MD5(chars, CC_LONG(chars.count - 1), &array)
        content = array
    }
    
    var md5: String { content.reduce("") { $0 + String(format: "%02x", $1) } }
    
    var MD5: String { content.reduce("") { $0 + String(format: "%02X", $1) } }
}

// MARK: - MD5加密
extension String {
    
    var md5: String {
        guard let chars = cString(using: .utf8) else { return "" }
        return Digest(chars: chars).md5
    }
    
    var MD5: String {
        guard let chars = cString(using: .utf8) else { return "" }
        return Digest(chars: chars).MD5
    }
}

// MARK: - Base64加/解密
extension String {
    
    /// base64加密字符串
    var base64EncodedString: String? {
        guard let data = data(using: .utf8) else { return nil }
        return data.base64EncodedString()
    }
    
    /// base64解密字符串
    var base64DecodedString: String? {
        guard let data = Data(base64Encoded: self) else { return nil }
        return String(data: data, encoding: .utf8)
    }
}
