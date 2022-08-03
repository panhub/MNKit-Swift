//
//  MNWebUserContentController.swift
//  MNFoundation
//
//  Created by 冯盼 on 2021/8/8.
//  脚本交互信息控制

import WebKit
import Foundation

// MARK: - 响应处理
@objc protocol MNWebScriptBridge {
    // 支持的命令
    @objc var cmds: [String] { get }
    // 调用命令
    @objc func call(cmd: String, body: Any) -> Void
}

// MARK: - 添加响应处理
protocol MNWebScriptAddHandler {
    // 添加脚本响应者
    func addScript(responder: MNWebScriptBridge) -> Void
}

public class MNUserContentController: NSObject, MNWebScriptAddHandler {
    /**保存响应者*/
    private(set) var responders: [String:MNWebScriptBridge] = [:]
    /**添加响应者*/
    func addScript(responder: MNWebScriptBridge) -> Void {
        for cmd in responder.cmds {
            responders[cmd] = responder
        }
    }
}

// MARK: - WKScriptMessageHandler
extension MNUserContentController: WKScriptMessageHandler {
    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if let responder = responders[message.name] {
            responder.call(cmd: message.name, body: message.body)
        }
    }
}
