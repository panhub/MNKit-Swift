//
//  URL+MNExtension.swift
//  MNTest
//
//  Created by 冯盼 on 2022/10/27.
//  URL扩展

import Foundation

extension URL {
    
    /// 获取参数列表, 若链接不合法, 则为空
    var queryItems: [String:String]? {
        guard let components = URLComponents(url: self, resolvingAgainstBaseURL: true), let queryItems = components.queryItems else { return nil }
        return queryItems.reduce(into: [String:String]()) { $0[$1.name] = ($1.value ?? "") }
    }
}
