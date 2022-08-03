//
//  MNNetworking.swift
//  MNFoundation
//
//  Created by 冯盼 on 2021/7/19.
//  请求错误定义

import Foundation

//=== Foundation
/**未知错误*/
public let HTTPErrorUnknown: Int = NSURLErrorUnknown
/**取消 -999*/
public let HTTPErrorCancelled: Int = NSURLErrorCancelled
/**网络中断*/
public let HTTPErrorNetworkConnectionLost: Int = NSURLErrorNetworkConnectionLost
/**无网络连接*/
public let HTTPErrorNotConnectedToInternet: Int = NSURLErrorNotConnectedToInternet
//=== Query
/**链接无效*/
public let HTTPErrorBadUrl: Int = NSURLErrorBadURL
/**链接拼接失败*/
public let HTTPErrorCannotQueryUrl: Int = -1813770
/**请求体编码失败*/
public let HTTPErrorCannotEncodeBody: Int = -1813780
//=== Response
/**无法解析服务端响应体*/
public let HTTPErrorBadServerResponse: Int = NSURLErrorCannotParseResponse
/**未知ContentType*/
public let HTTPErrorMissingContentType: Int = -1813790
/**不接受的ContentType*/
public let HTTPErrorUnsupportedContentType: Int = -1813800
/**不接受的StatusCode*/
public let HTTPErrorUnsupportedStatusCode: Int = -1813810
//=== Parse
/**空数据*/
public let HTTPErrorZeroByteData: Int = -1813820
/**不能解析数据*/
public let HTTPErrorCannotParseData: Int = -1813830
//=== Upload
/**未知上传内容体*/
public let HTTPErrorBodyEmpty: Int = -1813840
//=== Download I/O
/**无法保存到本地<路径错误>*/
public let HTTPErrorCannotWriteToFile: Int = NSURLErrorCannotWriteToFile
/**文件已存在*/
public let HTTPErrorFileExists: Int = -1813850
/**创建文件路径失败*/
public let HTTPErrorCannotCreateFile: Int = NSURLErrorCannotCreateFile
/**移动文件失败*/
public let HTTPErrorCannotMoveFile: Int = NSURLErrorCannotMoveFile

/**错误信息*/
public enum HTTPError: Swift.Error {
    //invalidUrl
    public enum RequestSerializationReason {
        case invalidUrl(String)
        case cannotQueryUrl(String)
        case cannotEncodeBody
    }
    
    public enum ResponseParseReason {
        case cannotParseResponse
        case missingMimeType
        case unsupportedContentType(mimeType: String, accept: Set<String>)
        case unsupportedStatusCode(Int)
        case underlyingError(Error)
    }
    
    public enum DataParseReason {
        case zeroByteData
        case cannotDecodeData
        case underlyingError(Error)
    }
    
    public enum UploadFailureReason {
        case bodyIsEmpty
    }
    
    public enum SSLChallengeReason {
        case underlyingError(Error)
    }

    // I/O
    public enum DownloadFailureReason {
        case cannotWriteToFile
        case fileExists(path: String, error: Error)
        case cannotCreateFile(path: String, error: Error)
        case cannotMoveFile(path: String, error: Error)
    }
    
    case requestSerializationFailure(RequestSerializationReason)
    case responseParseFailure(ResponseParseReason)
    case dataParseFailure(DataParseReason)
    case uploadFailure(UploadFailureReason)
    case downloadFailure(DownloadFailureReason)
    case httpsChallengeFailure(SSLChallengeReason)
    case custom(code: Int, msg: String)
}

public extension Swift.Error {
    var httpError: HTTPError? { self as? HTTPError }
}

public extension HTTPError {
    
    var errCode: Int {
        switch self {
        case .requestSerializationFailure(let reason):
            return reason.errCode
        case .responseParseFailure(let reason):
            return reason.errCode
        case .dataParseFailure(let reason):
            return reason.errCode
        case .uploadFailure(let reason):
            return reason.errCode
        case .downloadFailure(let reason):
            return reason.errCode
        case .httpsChallengeFailure(let reason):
            return reason.errCode
        case .custom(let code, _):
            return code
        }
    }
    
    // 错误信息
    var errMsg: String {
        switch self {
        case .requestSerializationFailure(let reason):
             return reason.errMsg
        case .responseParseFailure(let reason):
             return reason.errMsg
        case .dataParseFailure(let reason):
            return reason.errMsg
        case .uploadFailure(let reason):
            return reason.errMsg
        case .downloadFailure(let reason):
            return reason.errMsg
        case .httpsChallengeFailure(let reason):
            return reason.errMsg
        case .custom(code: _, msg: let desc):
            return desc
        }
    }
    
    // 测试输入
    var debug: String {
        switch self {
        case .requestSerializationFailure(let reason):
             return reason.debug
        case .responseParseFailure(let reason):
             return reason.debug
        case .dataParseFailure(let reason):
            return reason.debug
        case .uploadFailure(let reason):
            return reason.debug
        case .downloadFailure(let reason):
            return reason.debug
        case .httpsChallengeFailure(let reason):
            return reason.debug
        case .custom(let code, let msg):
            return "custom code:\(code) msg:\(msg)"
        }
    }
    
    // 底层错误信息
    var underlyingError: Error? {
        switch self {
        case .requestSerializationFailure(let reason):
            return reason.underlyingError
        case .responseParseFailure(let reason):
            return reason.underlyingError
        case .dataParseFailure(let reason):
            return reason.underlyingError
        case .uploadFailure(let reason):
            return reason.underlyingError
        case .downloadFailure(let reason):
            return reason.underlyingError
        case .httpsChallengeFailure(let reason):
            return reason.underlyingError
        default:
            return nil
        }
    }
    
    // 是否是取消带来的错误
    var isCancelled: Bool { errCode == HTTPErrorCancelled }
    
    // 是否是请求编码时的错误
    var isQueryError: Bool {
        switch self {
        case .requestSerializationFailure(_):
            return true
        default:
            return false
        }
    }
    
    // 是否是数据解析错误
    var isParseError: Bool {
        switch self {
        case .dataParseFailure(_):
            return true
        default:
            return false
        }
    }
}

public extension HTTPError.RequestSerializationReason {
    
    var errCode: Int {
        switch self {
        case .invalidUrl(_):
            return HTTPErrorBadUrl
        case .cannotQueryUrl(_):
            return HTTPErrorCannotQueryUrl
        case .cannotEncodeBody:
            return HTTPErrorCannotEncodeBody
        }
    }
    
    var errMsg: String {
        switch self {
        case .cannotQueryUrl(_):
            return "请求地址编码失败"
        case .invalidUrl(url: _):
            return "请求地址无效"
        case .cannotEncodeBody:
            return "数据编码失败"
        }
    }
    
    var debug: String {
        switch self {
        case .cannotQueryUrl(let url):
            return "错误的请求地址=\(url)"
        case .invalidUrl(let url):
            return "无效的请求地址=\(url)"
        case .cannotEncodeBody:
            return "请求体编码失败"
        }
    }
    
    var underlyingError: Error? { nil }
}

public extension HTTPError.ResponseParseReason {
    
    var errCode: Int {
        switch self {
        case .cannotParseResponse:
            return HTTPErrorBadServerResponse
        case .missingMimeType:
            return HTTPErrorMissingContentType
        case .unsupportedContentType( _, _):
            return HTTPErrorUnsupportedContentType
        case .unsupportedStatusCode(_):
            return HTTPErrorUnsupportedStatusCode
        case .underlyingError(let error):
            return (error as NSError).code
        }
    }
    
    var errMsg: String {
        switch self {
        case .cannotParseResponse:
            return "无效的响应者"
        case .missingMimeType:
            return "未知MIME"
        case .unsupportedContentType(_, _):
            return "MIME错误"
        case .unsupportedStatusCode(_):
            return "响应错误"
        case .underlyingError(let error):
            return error.localizedDescription
        }
    }
    
    var debug: String {
        switch self {
        case .cannotParseResponse:
            return "无效的响应者"
        case .missingMimeType:
            return "未知ContentType"
        case .unsupportedContentType(let mimeType, let accept):
            return "不接受ContentType mimeType:\(mimeType) accept:\(accept)"
        case .unsupportedStatusCode(let code):
            return "响应码错误 code: \(code)"
        case .underlyingError(let error):
            return (error as NSError).localizedFailureReason ?? error.localizedDescription
        }
    }
    
    var underlyingError: Error? {
        switch self {
        case .underlyingError(let error):
            return error
        default:
            return nil
        }
    }
}

public extension HTTPError.DataParseReason {
    
    var errCode: Int {
        switch self {
        case .zeroByteData:
            return HTTPErrorZeroByteData
        case .cannotDecodeData:
            return HTTPErrorCannotParseData
        case .underlyingError(let error):
            return (error as NSError).code
        }
    }
    
    var errMsg: String {
        switch self {
        case .zeroByteData:
            return "数据为空"
        case .cannotDecodeData:
            return "数据解析失败"
        case .underlyingError(let error):
            return error.localizedDescription
        }
    }
    
    var debug: String {
        switch self {
        case .zeroByteData:
            return "数据为空"
        case .cannotDecodeData:
            return "数据解析失败"
        case .underlyingError(let error):
            return (error as NSError).localizedFailureReason ?? error.localizedDescription
        }
    }
    
    var underlyingError: Error? {
        switch self {
        case .underlyingError(let error):
            return error
        default:
            return nil
        }
    }
}

public extension HTTPError.UploadFailureReason {
    
    var errCode: Int { HTTPErrorBodyEmpty }
    
    var errMsg: String {
        switch self {
        case .bodyIsEmpty:
            return "未知上传内容"
        }
    }
    
    var debug: String {
        switch self {
        case .bodyIsEmpty:
            return "body is empty"
        }
    }
    
    var underlyingError: Error? { nil }
}

public extension HTTPError.DownloadFailureReason {
    
    var errCode: Int {
        switch self {
        case .cannotWriteToFile:
            return HTTPErrorCannotWriteToFile
        case .fileExists(_, _):
            return HTTPErrorFileExists
        case .cannotCreateFile(_, _):
            return HTTPErrorCannotCreateFile
        case .cannotMoveFile(_, _):
            return HTTPErrorCannotMoveFile
        }
    }
    
    var errMsg: String {
        switch self {
        case .cannotWriteToFile:
            return "未知文件下载位置"
        case .fileExists(path: _, error: _):
            return "文件已存在"
        case .cannotCreateFile(path: _, error: _):
            return "创建目录失败"
        case .cannotMoveFile(path: _, error: _):
            return "文件移动失败"
        }
    }
    
    var debug: String {
        switch self {
        case .cannotWriteToFile:
            return "未知文件下载位置"
        case .fileExists(let path, let error):
            return "旧文件删除失败 path:\(path) error:\(error)"
        case .cannotCreateFile(let path, let error):
            return "创建目录失败 path:\(path) error:\(error)"
        case .cannotMoveFile(let path, let error):
            return "文件移动失败 path:\(path) error:\(error)"
        }
    }
    
    var underlyingError: Error? {
        switch self {
        case .cannotCreateFile(_, let error), .cannotMoveFile(_, let error), .fileExists(_, let error):
            return error
        default:
            return nil
        }
    }
}

public extension HTTPError.SSLChallengeReason {
    
    var errCode: Int {
        switch self {
        case .underlyingError(let error):
            return (error as NSError).code
        }
    }
    
    var errMsg: String {
        switch self {
        case .underlyingError(let error):
            return error.localizedDescription
        }
    }
    
    var underlyingError: Error? {
        switch self {
        case .underlyingError(let error):
            return error
        }
    }
    
    var debug: String {
        switch self {
        case .underlyingError(let error):
            return "HTTPS挑战失败 error:\(error)"
        }
    }
}
