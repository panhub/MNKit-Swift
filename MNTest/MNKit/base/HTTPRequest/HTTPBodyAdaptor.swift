//
//  HTTPBodyAdaptor.swift
//  MNFoundation
//
//  Created by 冯盼 on 2021/8/2.
//  上传数据适配

import UIKit
import Foundation
import CoreServices
import UniformTypeIdentifiers

public class HTTPBodyAdaptor {
    /**数据*/
    public var body: Data = Data()
    /**文字编码格式*/
    public var stringEncoding: String.Encoding = .utf8
    /**边界标记*/
    public var boundary: String = "com.mn.body.boundary.name"
    /**是否结束标记*/
    private var isFinishing: Bool = false
    /**开启*/
    public var beginAdapting: HTTPBodyAdaptor {
        body.removeAll()
        isFinishing = false
        return self
    }
    
    /**关闭*/
    public var endAdapting: HTTPBodyAdaptor {
        guard isFinishing == false else { return self }
        guard let data = "--\(boundary)--\r\n".data(using: stringEncoding) else { return self }
        isFinishing = true
        body.append(data)
        return self
    }
    
    /**
     追加字符串
     @param content 字符串
     @param key 关键字
     @return 是否追加成功
     */
    public func append(string content: String, for key: String) -> Bool {
        var string: String = ""
        string.append("--\(boundary)\r\n")
        string.append("Content-Disposition: form-data; name=\"\(key)\"\r\n")
        string.append("\r\n")
        string.append(content)
        string.append("\r\n")
        guard let data = string.data(using: stringEncoding) else { return false }
        body.append(data)
        return true
    }
    
    /**
     追加图片
     @param content 图片
     @param filename 文件名
     @param key 关键字
     @return 是否追加成功
     */
    public func append(image content: UIImage, key: String, filename: String) -> Bool {
        var name = filename
        if let pngData = content.pngData() {
            if (name as NSString).pathExtension.count <= 0 {
                name.append(".png")
            }
            return append(data: pngData, key: key, filename: name)
        } else if let jpegData = content.jpegData(compressionQuality: 1.0) {
            if (name as NSString).pathExtension.count <= 0 {
                name.append(".jpeg")
            }
            return append(data: jpegData, key: key, filename: name)
        }
        return false
    }
    
    /**
     追加数据流
     @param content 数据流
     @param filename 文件名<携带文件后缀>
     @param key 关键字
     @param type MIME<nil则内部依据文件后缀自行判断>
     @return 是否追加成功
     */
    public func append(data content: Data, key: String, filename: String, type: String? = nil) -> Bool {
        if content.count <= 0 || filename.count <= 0 || key.count <= 0 { return false }
        let mime = type ?? MNMIMEType(pathExtension: (filename as NSString).pathExtension)
        var string: String = ""
        string.append("--\(boundary)\r\n")
        string.append("Content-Disposition:form-data; name=\"\(key)\"; filename=\"\(filename)\"\r\n")
        string.append("Cotent-Type: \(mime)\r\n")
        string.append("\r\n")
        guard let begin = string.data(using: stringEncoding) else { return false }
        body.append(begin)
        body.append(content)
        guard let end = "\r\n".data(using: stringEncoding) else { return false }
        body.append(end)
        return true
    }
    
    /**
     追加文件
     @param URL 路径
     @param key 关键字
     @param filename 文件名
     @param type MIME<nil则内部依据文件后缀自行判断>
     @return 是否追加成功
     */
    public func append(_ URL: URL, key: String, filename: String? = nil, type: String? = nil) -> Bool {
        if URL.isFileURL {
            return append(file: URL.path, key: key, filename: filename, type: type)
        }
        guard let data = try? Data(contentsOf: URL) else { return false }
        var name = filename ?? (URL.lastPathComponent as NSString).lastPathComponent.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!
        if (name as NSString).pathExtension.count <= 0 {
            name.append(".\((URL.lastPathComponent as NSString).pathExtension)")
        }
        return append(data: data, key: key, filename: name, type: type)
    }
    
    /**
     追加文件
     @param file 路径
     @param key 关键字
     @param filename 文件名
     @param type MIME<nil则内部依据文件后缀自行判断>
     @return 是否追加成功
     */
    public func append(file path: String, key: String, filename: String? = nil, type: String? = nil) -> Bool {
        guard FileManager.default.fileExists(atPath: path), key.count > 0 else { return false }
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)) else { return false }
        var name = filename ?? (path as NSString).lastPathComponent.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!
        if (name as NSString).pathExtension.count <= 0 {
            name.append(".\((path as NSString).pathExtension)")
        }
        return append(data: data, key: key, filename: name, type: type)
    }
}

public func MNMIMEType(pathExtension ext: String) -> String {
    if #available(iOS 14.0, *) {
        if let uti = UTType(filenameExtension: ext), let mime = uti.preferredMIMEType {
            return mime
        }
    } else {
        if let uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, ext as CFString, nil)?.takeRetainedValue() {
            if let mime = UTTypeCopyPreferredTagWithClass(uti, kUTTagClassMIMEType)?.takeRetainedValue() {
                return mime as String
            }
        }
    }
    return "application/octet-stream"
}
