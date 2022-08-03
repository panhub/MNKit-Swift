//
//  MNHTTPTrustPolicy.swift
//  MNFoundation
//
//  Created by 冯盼 on 2021/7/29.
//  HTTPS信任策略

import UIKit
import Security
import CoreFoundation

public class HTTPSecurityPolicy {
    /**验证模式*/
    public enum Mode {
        case none //不验证
        case publicKey // 验证公钥
        case certificate // 验证证书
    }
    /**默认验证实例*/
    public static var `default`: HTTPSecurityPolicy = HTTPSecurityPolicy()
    /**验证模式*/
    public var mode: Mode = .none
    /**是否验证域名*/
    public var isValidateDomainName: Bool = true
    /**是否信任带有无效或过期SSL证书的服务器, 不建议开启*/
    public var isAllowsInvalidCertificate: Bool = false
    /**证书缓存 */
    private var publicKeys: [SecKey] = [SecKey]()
    /**本地锚点证书*/
    private var _certificates: Set<Data>?
    public var certificates: Set<Data>? {
        get { _certificates }
        set {
            _certificates = newValue
            publicKeys.removeAll()
            guard let items = newValue else { return }
            for certificateData in items {
                guard let publicKey = MNPublicKeyForCertificate(certificateData) else { continue }
                publicKeys.append(publicKey)
            }
        }
    }
    
    public init(mode: HTTPSecurityPolicy.Mode = .none, certificates: Set<Data>? = nil) {
        self.mode = mode
        self.certificates = certificates
    }
    
    public static func certificates(in bundle: Bundle?) -> Set<Data>? {
        let paths = (bundle ?? Bundle.main).paths(forResourcesOfType: "cer", inDirectory: ".")
        var certificates: Set<Data> = Set<Data>()
        for path in paths {
            guard let certificateData = try? Data(contentsOf: URL(fileURLWithPath: path)) else { continue }
            certificates.insert(certificateData)
        }
        return (certificates.count > 0 ? certificates : nil)
    }
    
    public func evaluate(server trust: SecTrust, for domain: String? = nil) -> Bool {
        //因为要验证域名, 所以必须不能是MNTrustModeNone或者添加到项目里的证书为0个
        if let _ = domain, isValidateDomainName, isAllowsInvalidCertificate, (mode == .none || (certificates?.count ?? 0) <= 0) { return false }
        // 定义验证策略
        var policies: [SecPolicy] = [SecPolicy]()
        if isValidateDomainName {
            // 如果需要验证domain, 那么就使用SecPolicyCreateSSL函数创建验证策略, 其中第一个参数为true表示验证整个SSL证书链, 第二个参数传入domain, 用于判断整个证书链上叶子节点表示的那个domain是否和此处传入domain一致
            if let _ = domain {
                policies.append(SecPolicyCreateSSL(true, domain! as CFString))
            } else {
                policies.append(SecPolicyCreateSSL(true, nil))
            }
        } else {
            // 如果不需要验证domain, 就使用默认的BasicX509验证策略
            policies.append(SecPolicyCreateBasicX509())
        }
        // 为serverTrust设置验证策略, 即告诉客户端如何验证serverTrust
        SecTrustSetPolicies(trust, policies as CFArray)
        // 有验证策略了, 可以去验证了, 如果是None, 是自签名, 直接返回可信任, 否则不是自签名的就去系统根证书里去找是否有匹配的证书
        if mode == .none {
            // 如果支持无效证书, 直接返回YES, 不允许才去判断第二个条件, 判断serverTrust是否有效
            return (isAllowsInvalidCertificate || MNServerTrustIsValid(trust))
        } else if isAllowsInvalidCertificate == false, MNServerTrustIsValid(trust) == false {
            // 如果验证无效, 而且allowInvalidCertificates不允许无效证书通过
            return false
        }
        switch mode {
        case .certificate:
            // 验证证书链
            // 把证书data, 用系统api转成 SecCertificateRef类型的数据
            // SecCertificateCreateWithData函数对原先的certificates做一些处理, 保证返回的证书都是DER编码的X.509证书
            var anchorCertificates: [SecCertificate] = [SecCertificate]()
            guard let items = certificates else { return isAllowsInvalidCertificate }
            for certificateData in items {
                if let cer = SecCertificateCreateWithData(nil, certificateData as CFData) {
                    anchorCertificates.append(cer)
                }
            }
            // 将anchorCertificates设置成需要参与验证的Anchor Certificate(锚点证书: 通过SecTrustSetAnchorCertificates设置了参与校验锚点证书之后, 假如验证的数字证书是这个锚点证书的子节点, 即验证的数字证书是由锚点证书对应CA或子CA签发的, 或是该证书本身, 则信任该证书), 具体就是调用SecTrustEvaluate来验证.
            SecTrustSetAnchorCertificates(trust, anchorCertificates as CFArray)
            //再去调用之前的serverTrust去验证该证书是否有效, 有可能,经过这个方法过滤后, serverTrust里面的anchorCertificates被筛选到只有信任的那一个证书
            guard MNServerTrustIsValid(trust) else { return false }
            //注意, 这个方法和我们之前的锚点证书没关系了, 验证证书链;
            //服务器端的证书链, 注意此处返回的证书链顺序是从叶节点到根节点;
            if let trustChain = MNCertificateTrustChainForServerTrust(trust) {
                for certificateData in trustChain.reversed() {
                    if items.contains(certificateData) {
                        return true
                    }
                }
            }
        case .publicKey:
            if let trustedPublicKeys = MNPublicKeyTrustChainForServerTrust(trust) {
                for key in trustedPublicKeys {
                    for key2 in publicKeys {
                        guard MNPublicKeyIsEqualToKey(key, publicKey2: key2) else { continue }
                        return true
                    }
                }
            }
        default:
            return false
        }
        
        return false
    }
}

// 获取证书公钥
private func MNPublicKeyForCertificate(_ certificateData: Data) -> SecKey? {
    
    guard let certificate = SecCertificateCreateWithData(nil, certificateData as CFData) else { return nil }
    
    var trust: SecTrust?
    guard SecTrustCreateWithCertificates(certificate, SecPolicyCreateBasicX509(), &trust) == errSecSuccess else { return nil }
    guard let trust = trust else { return nil }
    
    if #available(iOS 12.0, *) {
        var error: CFError?
        guard SecTrustEvaluateWithError(trust, &error) else { return nil }
    } else {
        var result: SecTrustResultType = .invalid
        guard SecTrustEvaluate(trust, &result) == errSecSuccess else { return nil }
    }
    
    if #available(iOS 14.0, *) {
        return SecTrustCopyKey(trust)
    } else {
        return SecTrustCopyPublicKey(trust)
    }
}

// 验证证书是否合法
private func MNServerTrustIsValid(_ serverTrust: SecTrust) -> Bool {
    if #available(iOS 12.0, *) {
        var error: CFError?
        guard SecTrustEvaluateWithError(serverTrust, &error) else { return false }
        return error == nil
    } else {
        var result: SecTrustResultType = .invalid
        guard SecTrustEvaluate(serverTrust, &result) == errSecSuccess else { return false }
        return (result == .unspecified || result == .proceed)
    }
}

// 获取证书链
private func MNCertificateTrustChainForServerTrust(_ serverTrust: SecTrust) -> [Data]? {
    var result: [Data] = [Data]()
    if #available(iOS 15.0, *) {
        guard let chain = SecTrustCopyCertificateChain(serverTrust) else { return nil }
        let count = CFArrayGetCount(chain)
        for index in 0..<count {
            let certificate = Unmanaged<SecCertificate>.fromOpaque(CFArrayGetValueAtIndex(chain, index)).takeUnretainedValue()
            result.append(SecCertificateCopyData(certificate) as Data)
        }
    } else {
        let count = SecTrustGetCertificateCount(serverTrust)
        for index in 0..<count {
            if let certificate = SecTrustGetCertificateAtIndex(serverTrust, index as CFIndex) {
                result.append(SecCertificateCopyData(certificate) as Data)
            }
        }
    }
    return (result.count > 0 ? result : nil)
}

// 获取证书公钥链
private func MNPublicKeyTrustChainForServerTrust(_ serverTrust: SecTrust) -> [SecKey]? {
    var trustChain: [SecKey] = [SecKey]()
    let policy = SecPolicyCreateBasicX509();
    let certificateCount = SecTrustGetCertificateCount(serverTrust)
    for index in 0..<certificateCount {
        if let certificate = SecTrustGetCertificateAtIndex(serverTrust, index as CFIndex) {
            var trust: SecTrust?
            guard SecTrustCreateWithCertificates(certificate, policy, &trust) == errSecSuccess else { continue }
            var result: SecTrustResultType = .invalid
            guard SecTrustEvaluate(trust!, &result) == errSecSuccess else { continue }
            guard let publicKey = SecTrustCopyPublicKey(trust!) else { continue }
            trustChain.append(publicKey)
        }
    }
    return (trustChain.count > 0 ? trustChain : nil)
}

// 比较公钥
private func MNPublicKeyIsEqualToKey(_ publicKey1: SecKey, publicKey2: SecKey) -> Bool {
    return publicKey1 == publicKey2
}
