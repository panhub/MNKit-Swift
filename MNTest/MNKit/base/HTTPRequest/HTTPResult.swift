//
//  MNHTTPResult.swift
//  MNFoundation
//
//  Created by 冯盼 on 2021/8/1.
//  网络请求结果

import Foundation

public extension Result where Success == Any, Failure == HTTPError {
    
    /**错误体*/
    var error: HTTPError? {
        switch self {
        case .failure(let error):
            return error
        default:
            return nil
        }
    }
    
    /**错误码*/
    var code: Int {
        switch self {
        case .failure(let error):
            return error.errCode
        default:
            return HTTPResultCode.succeed.rawValue
        }
    }
    
    /**错误信息**/
    var msg: String {
        switch self {
        case .failure(let error):
            return error.errMsg
        default:
            return "success"
        }
    }
    
    var debug: String {
        switch self {
        case .failure(let error):
            return error.debug
        default:
            return "success"
        }
    }
    
    /**请求数据*/
    var data: Any? {
        switch self {
        case .success(let obj):
            return obj
        default:
            return nil
        }
    }
    
    /**是否成功*/
    var isSuccess: Bool {
        switch self {
        case .success(_):
            return true
        default:
            return false
        }
    }
}

@objc enum HTTPResultCode: Int {
    case failed = 0
    case unknown = -1
    case succeed = 1
    case cancelled = -999
    case invalidUrl = -1000
    case timedOut = -1001
    case cannotFindHost = -1003
    case cannotConnectToHost = -1004
    case networkConnectionLost = -1005
    case notConnectedToInternet = -1009
    case cannotDecodeData = -1016
    case cannotParseResponse = -1017
    case cannotWriteToFile = -3003
    case cannotCreateFile = -3000
    case cannotMoveFile = -3005
    case cannotQueryUrl = -1813770
    case cannotEncodeBody = -1813780
    case missingMimeType = -1813790
    case unsupportedContentType = -1813800
    case unsupportedStatusCode = -1813810
    case zeroByteData = -1813820
    case bodyEmpty = -1813840
    case fileExists = -1813850
    // 项目定义
    case noCloudDisk = 121 // 没有磁盘空间
    case cloudDiskIsFull = 122 // 磁盘空间已满
    case notLogin = 401 // 没有登录
    case offline = 402 // 设备掉线
    case imageCodeError = 102 // 图片验证码错误
    case noSecurityQuestion = 103 // 无密码问题
}

@objc public class HTTPResult: NSObject {
    
    /**Swift数据结果**/
    private var result: Result<Any, HTTPError> = .failure(.custom(code: HTTPErrorUnknown, msg: "unknown error"))
    
    /**响应码**/
    @objc var code: HTTPResultCode {
        set {
            if newValue == .succeed {
                if result.isSuccess == false {
                    result = .success(["":""])
                }
            } else {
                result = .failure(.custom(code: newValue.rawValue, msg: result.msg))
            }
        }
        get { HTTPResultCode(rawValue: result.code) ?? .failed }
    }
    
    /**错误信息*/
    @objc var msg: String {
        set { result = .failure(.custom(code: result.code, msg: newValue)) }
        get { result.msg }
    }
    
    /**请求的数据*/
    @objc var data: Any? {
        set {
            if let responseObject = newValue {
                result = .success(responseObject)
            } else {
                result = .failure(.custom(code: HTTPErrorUnknown, msg: "failed"))
            }
        }
        get { result.data }
    }
    
    /**直接获取数据<确定有值时再使用, 仅为了方便>*/
    @objc var obj: Any { data ?? [String:String]() }
    
    /**请求是否成功*/
    @objc var isSuccess: Bool { code == .succeed }
    
    /**测试信息**/
    @objc var debug: String { result.debug }
    
    /**记录请求*/
    @objc weak var request: HTTPRequest?
    
    /**便捷初始化*/
    convenience init(result: Result<Any, HTTPError>) {
        self.init()
        self.result = result
    }
    
    convenience init(responseObject: Any) {
        self.init(result: .success(responseObject))
    }
}
