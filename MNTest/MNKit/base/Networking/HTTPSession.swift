//
//  HTTPSession.swift
//  MNFoundation
//
//  Created by 冯盼 on 2021/7/21.
//  请求会话管理

import Foundation
import ObjectiveC.runtime

/**请求进度回调*/
public typealias HTTPSessionProgressHandler = (Progress)->Void
/**下载位置回调*/
public typealias HTTPSessionLocationHandler = (URLResponse?, URL?)->URL
/**上传内容回调 接收 URL Data String*/
public typealias HTTPSessionBodyHandler = ()->Any
/**请求结束回调*/
public typealias HTTPSessionCompletionHandler = (Result<Any, HTTPError>)->Void

/**定义公共通知*/
public extension Notification.Name {
    static let HTTPSessionDidFinishEvents = Notification.Name("com.mn.http.session.did.finish.events")
    static let HTTPSessionDidBecomeInvalid = Notification.Name("com.mn.http.session.did.become.invalid")
}

public class HTTPSession: NSObject {
    /**关联标记*/
    public struct TaskAssociatedKey {
        static var challengeFailure = "com.mn.http.session.task.challenge.failure"
        static var downloadFailure = "com.mn.http.session.task.download.failure"
    }
    /**会话实例*/
    private var session: URLSession!
    /**快捷实例化入口*/
    public static var `default` : HTTPSession = HTTPSession(configuration: nil)
    /**信号量保证线程安全*/
    fileprivate let semaphore = DispatchSemaphore(value: 1)
    /**代理缓存*/
    private var proxies = [Int: HTTPProxy]()
    /**结束回调队列*/
    public var queue: DispatchQueue?
    /**创建Task的串行队列*/
    private static let Queue = DispatchQueue(label: "com.mn.url.session.task.create.queue", qos: .default)
    /**安全策略*/
    private lazy var securityPolicy: HTTPSecurityPolicy = {
        return HTTPSecurityPolicy.default
    }()
    
    // 不允许直接实例化
    private override init() {}
    
    init(configuration: URLSessionConfiguration?) {
        super.init()
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        session = URLSession(configuration: URLSessionConfiguration.default, delegate: self, delegateQueue: queue)
        session.getTasksWithCompletionHandler { [weak self] dataTasks, uploadTasks, downloadTasks in
            // 初始化
            for dataTask in dataTasks {
                self?.setProxy(task: dataTask)
            }
            for uploadTask in uploadTasks {
                self?.setProxy(task: uploadTask)
            }
            for downloadTask in downloadTasks {
                self?.setProxy(task: downloadTask)
            }
        }
    }
}

// MARK: - GET/POST/HEAD/DELETE
public extension HTTPSession {
    
    func get(_ url: String, progress: HTTPSessionProgressHandler? = nil, completion: @escaping HTTPSessionCompletionHandler) -> Void {
        guard let dataTask = dataTask(with: url, method: .get, serializer: nil, parser: nil, progress: progress, completion: completion) else { return }
        dataTask.resume()
    }
    
    func post(_ url: String, progress: HTTPSessionProgressHandler? = nil, completion: @escaping HTTPSessionCompletionHandler) -> Void {
        guard let dataTask = dataTask(with: url, method: .post, serializer: nil, parser: nil, progress: progress, completion: completion) else { return }
        dataTask.resume()
    }
    
    func head(_ url: String, completion: @escaping HTTPSessionCompletionHandler) -> Void {
        guard let dataTask = dataTask(with: url, method: .head, completion: completion) else { return }
        dataTask.resume()
    }
    
    func delete(_ url: String, completion: @escaping HTTPSessionCompletionHandler) -> Void {
        guard let dataTask = dataTask(with: url, method: .delete, completion: completion) else { return }
        dataTask.resume()
    }
}

// MARK: - dataTask
public extension HTTPSession {
    func dataTask(with url: String, method: HTTPMethod, serializer: HTTPSerializer? = nil, parser:HTTPParser? = nil, progress: HTTPSessionProgressHandler? = nil, completion: @escaping HTTPSessionCompletionHandler) -> URLSessionDataTask? {
        let request: URLRequest?
        do {
            request = try (serializer ?? HTTPSerializer.serializer).request(url, method)
        } catch {
            let httpError: HTTPError = error.httpError ?? .custom(code: (error as NSError).code, msg: error.localizedDescription)
            (queue ?? DispatchQueue.main).async {
                completion(.failure(httpError))
            }
            return nil
        }
        var dataTask: URLSessionDataTask?
        HTTPSession.Queue.sync {
            dataTask = self.session.dataTask(with: request!)
        }
        // 保存代理
        setProxy(task: dataTask!, parser: parser, location: nil, upload: (method == .get ? nil : progress), download: (method == .get ? progress : nil), completion: completion)
        return dataTask
    }
}

// MARK: - downloadTask
public extension HTTPSession {
    func downloadTask(with url: String, serializer: HTTPSerializer? = nil, parser:HTTPParser? = nil, location: @escaping HTTPSessionLocationHandler, progress: HTTPSessionProgressHandler? = nil, completion: @escaping HTTPSessionCompletionHandler) -> URLSessionDownloadTask? {
        // 判断是否需要下载文件
        if let _ = parser, parser!.downloadOptions.contains(.removeExistsFile) == false {
            let fileURL = location(nil, nil)
            if fileURL.isFileURL, FileManager.default.fileExists(atPath: fileURL.path) {
                (queue ?? DispatchQueue.main).async {
                    completion(.success(fileURL.path))
                }
                return nil
            }
        }
        // 初始化下载请求
        let request: URLRequest?
        do {
            request = try (serializer ?? HTTPSerializer.serializer).request(url, .get)
        } catch {
            let httpError: HTTPError = error.httpError ?? .custom(code: (error as NSError).code, msg: error.localizedDescription)
            (queue ?? DispatchQueue.main).async {
                completion(.failure(httpError))
            }
            return nil
        }
        var downloadTask: URLSessionDownloadTask?
        HTTPSession.Queue.sync {
            downloadTask = self.session.downloadTask(with: request!)
        }
        // 设置代理
        setProxy(task: downloadTask!, parser: parser, location: location, upload: nil, download: progress, completion: completion)
        return downloadTask
    }
    
    func downloadTask(with resumeData: Data, parser: HTTPParser? = nil, location: @escaping HTTPSessionLocationHandler, progress: HTTPSessionProgressHandler? = nil, completion: @escaping HTTPSessionCompletionHandler) -> URLSessionDownloadTask? {
        var downloadTask: URLSessionDownloadTask?
        HTTPSession.Queue.sync {
            downloadTask = self.session.downloadTask(withResumeData: resumeData)
        }
        // 设置代理
        setProxy(task: downloadTask!, parser: parser, location: location, upload: nil, download: progress, completion: completion)
        return downloadTask
    }
}

// MARK: - uploadTask
public extension HTTPSession {
    func uploadTask(with url: String, serializer: HTTPSerializer? = nil, parser:HTTPParser? = nil, body: HTTPSessionBodyHandler, progress: HTTPSessionProgressHandler? = nil, completion: @escaping HTTPSessionCompletionHandler) -> URLSessionUploadTask? {
        // 创建请求
        let request: URLRequest?
        do {
            request = try (serializer ?? HTTPSerializer.serializer).request(url, .post)
        } catch {
            let httpError: HTTPError = error.httpError ?? .custom(code: (error as NSError).code, msg: error.localizedDescription)
            (queue ?? DispatchQueue.main).async {
                completion(.failure(httpError))
            }
            return nil
        }
        // 询问body
        let obj = body()
        var uploadTask: URLSessionUploadTask?
        if let filePath = obj as? String, FileManager.default.fileExists(atPath: filePath) {
            HTTPSession.Queue.sync {
                uploadTask = self.session.uploadTask(with: request!, fromFile: URL(fileURLWithPath: filePath))
            }
        } else if let fileURL = obj as? URL, fileURL.isFileURL, FileManager.default.fileExists(atPath: fileURL.path) {
            HTTPSession.Queue.sync {
                uploadTask = self.session.uploadTask(with: request!, fromFile: fileURL)
            }
        } else if let fileData = obj as? Data, fileData.count > 0 {
            HTTPSession.Queue.sync {
                uploadTask = self.session.uploadTask(with: request!, from: fileData)
            }
        }
        guard let _ = uploadTask else {
            (queue ?? DispatchQueue.main).async {
                completion(.failure(.uploadFailure(.bodyIsEmpty)))
            }
            return nil
        }
        // 设置代理
        setProxy(task: uploadTask!, parser: parser, location: nil, upload: progress, download: nil, completion: completion)
        return uploadTask
    }
}

// MARK: - 保存代理
fileprivate extension HTTPSession {
    func setProxy(task: URLSessionTask, parser: HTTPParser? = nil, location: HTTPSessionLocationHandler? = nil, upload: HTTPSessionProgressHandler? = nil, download: HTTPSessionProgressHandler? = nil, completion: HTTPSessionCompletionHandler? = nil) -> Void {
        let proxy = HTTPProxy(task: task)
        proxy.queue = queue
        proxy.parser = parser
        proxy.uploadHandler = upload
        proxy.locationHandler = location
        proxy.downloadHandler = download
        proxy.completionHandler = completion
        setProxy(proxy, identifier: task.taskIdentifier)
    }
}

// MARK: - 代理存取
private extension HTTPSession {
   func proxy(for identifier: Int) -> HTTPProxy? {
        semaphore.wait()
        let proxy = proxies[identifier]
        semaphore.signal()
        return proxy
    }
    func setProxy(_ proxy: HTTPProxy, identifier: Int) -> Void {
        semaphore.wait()
        proxies[identifier] = proxy
        semaphore.signal()
    }
    func removeProxy(identifier: Int) -> Void {
        semaphore.wait()
        let _ = proxies.removeValue(forKey: identifier)
        semaphore.signal()
    }
}

// MARK: - URLSessionDelegate
extension HTTPSession: URLSessionDelegate {
    /**
     当前session失效时, 该代理方法被调用;
     如果使用finishTasksAndInvalidate函数使该session失效,
     那么session首先会先完成最后一个task, 然后再调用URLSession:didBecomeInvalidWithError:代理方法;
     如果使用invalidateAndCancel方法来使session失效, 那么该session会立即调用此代理方法;
     @param session 失效session
     @param error 错误信息
     */
    public func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {
        (queue ?? DispatchQueue.main).async {
            NotificationCenter.default.post(name: .HTTPSessionDidBecomeInvalid, object: session)
        }
    }
    /**
     Session中所有已经入队的消息被发送出去
     @param session 会话
     */
    public func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        (queue ?? DispatchQueue.main).async {
            NotificationCenter.default.post(name: .HTTPSessionDidFinishEvents, object: session)
        }
    }
}

// MARK: - URLSessionTaskDelegate
extension HTTPSession: URLSessionTaskDelegate {
    /**
     服务器重定向时调用
     只会在default session或者ephemeral session中调用
     在background session中, session task会自动重定向
     @param session 当前会话
     @param task task
     @param response 响应
     @param request 请求对象
     @param completionHandler 回调处理
     */
    public func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest, completionHandler: @escaping (URLRequest?) -> Void) {
        completionHandler(request)
    }
    
    /**
     Task级别HTTPS认证挑战
     @Session级别认证挑战 不响应也会转向这个
     @param session 当前session
     @param task 当前task
     @param challenge 挑战类型
     @param completionHandler 回调挑战证书
     */
    public func urlSession(_ session: URLSession, task: URLSessionTask, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        var credential: URLCredential?
        var disposition = URLSession.AuthChallengeDisposition.performDefaultHandling
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust {
            if securityPolicy.evaluate(server: challenge.protectionSpace.serverTrust!, domain: challenge.protectionSpace.host) {
                disposition = .useCredential
                credential = URLCredential(trust: challenge.protectionSpace.serverTrust!)
            } else {
                // 验证失败 标记失败 这里还不能获取错误信息
                disposition = .cancelAuthenticationChallenge
                objc_setAssociatedObject(task, &HTTPSession.TaskAssociatedKey.challengeFailure, true, .OBJC_ASSOCIATION_ASSIGN)
            }
        }
        completionHandler(disposition, credential)
    }
    
    /**
     因为认证挑战或者其他可恢复的服务器错误导致需要客户端重新发送一个含有body stream的request;
     如果task是由uploadTaskWithStreamedRequest:创建的,那么提供初始的request body stream时候会调用
     @param session 当前会话
     @param task 当前task
     @param completionHandler 回调
     */
    public func urlSession(_ session: URLSession, task: URLSessionTask, needNewBodyStream completionHandler: @escaping (InputStream?) -> Void) {
        var inputStream: InputStream?
        if let bodyStream = task.originalRequest?.httpBodyStream, bodyStream.conforms(to: NSCopying.self) {
            inputStream = task.originalRequest!.httpBodyStream!.copy() as? InputStream
        }
        completionHandler(inputStream)
    }
    
    /**
     每次发送数据给服务器回调这个方法通知已经发送了多少, 总共要发送多少
     @param session 当前会话
     @param task 当前task
     @param bytesSent 已发送数据量
     @param totalBytesSent 总共要发送数据量
     @param totalBytesExpectedToSend 剩余数据量
     */
    public func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        guard let proxy = proxy(for: task.taskIdentifier) else { return }
        proxy.urlSession(session, task: task, didSendBodyData: bytesSent, totalBytesSent: totalBytesSent, totalBytesExpectedToSend: totalBytesExpectedToSend)
    }
    
    /**
     Task执行结束
     @param session 当前会话
     @param task 当前task
     @param error 错误信息
     */
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let proxy = proxy(for: task.taskIdentifier) else { return }
        removeProxy(identifier: task.taskIdentifier)
        proxy.urlSession(session, task: task, didCompleteWithError: error)
    }
}

// MARK: - URLSessionDataDelegate
extension HTTPSession: URLSessionDataDelegate {
    /**
     该data task获取到了服务器端传回的最初始回复(response);
     其中的completionHandler传入一个类型为NSURLSessionResponseDisposition的变量;
     通过回调completionHandler决定该传输任务接下来该做什么;
     NSURLSessionResponseAllow 该task正常进行;
     NSURLSessionResponseCancel 该task会被取消;
     NSURLSessionResponseBecomeDownload 会调用URLSession:dataTask:didBecomeDownloadTask:方法
     来新建一个download task以代替当前的data task
     NSURLSessionResponseBecomeStream 转成一个StreamTask
     */
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        completionHandler(.allow);
    }
    
    /**
     didReceiveResponse:completionHandler设置为NSURLSessionResponseBecomeDownload, 则会调用
     */
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didBecome downloadTask: URLSessionDownloadTask) {
        guard let proxy = proxy(for: dataTask.taskIdentifier) else { return }
        removeProxy(identifier: dataTask.taskIdentifier)
        setProxy(proxy, identifier: downloadTask.taskIdentifier)
    }
    
    /**
     didReceiveResponse:completionHandler设置为NSURLSessionResponseBecomeStream, 则会调用
     */
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didBecome streamTask: URLSessionStreamTask) {
        guard let proxy = proxy(for: dataTask.taskIdentifier) else { return }
        removeProxy(identifier: dataTask.taskIdentifier)
        setProxy(proxy, identifier: dataTask.taskIdentifier)
    }
    
    // 当我们获取到数据就会调用，会被反复调用，请求到的数据就在这被拼装完整
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        guard let proxy = proxy(for: dataTask.taskIdentifier) else { return }
        proxy.urlSession(session, dataTask: dataTask, didReceive: data)
    }
    
    /*
     当task接收到所有期望的数据后, session会调用此代理方法
     询问data task或upload task, 是否缓存response
     如果你没有实现该方法, 那么就会使用创建session时使用的configuration对象决定缓存策略
     阻止缓存特定的URL或者修改NSCacheURLResponse对象相关的userInfo字典可使用
     缓存准则:
     1, 该request是HTTP或HTTPS URL的请求(或者你自定义的网络协议且确保该协议支持缓存)
     2, 确保request请求是成功的(返回的status code为200-299)
     3, 返回的response是来自服务器端的, 而非缓存中本身就有的
     4, 提供的NSURLRequest对象的缓存策略要允许进行缓存
     5, 服务器返回的response中与缓存相关的header要允许缓存
     5, 该response的大小不能比提供的缓存空间大太多(超过5%)
     */
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, willCacheResponse proposedResponse: CachedURLResponse, completionHandler: @escaping (CachedURLResponse?) -> Void) {
        completionHandler(proposedResponse)
    }
}

// MARK: - URLSessionDownloadDelegate
extension HTTPSession: URLSessionDownloadDelegate {
    /**
     周期性地通知下载进度
     @param session 当前session
     @param downloadTask 下载任务实例
     @param bytesWritten 上次调用该方法后，接收到的数据字节数
     @param totalBytesWritten 目前已经接收到的数据字节数
     @param totalBytesExpectedToWrite 期望收到的文件总字节数(由Content-Length header提供, 如果没有提供, 默认是NSURLSessionTransferSizeUnknown)
     */
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        guard let proxy = proxy(for: downloadTask.taskIdentifier) else { return }
        proxy.urlSession(session, downloadTask: downloadTask, didWriteData: bytesWritten, totalBytesWritten: totalBytesWritten, totalBytesExpectedToWrite: totalBytesExpectedToWrite)
    }
    
    /**
    当下载被取消或者失败后重新恢复下载时调用
     如果下载任务被取消或者失败了, 可以请求一个resumeData对象;
     比如在userInfo字典中通过NSURLSessionDownloadTaskResumeData这个键来获取到resumeData;
     使用它来提供足够的信息以重新开始下载任务;
     随后可以使用resumeData作为downloadTaskWithResumeData:或downloadTaskWithResumeData:completionHandler:的参数;
     当调用这些方法时,将开始一个新的下载任务;
     一旦继续下载任务, session会调用此代理方法;
     其中的downloadTask参数表示的就是新的下载任务, 这也意味着下载重新开始了;
    */
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didResumeAtOffset fileOffset: Int64, expectedTotalBytes: Int64) {
        guard let proxy = proxy(for: downloadTask.taskIdentifier) else { return }
        proxy.urlSession(session, downloadTask: downloadTask, didResumeAtOffset: fileOffset, expectedTotalBytes: expectedTotalBytes)
    }
    
    /**
     下载完成回调
     */
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        guard let proxy = proxy(for: downloadTask.taskIdentifier) else { return }
        proxy.urlSession(session, downloadTask: downloadTask, didFinishDownloadingTo: location)
    }
}
