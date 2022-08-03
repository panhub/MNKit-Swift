//
//  AHPrivacyController.swift
//  anhe
//
//  Created by 冯盼 on 2022/2/14.
//  用户协议/隐私政策

import UIKit
import WebKit

class TLPrivacyAlertController: TLWebViewController {
    
    // 结束回调
    private var completionHandler: (()->Void)?
    
    private var isHighlighted: Bool = false
    
    private var currentUrl: String {
        isHighlighted ? USER_URL : PRIVACY_URL
    }

    override init() {
        super.init()
        edges = []
        url = currentUrl
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func createView() {
        super.createView()
        
        navigationBar.isHidden = true
        
        view.backgroundColor = .clear
        
        contentView.backgroundColor = .white
        contentView.width = ceil(view.width*0.8)
        contentView.height = ceil(view.height*0.6)
        contentView.layer.cornerRadius = 10.0
        contentView.clipsToBounds = true
        contentView.center = view.Center
        
        let refuseButton = UIButton(type: .custom)
        refuseButton.size = CGSize(width: contentView.width/2.0, height: 50.0)
        refuseButton.maxY = contentView.height
        refuseButton.setTitle("拒绝", for: .normal)
        refuseButton.setTitleColor(.black, for: .normal)
        refuseButton.titleLabel?.font = .systemFont(ofSize: 17.0, weight: .medium)
        refuseButton.contentVerticalAlignment = .center
        refuseButton.contentHorizontalAlignment = .center
        refuseButton.addTarget(self, action: #selector(refuse), for: .touchUpInside)
        contentView.addSubview(refuseButton)
        
        let confirmButton = UIButton(type: .custom)
        confirmButton.frame = refuseButton.frame
        confirmButton.maxX = contentView.width
        confirmButton.setTitle("同意", for: .normal)
        //UIColor(red: 72.0/255.0, green: 122.0/255.0, blue: 245.0/255.0, alpha: 1.0)
        confirmButton.setTitleColor(THEME_COLOR, for: .normal)
        confirmButton.titleLabel?.font = refuseButton.titleLabel?.font
        confirmButton.contentVerticalAlignment = .center
        confirmButton.contentHorizontalAlignment = .center
        confirmButton.addTarget(self, action: #selector(confirm), for: .touchUpInside)
        contentView.addSubview(confirmButton)
        
        let verLine = UIView()
        verLine.width = 0.7
        verLine.height = refuseButton.height
        verLine.maxY = contentView.height
        verLine.midX = contentView.width/2.0
        verLine.backgroundColor = .gray.withAlphaComponent(0.2)
        contentView.addSubview(verLine)
        
        let horLine = UIView()
        horLine.height = 0.7
        horLine.width = contentView.width
        horLine.maxY = refuseButton.minY
        horLine.backgroundColor = .gray.withAlphaComponent(0.2)
        contentView.addSubview(horLine)
        
        let userProtocol: String = "《用户协议》"
        let userProtocolString: String = "您也可以查看\(userProtocol)"
        let userProtocolAttributedString: NSMutableAttributedString = NSMutableAttributedString(string: userProtocolString)
        userProtocolAttributedString.addAttribute(.font, value: UIFont.systemFont(ofSize: 16.0), range: NSRange(location: 0, length: userProtocolString.count))
        userProtocolAttributedString.addAttribute(.foregroundColor, value: UIColor.black, range: NSRange(location: 0, length: userProtocolString.count))
        userProtocolAttributedString.addAttribute(.font, value: UIFont.systemFont(ofSize: 16.0, weight: .medium), range: (userProtocolString as NSString).range(of: userProtocol))
        userProtocolAttributedString.addAttribute(.foregroundColor, value: THEME_COLOR, range: (userProtocolString as NSString).range(of: userProtocol))
        
        let privacyProtocol: String = "《隐私政策》"
        let privacyProtocolString: String = "您也可以查看\(privacyProtocol)"
        let privacyProtocolAttributedString: NSMutableAttributedString = NSMutableAttributedString(string: privacyProtocolString)
        privacyProtocolAttributedString.addAttribute(.font, value: UIFont.systemFont(ofSize: 16.0), range: NSRange(location: 0, length: privacyProtocolString.count))
        privacyProtocolAttributedString.addAttribute(.foregroundColor, value: UIColor.black, range: NSRange(location: 0, length: privacyProtocolString.count))
        privacyProtocolAttributedString.addAttribute(.font, value: UIFont.systemFont(ofSize: 16.0, weight: .medium), range: (privacyProtocolString as NSString).range(of: privacyProtocol))
        privacyProtocolAttributedString.addAttribute(.foregroundColor, value: THEME_COLOR, range: (privacyProtocolString as NSString).range(of: privacyProtocol))
        
        let toggleButton = UIButton(type: .custom)
        toggleButton.size = CGSize(width: contentView.width, height: refuseButton.height)
        toggleButton.maxY = horLine.minY
        toggleButton.setAttributedTitle(userProtocolAttributedString, for: .normal)
        toggleButton.setAttributedTitle(privacyProtocolAttributedString, for: .selected)
        toggleButton.contentVerticalAlignment = .center
        toggleButton.contentHorizontalAlignment = .center
        toggleButton.addTarget(self, action: #selector(toggle(_:)), for: .touchUpInside)
        contentView.addSubview(toggleButton)
        
        let line = UIView()
        line.height = 0.7
        line.width = contentView.width
        line.maxY = toggleButton.minY
        line.backgroundColor = .gray.withAlphaComponent(0.2)
        contentView.addSubview(line)
        
        webView.autoresizingMask = []
        webView.width = contentView.width
        webView.height = line.minY
        
        progressView.autoresizingMask = []
        progressView.width = webView.width
    }
    
    static func show(in controller: UIViewController?, completion completionHandler: (()->Void)?) {
        guard TLHelper.helper.isShowPrivacyAlert, let viewController = controller else {
            completionHandler?()
            return
        }
        let vc = TLPrivacyAlertController()
        vc.completionHandler = completionHandler
        viewController.addChild(vc, to: viewController.view)
        vc.contentView.alpha = 0.0
        vc.contentView.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        UIView.animate(withDuration: 0.5, delay: 0.0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1.0, options: .curveEaseInOut) { [weak vc] in
            vc?.contentView.alpha = 1.0
            vc?.contentView.transform = .identity
            vc?.view.backgroundColor = .black.withAlphaComponent(0.45)
        } completion: { _ in }
    }
}

extension TLPrivacyAlertController {
    
    @objc private func refuse() {
        let alert = UIAlertController(title: "提示", message: "若不同意《用户许可》与《隐私政策》, 则无法使用本软件各项功能, 希望理解!", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "不同意并退出", style: .destructive, handler: { _ in
            exit(0)
        }))
        alert.addAction(UIAlertAction(title: "继续阅读", style: .cancel))
        present(alert, animated: true, completion: nil)
    }
    
    @objc private func confirm() {
        TLHelper.helper.isShowPrivacyAlert = false
        UIView.animate(withDuration: 0.5, delay: 0.0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1.0, options: .curveEaseInOut) {
            self.contentView.alpha = 0.0
            self.contentView.transform = CGAffineTransform(scaleX: 1.02, y: 1.02)
            self.view.backgroundColor = .clear
        } completion: { _ in
            self.removeFromParentController()
            self.completionHandler?()
        }
    }
    
    @objc private func toggle(_ button: UIButton) {
        button.isSelected = !button.isSelected
        isHighlighted = button.isSelected
        stop()
        load(url: URL(string: currentUrl))
    }
}

// MARK: - WKNavigatonDelegate
extension TLPrivacyAlertController {
    
    override func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        guard let path = Bundle.main.path(forResource: currentUrl.lastPathComponent, ofType: "html") else { return }
        load(url: URL(fileURLWithPath: path))
    }
}
