//
//  HTTPMethod.swift
//  MNFoundation
//
//  Created by 冯盼 on 2021/7/27.
//  请求方法定义

import Foundation

public struct HTTPMethod: RawRepresentable, Equatable {
    /**GET请求*/
    public static let get = HTTPMethod(rawValue: "GET")
    /**POST请求*/
    public static let post = HTTPMethod(rawValue: "POST")
    /**HEAD请求*/
    public static let head = HTTPMethod(rawValue: "HEAD")
    /**DELETE请求*/
    public static let delete = HTTPMethod(rawValue: "DELETE")
    /**保存请求方法*/
    public let rawValue: String
    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }
    public init(rawValue: String) {
        self.rawValue = rawValue
    }
    
    public static func == (lhs: HTTPMethod, rhs: HTTPMethod) -> Bool { lhs.rawValue == rhs.rawValue }
}
