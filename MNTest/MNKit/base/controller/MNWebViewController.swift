//
//  MNWebViewController.swift
//  MNFoundation
//
//  Created by 冯盼 on 2021/8/7.
//  网页解决方案

import UIKit
import WebKit

/**WebView加载事件*/
@objc protocol MNWebControllerDelegate: NSObjectProtocol {
    @objc optional func webViewControllerDidStart(_ webViewController: MNWebViewController) -> Void
    @objc optional func webViewControllerWillFinish(_ webViewController: MNWebViewController) -> Void
    @objc optional func webViewControllerDidFinish(_ webViewController: MNWebViewController) -> Void
    @objc optional func webViewController(_ webViewController: MNWebViewController, didFailLoad error: Error) -> Void
}

// 标题监听Key
let MNWebViewObserveTitleKey: String = "title"
// 进度监听Key
let MNWebViewObserveProgressKey: String = "estimatedProgress"

class MNWebViewController: MNExtendViewController {
    /**链接*/
    var url: MNURLConvertible?
    /**静态网页 优先级高于url*/
    @objc var html: String?
    /**关闭按钮*/
    private(set) var closeButton: UIButton!
    /**刷新按钮*/
    private(set) var reloadButton: UIButton!
    /**网页控件*/
    private(set) var webView: WKWebView!
    /**交互代理*/
    private let userContentController = MNUserContentController()
    /**加载事件代理*/
    @objc weak var delegate: MNWebControllerDelegate?
    /**进度条*/
    private(set) var progressView: MNWebProgressView!
    /**是否在显示时刷新网页*/
    @objc var reloadWhenAppear: Bool = false
    /**是否允许刷新标题*/
    @objc var isAllowsUpdateTitle: Bool = true
    
    override init() {
        super.init()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    public init(url: MNURLConvertible?) {
        super.init()
        self.url = url
    }
    
    @objc convenience init(string: String) {
        self.init(url: string)
    }
    
    public convenience init(html: String, baseURL: URL? = nil) {
        self.init(url: baseURL)
        self.html = html
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        webView?.removeObserver(self, forKeyPath: MNWebViewObserveTitleKey)
        webView?.removeObserver(self, forKeyPath: MNWebViewObserveProgressKey)
    }
    
    override func initialized() {
        super.initialized()
        addScript(responder: MNWebResponder())
    }
    
    override func createView() {
        super.createView()
        
        let userContentController = WKUserContentController()
        
        let configuration = WKWebViewConfiguration()
        configuration.userContentController = userContentController
        for script in self.userContentController.responders.keys {
            userContentController.add(self.userContentController, name: script)
        }
        webView = WKWebView(frame: contentView.bounds, configuration: configuration)
        webView.uiDelegate = self
        webView.navigationDelegate = self
        webView.backgroundColor = contentView.backgroundColor
        webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        if #available(iOS 11.0, *) {
            webView.scrollView.contentInsetAdjustmentBehavior = .never;
        }
        webView.addObserver(self, forKeyPath: MNWebViewObserveTitleKey, options: .new, context: nil)
        webView.addObserver(self, forKeyPath: MNWebViewObserveProgressKey, options: .new, context: nil)
        contentView.addSubview(webView)
        
        progressView = MNWebProgressView(frame: CGRect(x: 0.0, y: 0.0, width: webView.bounds.width, height: 2.50))
        contentView.addSubview(progressView)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        if let _ = html {
            webView.loadHTMLString(html!, baseURL: url?.urlValue)
        } else if let URL = url?.urlValue {
            load(url: URL)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if isFirstAppear == false, reloadWhenAppear {
            reload()
        }
    }
    
    // 加载指定URL
    func load(url: URL?) -> Void {
        guard let u = url else { return }
        guard let request = request(for: u) else { return }
        webView.stopLoading()
        webView.load(request)
    }
    
    // 定制请求
    func request(for url: URL) -> URLRequest? {
        return URLRequest(url: url)
    }
    
    // 网页内部返回
    func goBack() -> Bool {
        guard webView.canGoBack else { return false }
        stop()
        closeButton?.isHidden = false
        webView.goBack()
        return true
    }
    
    // 停止加载
    func stop() -> Void {
        guard webView.isLoading else { return }
        reloadButton?.layer.pauseAnimation()
        webView.stopLoading()
    }
    
    // 重载
    @objc func reload() -> Void {
        stop()
        webView.reload()
    }
    
    // 空数据视图按钮点击
    override func reloadData() {
        reload()
    }
    
    // 监听标题/进度信息
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if let kPath = keyPath {
            if kPath == MNWebViewObserveTitleKey {
                if isAllowsUpdateTitle {
                    title = webView.title
                }
            } else if kPath == MNWebViewObserveProgressKey {
                progressView.set(progress: webView.estimatedProgress, animated: true)
            } else {
                super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
            }
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
}

// MARK: - 导航
extension MNWebViewController {
    override func navigationBarShouldDrawBackBarItem() -> Bool { false }
    /**创建返回/关闭按钮*/
    override func navigationBarShouldCreateLeftBarItem() -> UIView? {
        let leftItemView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: 62.0, height: 22.0))
        let backButton = UIButton(type: .custom)
        backButton.size = CGSize(width: leftItemView.height, height: leftItemView.height)
        backButton.setBackgroundImage(UIImage(unicode: .back, color: .black, size: leftItemView.height), for: .normal)
        backButton.setBackgroundImage(UIImage(unicode: .back, color: .black, size: leftItemView.height), for: .highlighted)
        backButton.addTarget(self, action: #selector(back), for: .touchUpInside)
        leftItemView.addSubview(backButton)
        closeButton = UIButton(type: .custom)
        closeButton.isHidden = true
        closeButton.size = CGSize(width: 20.0, height: 20.0)
        closeButton.maxX = leftItemView.width
        closeButton.midY = leftItemView.height/2.0
        closeButton.setBackgroundImage(UIImage(unicode: .close, color: .black, size: leftItemView.height), for: .normal)
        closeButton.setBackgroundImage(UIImage(unicode: .close, color: .black, size: leftItemView.height), for: .highlighted)
        closeButton.addTarget(self, action: #selector(close), for: .touchUpInside)
        leftItemView.addSubview(closeButton)
        return leftItemView
    }
    /**创建刷新按钮*/
    override func navigationBarShouldCreateRightBarItem() -> UIView? {
        reloadButton = UIButton(type: .custom)
        reloadButton.frame = CGRect(x: 0.0, y: 0.0, width: 23.0, height: 23.0)
        reloadButton.setBackgroundImage(UIImage(unicode: .refresh, color: .black, size: reloadButton.height), for: .normal)
        reloadButton.setBackgroundImage(UIImage(unicode: .refresh, color: .black, size: reloadButton.height), for: .highlighted)
        reloadButton.addTarget(self, action: #selector(reload), for: .touchUpInside)
        let animation = CABasicAnimation(keyPath: "transform.rotation.z")
        animation.duration = 1.0
        animation.toValue = Double.pi*2.0
        animation.beginTime = 0.0
        animation.autoreverses = false
        animation.timingFunction = CAMediaTimingFunction(name: .linear)
        animation.isRemovedOnCompletion = false
        animation.fillMode = .forwards
        animation.repeatCount = Float.greatestFiniteMagnitude
        reloadButton.layer.add(animation, forKey: "rotation")
        reloadButton.layer.pauseAnimation()
        return reloadButton
    }
    
    @objc func back() {
        if goBack() { return }
        super.navigationBarLeftBarItemTouchUpInside(nil)
    }
    
    @objc func close() {
        super.navigationBarLeftBarItemTouchUpInside(nil)
    }
}

// MARK: - WKNavigationDelegate
extension MNWebViewController: WKNavigationDelegate {
    /*开始加载*/
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        reloadButton?.layer.resumeAnimation()
        delegate?.webViewControllerDidStart?(self)
    }
    /*当内容开始到达主帧时被调用(即将完成)*/
    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        delegate?.webViewControllerWillFinish?(self)
    }
    /*加载完成(并非真正的完成, 比如重定向)*/
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        reloadButton?.layer.pauseAnimation()
        delegate?.webViewControllerDidFinish?(self)
    }
    /*加载失败*/
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        if (error as NSError).code == 102, (error as NSError).domain == WKErrorDomain { return }
        reloadButton?.layer.pauseAnimation()
        if (error as NSError).code == NSURLErrorCancelled { return }
        delegate?.webViewController?(self, didFailLoad: error)
    }
    /*在提交的主帧中发生错误时调用*/
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        if (error as NSError).code == 102, (error as NSError).domain == WKErrorDomain { return }
        reloadButton?.layer.pauseAnimation()
        if (error as NSError).code == NSURLErrorCancelled { return }
    }
    /**当webView接受SSL认证挑战*/
    func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        var credential: URLCredential?
        var disposition = URLSession.AuthChallengeDisposition.performDefaultHandling
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust {
            if HTTPSecurityPolicy().evaluate(server: challenge.protectionSpace.serverTrust!, domain: challenge.protectionSpace.host) {
                disposition = .useCredential
                credential = URLCredential(trust: challenge.protectionSpace.serverTrust!)
            } else {
                // 验证失败
                disposition = .cancelAuthenticationChallenge
            }
        }
        completionHandler(disposition, credential)
    }
    /*开始加载后调用(可处理一些简单交互)*/
    /*
    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {}
    */
    /**在请求开始加载之前调用 -- 跳转操作*/
    /*
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {}
    */
    /**接收到服务器重定向时调用*/
    /*
    func webView(_ webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {}
    */
}

// MARK: - WKUIDelegate
extension MNWebViewController: WKUIDelegate {
    /**js脚本需要新webview加载网页*/
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if let targetFrame = navigationAction.targetFrame, targetFrame.isMainFrame == false {
            webView.load(navigationAction.request)
        }
        return nil
    }
    /**输入框 在js中调用prompt函数时,会调用该方法*/
    func webView(_ webView: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String, defaultText: String?, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (String?) -> Void) {
        let alertController = UIAlertController(title: nil, message: prompt, preferredStyle: .alert)
        alertController.addTextField { textField in
            textField.text = defaultText
            textField.placeholder = prompt
            textField.font = UIFont.systemFont(ofSize: 16.0)
        }
        alertController.addAction(UIAlertAction(title: "取消", style: .cancel, handler: { action in
            completionHandler(nil)
            #if DEBUG
            print("取消输入")
            #endif
        }))
        alertController.addAction(UIAlertAction(title: "确定", style: .default, handler: { [weak alertController] action in
            completionHandler(alertController?.textFields?.first?.text)
            #if DEBUG
            print("确定输入")
            #endif
        }))
        present(alertController, animated: true, completion: nil)
    }
    /**确认框 在js中调用confirm函数时,会调用该方法*/
    func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
        let alertController = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "取消", style: .cancel, handler: { action in
            completionHandler(false)
            #if DEBUG
            print("取消输入")
            #endif
        }))
        alertController.addAction(UIAlertAction(title: "确定", style: .default, handler: { action in
            completionHandler(true)
            #if DEBUG
            print("确定")
            #endif
        }))
        present(alertController, animated: true, completion: nil)
    }
    /**警告框 在js中调用alert函数时,会调用该方法*/
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        let alertController = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "确定", style: .default, handler: { action in
            completionHandler()
            #if DEBUG
            print("确定")
            #endif
        }))
        present(alertController, animated: true, completion: nil)
    }
}

// MARK: - 添加脚本
extension MNWebViewController: MNWebScriptAddHandler {
    
    // 添加响应者
    func addScript(responder: MNWebScriptBridge) -> Void {
        if responder is MNWebResponder {
            (responder as! MNWebResponder).webViewController = self
        }
        userContentController.addScript(responder: responder)
    }
}
