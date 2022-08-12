//
//  MNUserDefaults.swift
//  MNFoundation
//
//  Created by 冯盼 on 2021/9/23.
//  本地数据缓存包装

import Foundation

@propertyWrapper
struct UserDefaultsWrapper<T> {
    let key: String
    let suite: String?
    let defaultValue: T
    private var userDefaults: UserDefaults? {
        if let suiteName = suite, suiteName.count > 0 {
            return UserDefaults(suiteName: suiteName)
        }
        return UserDefaults.standard
    }
    
    var wrappedValue: T {
        get {
            (userDefaults?.object(forKey: key) as? T) ?? self.defaultValue
        }
        set {
            if let userDefaults = userDefaults {
                userDefaults.set(newValue, forKey: key)
                userDefaults.synchronize()
            }
        }
    }
    
    /// 构造属性包装器
    /// - Parameters:
    ///   - defaultName: 存储的key
    ///   - defaultValue: 默认值
    ///   - suiteName: 公共沙盒组名
    init(key defaultName: String, default defaultValue: T, suite suiteName: String? = nil) {
        self.key = defaultName
        self.suite = suiteName
        self.defaultValue = defaultValue
    }
}
