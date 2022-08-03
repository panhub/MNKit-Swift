//
//  HTTPPageRequest.swift
//  MNFoundation
//
//  Created by 冯盼 on 2021/8/4.
//  数据请求封装

import Foundation

public class HTTPPageRequest: HTTPDataRequest {
    /**数据源*/
    public var dataArray: [Any] = [Any]()
    /**是否还有更多数据*/
    public var hasMore: Bool = false
    /**页数*/
    public var page: Int = 1
    /**是否允许分页*/
    public var isPagingEnabled: Bool = false
    /**是否空数据*/
    public var isEmpty: Bool { dataArray.count <= 0 }
    
    /**处理POST数据体*/
    public func handBody() {}
    
    /**处理请求参数*/
    public func handQuery() {}
    
    /**处理请求头*/
    public func handHeaderField() {}
    
    /**即将刷新数据*/
    public func prepareReload() {
        if isPagingEnabled {
            page = 1
        }
    }
    
    /**清理缓存*/
    public func cleanCache() {
        dataArray.removeAll()
    }
    
    /**处理成功*/
    public override func succeed(responseObject: Any) {
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
