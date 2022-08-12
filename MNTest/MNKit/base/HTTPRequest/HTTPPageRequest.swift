//
//  HTTPPageRequest.swift
//  MNFoundation
//
//  Created by 冯盼 on 2021/8/4.
//  数据请求封装

import Foundation

@objc public class HTTPPageRequest: HTTPDataRequest {
    /**数据源*/
    @objc public var dataArray: [Any] = [Any]()
    /**是否还有更多数据*/
    @objc public var hasMore: Bool = false
    /**页数*/
    @objc public var page: Int = 1
    /**是否允许分页*/
    @objc public var isPagingEnabled: Bool = false
    /**是否空数据*/
    @objc public var isEmpty: Bool { dataArray.count <= 0 }
    
    /**处理POST数据体*/
    @objc public func handBody() {}
    
    /**处理请求参数*/
    @objc public func handQuery() {}
    
    /**处理请求头*/
    @objc public func handHeaderField() {}
    
    /**即将刷新数据*/
    @objc public func prepareReload() {
        if isPagingEnabled {
            page = 1
        }
    }
    
    /**清理缓存*/
    @objc public func cleanCache() {
        dataArray.removeAll()
    }
    
    /**处理成功*/
    @objc public override func succeed(responseObject: Any) {
        if isPagingEnabled {
            if page == 1 {
                cleanCache()
            }
        } else {
            cleanCache()
        }
    }
    
    /**重写请求*/
    public override func load(start: HTTPRequestStartHandler? = nil, completion: HTTPRequestCompletionHandler? = nil) {
        handQuery()
        if method == .post { handBody() }
        handHeaderField()
        super.load(start: start, completion: completion)
    }
}
