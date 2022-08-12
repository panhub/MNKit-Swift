//
//  HTTPRequest.swift
//  MNFoundation
//
//  Created by 冯盼 on 2021/8/1.
//  网络请求基类, 不可直接实例化使用

import Foundation

/**请求开始回调*/
public typealias HTTPRequestStartHandler = ()->Void
/**请求结束回调*/
public typealias HTTPRequestCompletionHandler = (HTTPResult)->Void
/**请求进度回调*/
public typealias HTTPRequestProgressHandler = HTTPSessionProgressHandler

@objc public class HTTPRequest: NSObject {
    /**请求地址*/
    @objc public var url: String = ""
    /**参数 支持String, [String:String]*/
    @objc public var query: Any?
    /**回调队列*/
    @objc public weak var queue: DispatchQueue?
    /**请求超时时间*/
    @objc public var timeoutInterval: TimeInterval = 10.0
    /**字符串编码格式*/
    public var stringWritingEncoding: String.Encoding = .utf8
    /** 是否允许使用蜂窝网络*/
    @objc public var allowsCellularAccess: Bool = true
    /** 是否允许取消后回调*/
    @objc public var allowsCancelCallback: Bool = false
    /** 是否显示请求网络视图*/
    @objc public var allowsNetworkActivity: Bool = true
    /**Header信息*/
    @objc public var headerFields: [String: String]?
    /**服务端认证信息*/
    @objc public var authField: [String: String]?
    
    /** 字符串编码格式*/
    public var stringReadingEncoding: String.Encoding = .utf8
    /**接受的响应码*/
    @objc public var acceptableStatusCodes: IndexSet = IndexSet(integersIn: 200..<300)
    /**接受的响应数据类型*/
    @objc public var acceptableContentTypes: Set<String>?
    /**JSON格式编码选项*/
    @objc public var jsonReadingOptions: JSONSerialization.ReadingOptions = []
    /**数据解析方式*/
    @objc public var serializationType: HTTPParser.SerializationType = .json
    
    /**请求产生的Task*/
    @objc public var task: URLSessionTask?
    /** 是否是第一次请求*/
    @objc public var isFirstLoading: Bool = true
    /**是否在请求*/
    @objc public var isLoading: Bool {
        guard let _ = task else { return false }
        return task!.state == .running
    }
    
    /**开始回调*/
    public var startHandler: HTTPRequestStartHandler?
    /**结束回调*/
    public var finishHandler: HTTPRequestCompletionHandler?
    /**进度回调*/
    public var progressHandler: HTTPRequestProgressHandler?
    
    @objc public override init() {
        super.init()
    }
    
    /// 依据链接初始化
    /// - Parameter url: 链接
    @objc public convenience init(url: String) {
        self.init()
        self.url = url
    }
    
    deinit {
        task = nil
        startHandler = nil
        finishHandler = nil
        progressHandler = nil
    }
    
    /**开启请求*/
    @objc public func resume() -> Void {
        HTTPManager.default.resume(request: self)
    }
    
    /**取消请求*/
    @objc public func cancel() -> Void {
        HTTPManager.default.cancel(request: self)
    }
    
    /**定制请求结束处理*/
    public func finish(result: Result<Any, HTTPError>) -> Void {
        // 整理结果
        let httpResult = HTTPResult(result: result)
        httpResult.request = self
        if httpResult.isSuccess {
            succeed(result: httpResult)
        }
        if httpResult.isSuccess {
            // 回调成功函数
            succeed(responseObject: httpResult.data!)
        }
        // 回调结果 这里要强引用self 避免过早释放
        (queue ?? DispatchQueue.main).async {
            // 回调结果代码块
            self.finishHandler?(httpResult)
        }
    }
    /**定制请求成功处理*/
    @objc public func succeed(responseObject: Any) -> Void {}
    /**定制错误信息*/
    @objc public func succeed(result: HTTPResult) -> Void {}
}
