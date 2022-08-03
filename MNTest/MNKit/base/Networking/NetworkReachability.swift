//
//  NetworkReachability.swift
//  MNFoundation
//
//  Created by 冯盼 on 2021/8/27.
//  网络可达性检测<可达性并不保证数据包一定会被主机接收到>

import Foundation
import CoreTelephony
import SystemConfiguration
import CoreAudio

/**网络监测通知*/
public extension Notification.Name {
    static let networkReachabilityNotificationName = Notification.Name("com.mn.network.reachability.notification.name")
}

// 定义网络状态
@objc public enum NetworkStatus: Int {
    case none // 不可达
    case wwan // 基带网络
    case wifi // "Wi-Fi"
}

// 定义广域网状态
@objc public enum NetworkType: Int {
    case unknown
    case wwan2g
    case wwan3g
    case wwan4g
    case wwan5g
}

public class NetworkReachability: NSObject {
    // 内部检测实例
    private var reachability: SCNetworkReachability?
    // 外界快速获取实例
    @objc public static let reachability: NetworkReachability = NetworkReachability()
    // 是否在检测
    @objc public private(set) var isRunning: Bool = false
    // 网络信息
    private let networkInfo = CTTelephonyNetworkInfo()
    // 检测回调队列
    private static let Queue = DispatchQueue(label: "com.mn.net.reachability")
    // 检测事件回调 主线程
    @objc public var updateHandler: ((NetworkStatus)->Void)?
    // 获取广域网状态标识
    private lazy var technologys: [String: NetworkType] = {
        var technologys: [String: NetworkType] = [String: NetworkType]()
        technologys[CTRadioAccessTechnologyGPRS] = .wwan2g
        technologys[CTRadioAccessTechnologyEdge] = .wwan2g
        technologys[CTRadioAccessTechnologyWCDMA] = .wwan3g
        technologys[CTRadioAccessTechnologyHSDPA] = .wwan3g
        technologys[CTRadioAccessTechnologyHSUPA] = .wwan3g
        technologys[CTRadioAccessTechnologyCDMA1x] = .wwan3g
        technologys[CTRadioAccessTechnologyCDMAEVDORev0] = .wwan3g
        technologys[CTRadioAccessTechnologyCDMAEVDORevA] = .wwan3g
        technologys[CTRadioAccessTechnologyCDMAEVDORevB] = .wwan3g
        technologys[CTRadioAccessTechnologyeHRPD] = .wwan3g
        technologys[CTRadioAccessTechnologyLTE] = .wwan4g
        if #available(iOS 14.1, *) {
            technologys[CTRadioAccessTechnologyNRNSA] = .wwan5g
            technologys[CTRadioAccessTechnologyNR] = .wwan5g
        }
        return technologys
    }()
    // 网络状态变化回调
    private lazy var reachabilityCallBack: SCNetworkReachabilityCallBack = { _, _, context in
        // 通知状态变化
        guard let context = context else { return }
        guard let target = Unmanaged<AnyObject>.fromOpaque(context).takeUnretainedValue() as? NetworkReachability else { return }
        let status = target.status
        DispatchQueue.main.async { [weak target] in
            guard let target = target else { return }
            target.updateHandler?(status)
            NotificationCenter.default.post(name: .networkReachabilityNotificationName, object: target)
        }
    }
    
    deinit { stop() }
    
    public override init() {
        super.init()
        var addr_in: sockaddr_in = sockaddr_in()
        bzero(&addr_in, MemoryLayout.size(ofValue: addr_in))
        addr_in.sin_len = __uint8_t(MemoryLayout.size(ofValue: addr_in))
        addr_in.sin_family = sa_family_t(AF_INET)
        guard let reachability = withUnsafePointer(to: &addr_in, {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                SCNetworkReachabilityCreateWithAddress(kCFAllocatorDefault, $0)
            }
        }) else { return }
        self.reachability = reachability
    }
    
    @objc init(reachability: SCNetworkReachability) {
        super.init()
        self.reachability = reachability
    }
    
    @objc convenience init?(hostname: String) {
        guard let chars = hostname.cString(using: .utf8) else { return nil }
        guard let reachability = SCNetworkReachabilityCreateWithName(nil, chars) else { return nil }
        self.init(reachability: reachability)
    }
    
    @objc convenience init?(address: sockaddr) {
        var addr = address
        guard let reachability = SCNetworkReachabilityCreateWithAddress(kCFAllocatorDefault, &addr) else { return nil }
        self.init(reachability: reachability)
    }
    
    @objc public func start() {
        guard isRunning == false, let reachability = reachability else { return }
        var context = SCNetworkReachabilityContext()
        context.info = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        guard SCNetworkReachabilitySetCallback(reachability, reachabilityCallBack, &context) else {
            #if DEBUG
            print("SCNetworkReachabilitySetCallback() failed: \(SCErrorString(SCError()))")
            #endif
            return
        }
        guard SCNetworkReachabilitySetDispatchQueue(reachability, NetworkReachability.Queue) else {
            SCNetworkReachabilitySetCallback(reachability, nil, nil)
            #if DEBUG
            print("SCNetworkReachabilitySetDispatchQueue() failed: \(SCErrorString(SCError()))")
            #endif
            return
        }
        isRunning = true
    }
    
    @objc public func stop() {
        guard isRunning, let reachability = reachability else { return }
        isRunning = false
        SCNetworkReachabilitySetCallback(reachability, nil, nil)
        SCNetworkReachabilitySetDispatchQueue(reachability, nil)
    }
}

// MARK: - 网络状态
public extension NetworkReachability {
    // 是否可达
    @objc var isReachable: Bool { status != .none }
    // 是否是Wifi
    @objc var isReachableWifi: Bool { status == .wifi }
    // 是否是无线广域网
    @objc var isReachableWWAN: Bool { status == .wwan }
    // 当前网络状态
    @objc var status: NetworkStatus {
        guard let reachability = reachability else { return .none }
        var flags: SCNetworkReachabilityFlags = []
        guard SCNetworkReachabilityGetFlags(reachability, &flags) else { return .none }
        return status(flags: flags)
    }
    // NetworkType -> String
    @objc func string(status: NetworkStatus) -> String {
        ["", "WWAN", "Wi-Fi"][status.rawValue]
    }
    
    private func status(flags: SCNetworkReachabilityFlags) -> NetworkStatus {
        // 无法连接网络
        guard flags.contains(.reachable) else { return .none }
        if flags.contains(.interventionRequired) { return .none } //|| flags.contains(.transientConnection)
        if flags.contains(.isWWAN) {
            #if arch(i386) || arch(x86_64)
            // 模拟器
            #else
            return .wwan
            #endif
        }
        return .wifi
    }
}

// MARK: - 无线广域网类型
public extension NetworkReachability {
    // 当前广域网状态
    @objc var type: NetworkType {
        guard isReachableWWAN else { return .unknown }
        var type: NetworkType = .unknown
        if #available(iOS 12.1, *) {
            if let values = networkInfo.serviceCurrentRadioAccessTechnology?.values {
                for technology in values {
                    if let value = technologys[technology] {
                        type = value
                        break
                    }
                }
            }
        } else {
            if let technology = networkInfo.currentRadioAccessTechnology, let value = technologys[technology] {
                type = value
            }
        }
        return type
    }
    
    // NetworkType -> String
    @objc func string(type: NetworkType) -> String {
        ["", "2G", "3G", "4G", "5G"][type.rawValue]
    }
}

// MARK: - DEBUG
public extension NetworkReachability {
    
    @objc var statusString: String {
        string(status: status)
    }
    
    @objc var typeString: String {
        string(type: type)
    }
    
    override var debugDescription: String {
        "status:\(statusString) type:\(typeString)"
    }
}
