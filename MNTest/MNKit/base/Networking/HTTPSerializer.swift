//
//  HTTPSerializer.swift
//  MNFoundation
//
//  Created by 冯盼 on 2021/7/19.
//  请求序列化

import UIKit
import Foundation

public class HTTPSerializer {
    /** 是否允许使用蜂窝网络*/
    public var allowsCellularAccess: Bool = true
    /** 超时时长*/
    public var timeoutInterval: TimeInterval = 10.0
    /** 字符串编码格式*/
    public var stringEncoding: String.Encoding = .utf8
    /** 上传内容的分割标记*/
    public var boundary: String?
    /** 上传内容的长度*/
    public var contentLength: Int = 0
    /**POST数据体 非上传数据*/
    public var body: Any?
    /**请求地址参数拼接 支持 String, [String: String]*/
    public var query: Any?
    /**缓存策略*/
    public var cachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy
    /**Header信息*/
    public var headerFields: [String: String]?
    /**服务端认证信息*/
    public var authField: [String: String]?
    /**快速获取实例*/
    public static let serializer: HTTPSerializer = HTTPSerializer()
    
    public func request(_ url: String, _ method: HTTPMethod) throws -> URLRequest {
        // 检查链接
        guard url.count > 0 else { throw HTTPError.requestSerializationFailure(.invalidUrl(url)) }
        // 拼接参数并编码
        guard let str = query(url) else { throw HTTPError.requestSerializationFailure(.cannotQueryUrl(url)) }
        // 拼接参数并编码
        guard let URL = URL(string: str) else { throw HTTPError.requestSerializationFailure(.invalidUrl(url)) }
        // 创建请求体
        var request = URLRequest(url: URL)
        request.cachePolicy = cachePolicy
        request.httpMethod = method.rawValue
        request.timeoutInterval = timeoutInterval
        request.allowsCellularAccess = allowsCellularAccess
        request.allHTTPHeaderFields = headerFields
        // 添加认证信息
        if let auth = authField, auth.count > 0 {
            if let (username, password) = auth.first {
                if let data = (username + ":" + password).data(using: stringEncoding) {
                    request.setValue(data.base64EncodedString(), forHTTPHeaderField: "Authorization")
                }
            }
        }
        // 添加数据体
        if method == .post {
            if let body = self.body {
                // POST数据
                let data: Data? = body is Data ? (body as? Data) : MNQueryExtract(body)?.data(using: stringEncoding)
                guard let httpBody = data, httpBody.count > 0 else { throw HTTPError.requestSerializationFailure(.cannotEncodeBody) }
                request.httpBody = httpBody
                if request.value(forHTTPHeaderField: "Content-Type") == nil {
                    request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
                }
            } else if let boundary = boundary {
                // Upload数据
                if request.value(forHTTPHeaderField: "Content-Type") == nil {
                    request.setValue("multipart/form-data;charset=utf-8;boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
                }
                if contentLength > 0, request.value(forHTTPHeaderField: "Content-Length") == nil {
                    request.setValue("\(contentLength)", forHTTPHeaderField: "Content-Length")
                }
            }
        }
        return request
    }
    
    // url编码
    private func query(_ url: String) -> String? {
        // 链接编码
        guard var string = url.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed) else {
            return nil
        }
        // 参数编码
        guard let query = MNQueryExtract(query) else { return string }
        // 拼接参数
        string.append(contentsOf: string.contains("?") ? "&" : "?")
        string.append(contentsOf: query)
        return string
    }
}
