//
//  HTTPParser.swift
//  MNFoundation
//
//  Created by 冯盼 on 2021/7/27.
//  请求结果序列化

import Foundation

public class HTTPParser {
    /**数据解析类型*/
    @objc public enum SerializationType: Int {
        case none
        case json
        case string
        case xml
        case plist
    }
    /**文件下载选项*/
    public struct DownloadOptions: OptionSet {
        // 当路径不存在时自动创建文件夹
        public static let createIntermediateDirectories = DownloadOptions(rawValue: 1 << 0)
        // 删除已存在的文件 否则存在则使用旧文件
        public static let removeExistsFile = DownloadOptions(rawValue: 1 << 1)
        
        public let rawValue: Int
        public init(rawValue: Int) {
            self.rawValue = rawValue
        }
    }
    /** 字符串编码格式*/
    public var stringEncoding: String.Encoding = .utf8
    /**接受的响应码*/
    public var acceptableStatusCodes: IndexSet = IndexSet(integersIn: 200..<300)
    /**JSON格式编码选项*/
    public var jsonReadingOptions: JSONSerialization.ReadingOptions = [.fragmentsAllowed]
    /**删除空数据 针对JsonObject有效*/
    public var removeNullValues: Bool = false
    /**数据解析方式*/
    public var serializationType: SerializationType = .json
    /**快速获取实例*/
    public static let parser: HTTPParser = HTTPParser()
    /**下载选项*/
    public var downloadOptions: DownloadOptions = [.createIntermediateDirectories, .removeExistsFile]
    /**接受的响应数据类型*/
    private var mimeTypes: Set<String>?
    public var acceptableContentTypes: Set<String>? {
        set { mimeTypes = newValue }
        get {
            guard let mimeTypes = mimeTypes else {
                switch serializationType {
                case .json:
                    return ["application/json", "text/json", "text/javascript"]
                case .string:
                    return ["text/html", "application/xml", "text/plain", "text/json"]
                case .xml:
                    return ["application/xml", "text/xml"]
                case .plist:
                    return ["application/x-plist"]
                default:
                    return nil
                }
            }
            return mimeTypes
        }
    }
    
    /// 解析响应结果
    /// - Parameters:
    ///   - response: 响应者
    ///   - data: 数据体
    ///   - error: 请求错误信息
    /// - Returns: 解析后的数据
    public func parse(response: URLResponse?, data: Data?, error: Error?) throws -> Any? {
        
        // 解析响应结果
        do {
            try parse(response: response, error: error)
        } catch {
            throw error
        }
        
        // 不解析数据则返回nil
        if serializationType == .none {
            return data
        }
        
        // 判断数据是否为空
        guard let responseData = data, responseData.count > 0, data != Data(bytes: " ", count: 1) else {
            throw HTTPError.dataParseFailure(.zeroByteData)
        }
        
        // 解析数据
        var responseObject: Any?
        switch serializationType {
        case .json:
            responseObject = try json(responseData)
        case .string:
            responseObject = try string(responseData)
        case .xml:
            responseObject = try xml(responseData)
        case .plist:
            responseObject = try plist(responseData)
        default: break
        }
        
        return responseObject
    }
    
    /// 解析响应者
    /// - Parameters:
    ///   - response: 响应者
    ///   - error: 请求错误信息
    private func parse(response: URLResponse?, error: Error?) throws {

        // 响应是否合法
        guard let httpResponse = response as? HTTPURLResponse else { throw HTTPError.responseParseFailure(.cannotParseResponse) }
        
        // 判断可接受的内容类型
        if let acceptTypes = acceptableContentTypes {
            // 判断响应类型
            guard let mimeType = httpResponse.mimeType else {
                throw HTTPError.responseParseFailure(.missingMimeType)
            }
            // 判断是否接受响应类型
            guard acceptTypes.contains(mimeType) else {
                throw HTTPError.responseParseFailure(.unsupportedContentType(mimeType: mimeType, accept: acceptTypes))
            }
        }
        // 判断状态码
        let statusCode = httpResponse.statusCode
        guard acceptableStatusCodes.contains(statusCode) else {
            throw HTTPError.responseParseFailure(.unsupportedStatusCode(statusCode))
        }
        // 是否有响应错误
        if let httpError = error {
            throw HTTPError.responseParseFailure(.underlyingError(httpError))
        }
    }
}

// MARK: - 数据解析
private extension HTTPParser {
    
    func json(_ data: Data) throws -> Any {
        
        var jsonObject: Any
        do {
            jsonObject = try JSONSerialization.jsonObject(with: data, options: jsonReadingOptions)
        } catch {
            throw HTTPError.dataParseFailure(.underlyingError(error))
        }
        
        // 删除null
        if removeNullValues {
            if let array = jsonObject as? [Any?] {
                var result: [Any] = [Any]()
                for value in array {
                    guard let value = value else { continue }
                    if value is NSNull { continue }
                    result.append(value)
                }
                jsonObject = result
            } else if let dic = jsonObject as? [AnyHashable:Any?] {
                var result: [AnyHashable:Any] = [AnyHashable:Any]()
                for (key, value) in dic {
                    guard let value = value else { continue }
                    if value is NSNull { continue }
                    result[key] = value
                }
                jsonObject = result
            }
        }
        
        return jsonObject
    }
    
    func string(_ data: Data) throws -> String {
        
        guard let stringObject = String(data: data, encoding: stringEncoding) else {
            throw HTTPError.dataParseFailure(.cannotDecodeData)
        }
        return stringObject
    }
    
    func xml(_ data: Data) throws -> XMLParser {
        return XMLParser(data: data)
    }
    
    func plist(_ data: Data) throws -> Any {
        
        var propertyList: Any
        do {
            propertyList = try PropertyListSerialization.propertyList(from: data, options: [], format: nil)
        } catch {
            throw HTTPError.dataParseFailure(.cannotDecodeData)
        }
        return propertyList
    }
}
