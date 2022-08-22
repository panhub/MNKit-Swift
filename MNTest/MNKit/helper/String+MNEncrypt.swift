//
//  String+MNMD5.swift
//  MNFoundation
//
//  Created by 冯盼 on 2022/1/17.
//  字符串加密

import Foundation
import CommonCrypto

struct Digest {
    
    let content: [UInt8]
    
    init(chars: [CChar]) {
        var array = [UInt8](repeating: 0, count: Int(CC_MD5_DIGEST_LENGTH))
        CC_MD5(chars, CC_LONG(chars.count - 1), &array)
        content = array
    }
    
    var md5: String { content.reduce("") { $0 + String(format: "%02x", $1) } }
    
    var MD5: String { content.reduce("") { $0 + String(format: "%02X", $1) } }
}

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
