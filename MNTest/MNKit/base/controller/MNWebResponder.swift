//
//  MNWebResponder.swift
//  MNFoundation
//
//  Created by 冯盼 on 2021/9/6.
//  提供默认的事件响应

import UIKit

/**退出*/
let MNWebViewExitScriptMessageName: String = "exit"
/**返回*/
let MNWebViewBackScriptMessageName: String = "back"
/**刷新*/
let MNWebViewReloadScriptMessageName: String = "reload"

class MNWebResponder: NSObject {
    // 加载它的网页控制器
    weak var webViewController: MNWebViewController!
}

extension MNWebResponder: MNWebScriptBridge {
    
    var cmds: [String] {
        [MNWebViewExitScriptMessageName, MNWebViewBackScriptMessageName, MNWebViewReloadScriptMessageName]
    }

    func call(cmd: String, body: Any) {
        if cmd == MNWebViewExitScriptMessageName {
            webViewController?.close()
        } else if cmd == MNWebViewBackScriptMessageName {
            webViewController?.back()
        } else {
            webViewController?.reload()
        }
    }
}
