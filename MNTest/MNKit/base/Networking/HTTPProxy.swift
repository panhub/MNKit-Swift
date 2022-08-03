//
//  HTTPProxy.swift
//  MNFoundation
//
//  Created by 冯盼 on 2021/7/21.
//  请求代理

import UIKit
import ObjectiveC.runtime

public class HTTPProxy: NSObject {
    /**下载的位置*/
    private var fileURL: URL?
    /**服务端返回的数据*/
    private var data: Data? = Data()
    /**结束队列*/
    public weak var queue: DispatchQueue?
    /**序列化*/
    public var parser: HTTPResponseParser?
    /**上传进度*/
    public var uploadProgress: Progress = Progress(parent: nil, userInfo: nil)
    /**下载进度*/
    public var downloadProgress: Progress = Progress(parent: nil, userInfo: nil)
    /**上传进度回调*/
    public var uploadHandler: HTTPSessionProgressHandler?
    /**下载位置回调*/
    public var locationHandler: HTTPSessionLocationHandler?
    /**下载进度回调*/
    public var downloadHandler: HTTPSessionProgressHandler?
    /**结束回调*/
    public var completionHandler: HTTPSessionCompletionHandler?
    /**数据解析队列*/
    private static let SerializationQueue = DispatchQueue(label: "com.mn.url.session.serialization.queue", qos: .default, attributes: .concurrent)

    public init(task: URLSessionTask) {
        super.init()
        for progress in [uploadProgress, downloadProgress] {
            progress.isPausable = true
            progress.isCancellable = true
            progress.totalUnitCount = NSURLSessionTransferSizeUnknown
            progress.cancellationHandler = { [weak task] in
                task?.cancel()
            }
            progress.pausingHandler = { [weak task] in
                task?.suspend()
            }
            if #available(iOS 9.0, *) {
                progress.resumingHandler = { [weak task] in
                    task?.resume()
                }
            }
            progress.addObserver(self, forKeyPath: "fractionCompleted", options: .new, context: nil)
        }
    }
    
    deinit {
        for progress in [uploadProgress, downloadProgress] {
            progress.removeObserver(self, forKeyPath: "fractionCompleted")
        }
    }
    
    public override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if let obj = object, let progress = obj as? Progress {
            if progress == uploadProgress {
                (queue ?? DispatchQueue.main).async {
                    guard let callback = self.uploadHandler else { return }
                    callback(progress)
                }
            } else if progress == downloadProgress {
                (queue ?? DispatchQueue.main).async {
                    guard let callback = self.downloadHandler else { return }
                    callback(progress)
                }
            }
        }
    }
}

public extension HTTPProxy {

    func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) -> Void {
        uploadProgress.totalUnitCount = task.countOfBytesExpectedToSend
        uploadProgress.completedUnitCount = task.countOfBytesSent
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) -> Void {
        // 检查错误
        var httpError: HTTPError?
        if let _ = objc_getAssociatedObject(task, &HTTPSession.TaskAssociatedKey.challengeFailure) {
            httpError = .httpsChallengeFailure(.underlyingError(error!))
        } else if let downloadError = objc_getAssociatedObject(task, &HTTPSession.TaskAssociatedKey.downloadFailure) {
            httpError = downloadError as? HTTPError
        }
        if let httpError = httpError {
            if let fileURL = fileURL {
                try? FileManager.default.removeItem(at: fileURL)
            }
            (queue ?? DispatchQueue.main).async {
                self.completionHandler?(.failure(httpError))
            }
            return
        }
        // 解析数据
        let data = self.data
        self.data = nil
        HTTPProxy.SerializationQueue.async {
            var result: Any?
            let parser = self.parser ?? HTTPResponseParser.parser
            do {
                result = try parser.parse(response: task.response, data: data, error: error)
            } catch {
                // 回调错误 下载失败则删除
                if let fileURL = self.fileURL {
                    try? FileManager.default.removeItem(at: fileURL)
                }
                (self.queue ?? DispatchQueue.main).async {
                    self.completionHandler?(.failure(error.httpError!))
                }
                return
            }
            if let fileURL = self.fileURL, parser.serializationType == .none {
                // 下载请求, 将下载路径返回
                result = fileURL.path
            }
            // 回调结果
            (self.queue ?? DispatchQueue.main).async {
                self.completionHandler?(.success(result!))
            }
        }
    }
}

public extension HTTPProxy {
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) -> Void {
        self.data?.append(data)
        downloadProgress.totalUnitCount = dataTask.countOfBytesExpectedToReceive
        downloadProgress.completedUnitCount = dataTask.countOfBytesReceived
    }
}

public extension HTTPProxy {
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) -> Void {
        downloadProgress.totalUnitCount = totalBytesExpectedToWrite
        downloadProgress.completedUnitCount = totalBytesWritten
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didResumeAtOffset fileOffset: Int64, expectedTotalBytes: Int64) -> Void {
        downloadProgress.totalUnitCount = expectedTotalBytes;
        downloadProgress.completedUnitCount = fileOffset;
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) -> Void {
        
        fileURL = nil
        
        // 获取文件位置
        guard let callback = self.locationHandler else {
            objc_setAssociatedObject(downloadTask, &HTTPSession.TaskAssociatedKey.downloadFailure, HTTPError.downloadFailure(.cannotWriteToFile), .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            return
        }
        let fileURL = callback(downloadTask.response, location)
        guard fileURL.isFileURL else {
            objc_setAssociatedObject(downloadTask, &HTTPSession.TaskAssociatedKey.downloadFailure, HTTPError.downloadFailure(.cannotWriteToFile), .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            return
        }
        
        // 检查文件
        let parser = self.parser ?? HTTPResponseParser.parser
        if parser.downloadOptions.contains(.removeExistsFile) {
            // 文件存在则删除
            if FileManager.default.fileExists(atPath: fileURL.path) {
                do {
                    try FileManager.default.removeItem(at: fileURL)
                } catch {
                    objc_setAssociatedObject(downloadTask, &HTTPSession.TaskAssociatedKey.downloadFailure, HTTPError.downloadFailure(.fileExists(path: fileURL.path, error: error)), .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
                    return
                }
            }
        } else {
            // 文件存在则使用旧文件
            if FileManager.default.fileExists(atPath: fileURL.path) {
                self.fileURL = fileURL
                return
            }
        }
        
        // 检查路径
        if parser.downloadOptions.contains(.createIntermediateDirectories), FileManager.default.fileExists(atPath: fileURL.deletingLastPathComponent().path) == false {
            // 创建文件夹
            do {
                try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true, attributes: nil)
            } catch {
                objc_setAssociatedObject(downloadTask, &HTTPSession.TaskAssociatedKey.downloadFailure, HTTPError.downloadFailure(.cannotCreateFile(path: fileURL.path, error: error)), .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
                return
            }
        }
        
        // 移动文件
        do {
            try FileManager.default.moveItem(at: location, to: fileURL)
        } catch {
            objc_setAssociatedObject(downloadTask, &HTTPSession.TaskAssociatedKey.downloadFailure, HTTPError.downloadFailure(.cannotMoveFile(path: fileURL.path, error: error)), .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            return
        }
        
        // 保存文件位置
        self.fileURL = fileURL
    }
}
