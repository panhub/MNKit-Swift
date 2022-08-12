//
//  HTTPUploadRequest.swift
//  MNFoundation
//
//  Created by 冯盼 on 2021/8/2.
//  上传请求体

import Foundation

/**询问上传数据回调*/
public typealias HTTPRequestBodyHandler = HTTPSessionBodyHandler

@objc public class HTTPUploadRequest: HTTPRequest {
    /**上传请求的文件内容边界*/
    @objc public var boundary: String?
    /**询问下载位置回调*/
    var bodyHandler: HTTPRequestBodyHandler?
    /** 上传内容的长度*/
    @objc public var contentLength: Int = 0
    /**请求产生的Task*/
    @objc public var uploadTask: URLSessionUploadTask? { task as? URLSessionUploadTask }
    
    @objc convenience init(url: String) {
        self.init()
        self.url = url
    }
    
    deinit {
        bodyHandler = nil
    }
    
    @objc public func upload(start: HTTPRequestStartHandler? = nil, body: @escaping HTTPRequestBodyHandler, progress: HTTPRequestProgressHandler? = nil, completion: HTTPRequestCompletionHandler? = nil) -> Void {
        startHandler = start
        bodyHandler = body
        progressHandler = progress
        finishHandler = completion
        resume()
    }
    
    public func upload(adaptor: HTTPBodyAdaptor, start: HTTPRequestStartHandler? = nil, progress: HTTPRequestProgressHandler? = nil, completion: HTTPRequestCompletionHandler? = nil) -> Void {
        boundary = adaptor.endAdapting.boundary
        contentLength = adaptor.body.count
        let body = adaptor.body
        upload(start: start, body: {
            return body
        }, progress: progress, completion: completion)
    }
}
