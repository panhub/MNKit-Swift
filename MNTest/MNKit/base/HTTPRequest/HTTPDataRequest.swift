//
//  HTTPDataRequest.swift
//  MNFoundation
//
//  Created by 冯盼 on 2021/8/1.
//  数据请求者

import Foundation

@objc public class HTTPDataRequest: HTTPRequest {
    /**数据来源*/
    @objc public enum DataSource: Int {
        case network // 网络数据
        case cache // 本地缓存
    }
    /**缓存策略*/
    @objc public enum CachePolicy: Int {
        case never // 不使用缓存
        case local // 先读取缓存 失败后再请求
        case remote // 先请求 失败后再读取缓存
    }
    /**请求方式*/
    @objc public enum RequestMethod: Int {
        case get, post, head, delete
    }
    /**POST数据体 非上传数据*/
    @objc public var body: Any?
    /**最大的重试次数 失败时依此重新请求 NSURLErrorCancelled 无效*/
    @objc public var retryCount: UInt = 0
    /**重试间隔 默认立即重试*/
    @objc public var retryTimeInterval: TimeInterval = 0.0
    /**请求方式*/
    @objc public var method: RequestMethod = .get
    /**数据来源*/
    @objc public var source: DataSource = .network
    /**缓存策略*/
    @objc public var cachePolicy: CachePolicy = .never
    /**是否删除数据中的null*/
    @objc var removeNullValues: Bool = false
    /**缓存时间以秒为单位 默认无限期*/
    @objc public var cacheTimeInterval: Int = 0
    /**缓存的key 支持定制*/
    @objc public var cacheForKey: String { url }
    /**请求产生的Task*/
    @objc public var dataTask: URLSessionDataTask? { task as? URLSessionDataTask }
    
    /**开始请求*/
    @objc public func load(start: HTTPRequestStartHandler? = nil, completion: HTTPRequestCompletionHandler? = nil) -> Void {
        startHandler = start
        finishHandler = completion
        resume()
    }

    public override func finish(result: Result<Any, HTTPError>) {
        // 判断是否需要读取缓存
        let httpResult = HTTPResult(result: result)
        httpResult.request = self
        if result.isSuccess == false, method == .get, cachePolicy == .remote, let cache = HTTPManager.default.database.cache(key: cacheForKey, out: cacheTimeInterval) {
            source = .cache
            httpResult.data = cache
        }
        // 定制自己的结果
        if httpResult.isSuccess {
            succeed(result: httpResult)
        }
        // 依据结果回调
        if httpResult.isSuccess {
            // 判断是否缓存结果
            let responseObject = httpResult.data!
            if method == .get, source == .network, cachePolicy != .never {
                if HTTPManager.default.database.setCache(responseObject, forKey: cacheForKey) {
                    #if DEBUG
                    print("已缓存数据")
                    #endif
                }
            }
            // 回调成功函数
            succeed(responseObject: responseObject)
        }
        // 回调结果
        (queue ?? DispatchQueue.main).async {
            // 回调结果
            self.finishHandler?(httpResult)
        }
    }
}
