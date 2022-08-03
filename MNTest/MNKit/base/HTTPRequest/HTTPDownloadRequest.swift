//
//  HTTPDownloadRequest.swift
//  MNFoundation
//
//  Created by 冯盼 on 2021/8/2.
//  下载请求体

import Foundation

/**询问下载位置回调*/
public typealias HTTPRequestLocationHandler = HTTPSessionLocationHandler

public class HTTPDownloadRequest: HTTPRequest {
    /**
     断点下载使用;
     不是下载数据本身, 而是已经下载好的数据相关信息;
     如: 文件名, 存储位置, 已经下载好的数据的长度等.
     */
    @objc public var resumeData: Data?
    /**询问下载位置回调 可能会回调两次 下载前检查文件是否存在*/
    public var locationHandler: HTTPRequestLocationHandler?
    /**下载选项*/
    public var downloadOptions: HTTPResponseParser.DownloadOptions = [.createIntermediateDirectories, .removeExistsFile]
    /**请求产生的Task*/
    @objc public var downloadTask: URLSessionDownloadTask? { task as? URLSessionDownloadTask }
    
    public override init() {
        super.init()
        serializationType = .none
        allowsCancelCallback = false
    }
    
    convenience init(url: String) {
        self.init()
        self.url = url
    }
    
    deinit {
        resumeData = nil
        locationHandler = nil
    }
    
    /**开启下载*/
    @objc public func download(start: HTTPRequestStartHandler? = nil, location: @escaping HTTPRequestLocationHandler, progress: HTTPRequestProgressHandler? = nil, completion: HTTPRequestCompletionHandler? = nil) -> Void {
        resumeData = nil
        startHandler = start
        progressHandler = progress
        locationHandler = location
        finishHandler = completion
        resume()
    }
    
    /**暂停下载*/
    @objc public func suspend(completion: ((Data?) -> Void)? = nil) -> Void {
        HTTPManager.default.cancel(download: self, completion: completion)
    }

    /**继续下载*/
    @objc public func resume(completion: ((Bool) -> Void)?) -> Void {
        HTTPManager.default.resume(download: self, completion: completion)
    }
}
