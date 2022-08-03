//
//  TLLanguage.swift
//  TLChat
//
//  Created by 冯盼 on 2022/7/21.
//  翻译语言

import UIKit

class TLLanguage: NSObject {
    
    enum Mode {
        case from, to
    }
    
    /// 语言码
    var code: String = "0"
    /// 显示名称
    var name: String = "中文"
}

extension TLLanguage {
    
    static var auto: TLLanguage {
        let language = TLLanguage()
        language.code = "auto"
        language.name = "Auto"
        return language
    }
    
    static var english: TLLanguage {
        let language = TLLanguage()
        language.code = "en"
        language.name = "英语"
        return language
    }
}
