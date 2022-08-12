//
//  HTTPManager.swift
//  MNFoundation
//
//  Created by 冯盼 on 2021/8/1.
//  请求管理者 以单例模式存在

import UIKit
import Foundation
import ObjectiveC.runtime

public class HTTPManager {
    /**唯一实例化入口*/
    public static let `default` = HTTPManager()
    /**缓存管理*/
    let database = HTTPCache.default
    /**网络会话*/
    private let session = HTTPSession.default
    /**匹配请求方法*/
    private let methods: [HTTPMethod] = [.get, .post, .head, .delete]
    /**禁止实例化*/
    private init() {
        session.queue = DispatchQueue(label: "com.mn.http.session.completion.queue", qos: .default, attributes: .concurrent)
    }
    
    /**开启请求*/
    public func resume(request: HTTPRequest) -> Void {
        guard request.isLoading == false else { return }
        if let dataRequest = request as? HTTPDataRequest {
            load(dataRequest)
        } else if let downloadRequest = request as? HTTPDownloadRequest {
            download(downloadRequest)
        } else if let uploadRequest = request as? HTTPUploadRequest {
            upload(uploadRequest)
        }
    }
    
    /**取消请求*/
    public func cancel(request: HTTPRequest) -> Void {
        guard request.isLoading else { return }
        request.task?.cancel()
    }
    
    /**请求结束*/
    private func finish(request: HTTPRequest, result: Result<Any, HTTPError>) -> Void {
        // 判断是请求结束后的回调
//        if let _ = request.task {
//            // 关闭网络指示图
//            if request.allowsNetworkActivity {
//                UIApplication.closeNetworkActivityIndicating()
//            }
//        }
        // 标记已不是第一次请求
        request.isFirstLoading = false
        // 判断是否需要重新请求并修改数据来源
        let code = result.code
        if let dataRequest = request as? HTTPDataRequest {
            let retryCount = dataRequest.retry
            if let error = result.error, error.isCancelled == false, error.isQueryError == false, error.isParseError == false, retryCount < dataRequest.retryCount {
                // 重试
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + max(dataRequest.retryTimeInterval, 0.1)) { [weak self] in
                    dataRequest.retry = retryCount + 1
                    self?.load(dataRequest)
                }
                return
            }
            dataRequest.retry = 0
        }
        // 回调
        if code == HTTPErrorCancelled, request.allowsCancelCallback == false { return }
        request.finish(result: result)
    }
}

// MARK: - 数据请求
private extension HTTPManager {
    /**开始加载*/
    func load(_ request: HTTPDataRequest) -> Void {
        // 判断是否需要读取缓存
        if request.method == .get, request.cachePolicy == .local, request.retry <= 0, let cache = database.cache(key: request.cacheForKey, out: request.cacheTimeInterval) {
            request.source = .cache
            request.isFirstLoading = false
            request.finish(result: .success(cache))
            #if DEBUG
            print("读取缓存成功===\(request.url)")
            #endif
            return
        }
        // 创建Task
        request.task = dataTask(request)
        guard let dataTask = request.task else { return }
        request.source = .network
        // 是否允许显示网络加载
//        if request.allowsNetworkActivity {
//            UIApplication.startNetworkActivityIndicating()
//        }
        // 回调开始
        if request.retry <= 0 {
            DispatchQueue.main.async { [weak request] in
                guard let startHandler = request?.startHandler else { return }
                startHandler()
            }
        }
        // 开启请求
        dataTask.resume()
    }
    
    func dataTask(_ request: HTTPDataRequest) -> URLSessionDataTask? {
        return self.session.dataTask(with: request.url, method: methods[request.method.rawValue], serializer: serializer(request), parser: parser(request), progress: request.progressHandler, completion: { result in
            HTTPManager.default.finish(request: request, result: result)
        })
    }
}

// MARK: - 下载请求
public extension HTTPManager {
    /**下载*/
    private func download(_ request: HTTPDownloadRequest) -> Void {
        // 创建Task
        request.task = downloadTask(request)
        guard let downloadTask = request.task else { return }
        // 是否允许显示网络加载
//        if request.allowsNetworkActivity {
//            UIApplication.startNetworkActivityIndicating()
//        }
        // 回调开始
        DispatchQueue.main.async { [weak request] in
            guard let startHandler = request?.startHandler else { return }
            startHandler()
        }
        // 开启请求
        downloadTask.resume()
    }
    
    private func downloadTask(_ request: HTTPDownloadRequest) -> URLSessionDownloadTask? {
        return self.session.downloadTask(with: request.url, serializer: serializer(request), parser: parser(request), location: request.locationHandler ?? { _, _ in URL(fileURLWithPath: "") }, progress: request.progressHandler, completion: { result in
            HTTPManager.default.finish(request: request, result: result)
        })
    }
    
    /**可恢复的取消下载*/
    func cancel(download request: HTTPDownloadRequest, completion completionHandler: ((Data?) -> Void)? = nil) -> Void {
        // 询问下载实例
        guard let downloadTask = request.downloadTask else {
            completionHandler?(nil)
            return
        }
        // 判断是否下载中
        guard downloadTask.state == .running else {
            completionHandler?(request.resumeData)
            return
        }
        // 取消下载 会触发结束回调
        downloadTask.cancel { [weak request] data in
            request?.resumeData = data
            completionHandler?(data)
        }
    }
    
    /**继续下载*/
    func resume(download request: HTTPDownloadRequest, completion completionHandler: ((Bool) -> Void)? = nil) -> Void {
        
        // 判断是否下载中
        guard request.isLoading == false else {
            completionHandler?(false)
            return
        }
        // 判断是否支持暂停下载
        guard let resumeData = request.resumeData else {
            completionHandler?(false)
            return
        }
        // 创建新的下载请求
        request.task = self.session.downloadTask(with: resumeData, parser: parser(request), location: request.locationHandler ?? { _, _ in URL(fileURLWithPath: "") }, progress: request.progressHandler) { result in
            HTTPManager.default.finish(request: request, result: result)
        }
        guard let downloadTask = request.task else {
            completionHandler?(false)
            return
        }
        // 置空暂停标记
        request.resumeData = nil
        // 是否允许显示网络加载
//        if request.allowsNetworkActivity {
//            UIApplication.startNetworkActivityIndicating()
//        }
        // 开启请求
        downloadTask.resume()
        // 回调成功
        completionHandler?(true)
    }
}

// MARK: - 上传请求
private extension HTTPManager {
    func upload(_ request: HTTPUploadRequest) -> Void {
        // 创建Task
        request.task = uploadTask(request)
        guard let uploadTask = request.task else { return }
        // 是否允许显示网络加载
//        if request.allowsNetworkActivity {
//            UIApplication.startNetworkActivityIndicating()
//        }
        // 回调开始
        DispatchQueue.main.async { [weak request] in
            guard let startHandler = request?.startHandler else { return }
            startHandler()
        }
        // 开启请求
        uploadTask.resume()
    }
    
    func uploadTask(_ request: HTTPUploadRequest) -> URLSessionUploadTask? {
        return self.session.uploadTask(with: request.url, serializer: serializer(request), parser: parser(request), body: request.bodyHandler ?? {1}, progress: request.progressHandler, completion: { result in
            HTTPManager.default.finish(request: request, result: result)
        })
    }
}

// MARK: - 序列化
private extension HTTPManager {
    func serializer(_ request: HTTPRequest) -> HTTPSerializer {
        let serializer = HTTPSerializer()
        serializer.query = request.query
        serializer.authField = request.authField
        serializer.headerFields = request.headerFields
        serializer.timeoutInterval = request.timeoutInterval
        serializer.allowsCellularAccess = request.allowsCellularAccess
        serializer.stringEncoding = request.stringWritingEncoding
        serializer.body = (request as? HTTPDataRequest)?.body
        serializer.boundary = (request as?  HTTPUploadRequest)?.boundary
        serializer.contentLength = ((request as?  HTTPUploadRequest)?.contentLength) ?? 0
        return serializer
    }
    
    func parser(_ request: HTTPRequest) -> HTTPParser {
        let parser = HTTPParser()
        parser.jsonReadingOptions = request.jsonReadingOptions
        parser.acceptableStatusCodes = request.acceptableStatusCodes
        parser.stringEncoding = request.stringReadingEncoding
        parser.serializationType = request.serializationType
        parser.acceptableContentTypes = request.acceptableContentTypes
        if request is HTTPDataRequest {
            parser.removeNullValues = (request as! HTTPDataRequest).removeNullValues
        } else if request is HTTPDownloadRequest {
            parser.downloadOptions = (request as! HTTPDownloadRequest).downloadOptions
        }
        return parser
    }
}

// MARK: - 标记请求重试次数
fileprivate extension HTTPDataRequest {
    private struct AssociatedKey {
        static var retryCount = "com.mn.data.request.retry.count"
    }
    /**当前重试次数*/
    var retry: Int {
        get { return objc_getAssociatedObject(self, &AssociatedKey.retryCount) as? Int ?? 0 }
        set { objc_setAssociatedObject(self, &AssociatedKey.retryCount, newValue, .OBJC_ASSOCIATION_ASSIGN) }
    }
}
