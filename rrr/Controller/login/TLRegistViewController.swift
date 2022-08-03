//
//  TLRegistViewController.swift
//  TLChat
//
//  Created by 冯盼 on 2022/7/21.
//  注册聊天号

import UIKit

class TLRegistViewController: MNExtendViewController {
    /// 手机号码
    private var firstTextField: UITextField = UITextField()
    /// 验证码
    private var lastTextField: UITextField = UITextField()
    /// 发送验证码
    private var sendButton: UIButton = UIButton(type: .custom)
    /// 同意协议弹窗
    private var agreeBox: UIButton = UIButton(type: .custom)
    /// 自定义导航栏高度
    override var navigationBarHeight: CGFloat { MN_NAV_BAR_HEIGHT + 10.0 }
    
    override init() {
        super.init()
        edges = []
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        navigationBar.translucent = false
        navigationBar.backgroundColor = .clear
        navigationBar.shadowView.isHidden = true
        
        contentView.backgroundColor = VIEW_COLOR
        
        let scrollView = UIScrollView(frame: contentView.bounds)
        scrollView.backgroundColor = contentView.backgroundColor
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.neverAdjustmentBehavior()
        scrollView.alwaysBounceVertical = true
        scrollView.keyboardDismissMode = .onDrag
        contentView.addSubview(scrollView)
        
        let bg: UIImage = UIImage(named: "view-bg")!
        let headerView = MNAdsorbHeader(frame: CGRect(x: 0.0, y: 0.0, width: scrollView.width, height: 0.0))
        headerView.imageView.image = bg
        headerView.height = ceil(bg.size.height/bg.size.width*headerView.width)
        scrollView.addSubview(headerView)
        
        var style = NSMutableParagraphStyle()
        style.lineSpacing = 7.0
        var string = NSMutableAttributedString(string: "首次使用\n请绑定聊天号")
        string.addAttribute(.foregroundColor, value: UIColor.black, range: string.rangeOfAll)
        string.addAttribute(.font, value: UIFont.systemFont(ofSize: 25.0, weight: .medium), range: string.rangeOfAll)
        string.addAttribute(.paragraphStyle, value: style, range: string.rangeOfAll)
        let titleLabel = UILabel()
        titleLabel.numberOfLines = 0
        titleLabel.attributedText = string
        titleLabel.sizeToFit()
        titleLabel.width = ceil(titleLabel.width)
        titleLabel.height = ceil(titleLabel.height)
        titleLabel.minX = MN_NAV_ITEM_MARGIN
        titleLabel.minY = navigationBar.maxY + 5.0
        scrollView.addSubview(titleLabel)
        
        let m: CGFloat = 18.0
        let y: CGFloat = ceil(titleLabel.maxY) + 35.0
        let x: CGFloat = MN_NAV_ITEM_MARGIN
        let w: CGFloat = scrollView.width - x*2.0
        let image: UIImage = UIImage(named: "regist-input-bg")!
        let h: CGFloat = 55.0//floor(image.size.height/image.size.width*w)
        let placeholders: [String] = ["请输入手机号", "请输入验证码"]
        let textFields: [UITextField] = [firstTextField, lastTextField]
        UIView.grid(rect: CGRect(x: x, y: y, width: w, height: h), offset: UIOffset(horizontal: 0.0, vertical: m), count: placeholders.count, column: 1) { idx, rect, _ in
            
            let imageView = UIImageView(frame: rect)
            imageView.image = image.stretchableImage(withLeftCapWidth: Int(image.size.width/2.0), topCapHeight: Int(image.size.height/2.0))
            imageView.isUserInteractionEnabled = true
            imageView.contentMode = .scaleToFill
            scrollView.addSubview(imageView)
            
            let textField = textFields[idx]
            textField.frame = imageView.bounds
            //textField.delegate = self
            textField.font = .systemFont(ofSize: 17.0, weight: .medium)
            textField.textColor = UIColor(red: 0.18, green: 0.22, blue: 0.36, alpha: 1.0)
            textField.borderStyle = .none
            textField.backgroundColor = .clear
            textField.clearButtonMode = .never
            textField.keyboardType = .numberPad
            textField.contentVerticalAlignment = .center
            textField.contentHorizontalAlignment = .center
            textField.tintColor = UIColor(red: 0.39, green: 0.93, blue: 0.76, alpha: 1.0)
            textField.attributedPlaceholder = NSAttributedString(string: placeholders[idx], attributes: [.font:UIFont.systemFont(ofSize: 17.0, weight: .medium), .foregroundColor: UIColor(red: 0.77, green: 0.78, blue: 0.82, alpha: 1.0)])
            textField.leftView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: 25.0, height: textField.height))
            textField.leftViewMode = .always
            textField.rightView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: 25.0, height: textField.height))
            textField.rightViewMode = .always
            imageView.addSubview(textField)
            
            if idx != 0 {
                sendButton.titleLabel?.font = .systemFont(ofSize: 16.0, weight: .regular)
                sendButton.setTitle("发送验证码", for: .normal)
                sendButton.setTitleColor(UIColor(red: 0.39, green: 0.93, blue: 0.76, alpha: 1.0), for: .normal)
                sendButton.setTitleColor(UIColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1.0), for: .disabled)
                sendButton.contentVerticalAlignment = .center
                sendButton.contentHorizontalAlignment = .center
                sendButton.sizeToFit()
                sendButton.width = ceil(sendButton.width)
                sendButton.height = imageView.height
                sendButton.maxX = imageView.width - textField.leftView!.width
                sendButton.midY = imageView.height/2.0
                sendButton.addTarget(self, action: #selector(sendButtonTouchUpInside(_:)), for: .touchUpInside)
                imageView.addSubview(sendButton)
                textField.width = sendButton.minX
            }
        }
        
        let agreeLabel = UILabel()
        agreeLabel.numberOfLines = 1
        agreeLabel.text = "我已阅读并同意"
        agreeLabel.textColor = UIColor(red: 0.4, green: 0.4, blue: 0.4, alpha: 1.0)
        agreeLabel.font = .systemFont(ofSize: 14.0, weight: .regular)
        agreeLabel.textAlignment = .center
        agreeLabel.sizeToFit()
        agreeLabel.width = ceil(agreeLabel.width)
        agreeLabel.height = ceil(agreeLabel.height)
        scrollView.addSubview(agreeLabel)
        
        let registProtocol = UIButton(type: .custom)
        registProtocol.setAttributedTitle(NSAttributedString(string: "《注册协议》", attributes: [.font:agreeLabel.font!, .foregroundColor:UIColor(red: 0.16, green: 0.19, blue: 0.31,alpha:1.0)]), for: .normal)
        registProtocol.sizeToFit()
        registProtocol.width = ceil(registProtocol.width)
        registProtocol.height = ceil(registProtocol.height)
        registProtocol.addTarget(self, action: #selector(registProtocolTouchUpInside), for: .touchUpInside)
        scrollView.addSubview(registProtocol)
        
        let privacyProtocol = UIButton(type: .custom)
        privacyProtocol.setAttributedTitle(NSAttributedString(string: "《隐私协议》", attributes: [.font:agreeLabel.font!, .foregroundColor:UIColor(red: 0.16, green: 0.19, blue: 0.31,alpha:1.0)]), for: .normal)
        privacyProtocol.sizeToFit()
        privacyProtocol.width = ceil(privacyProtocol.width)
        privacyProtocol.height = ceil(privacyProtocol.height)
        privacyProtocol.addTarget(self, action: #selector(privacyProtocolTouchUpInside), for: .touchUpInside)
        scrollView.addSubview(privacyProtocol)
        
        agreeBox.width = agreeLabel.height
        agreeBox.height = agreeBox.width
        agreeBox.adjustsImageWhenHighlighted = false
        agreeBox.setBackgroundImage(UIImage(named: "regist-agree"), for: .normal)
        agreeBox.setBackgroundImage(UIImage(named: "regist-agree-selected"), for: .selected)
        agreeBox.addTarget(self, action: #selector(agree(_:)), for: .touchUpInside)
        scrollView.addSubview(agreeBox)
        
        agreeBox.minY = y + h*2.0 + m + m
        agreeBox.minX = (scrollView.width - agreeBox.width - agreeLabel.width - registProtocol.width - privacyProtocol.width - 5.0)/2.0
        agreeLabel.midY = agreeBox.midY
        agreeLabel.minX = agreeBox.maxX + 5.0
        registProtocol.midY = agreeBox.midY
        registProtocol.minX = agreeLabel.maxX
        privacyProtocol.midY = agreeBox.midY
        privacyProtocol.minX = registProtocol.maxX
        
        let ensureButton = UIButton(type: .custom)
        ensureButton.frame = CGRect(x: x, y: agreeBox.maxY + 50.0, width: w, height: h)
        ensureButton.titleLabel?.font = .systemFont(ofSize: 17.0, weight: .medium)
        ensureButton.setTitle("确定", for: .normal)
        ensureButton.setTitleColor(.black, for: .normal)
        ensureButton.layer.cornerRadius = floor(ensureButton.height/3.0)
        ensureButton.clipsToBounds = true
        ensureButton.setBackgroundImage(UIImage(color: UIColor(r: 100.0, g: 237.0, b: 193.0, a: 1.0)), for: .normal)
        ensureButton.addTarget(self, action: #selector(ensure), for: .touchUpInside)
        scrollView.addSubview(ensureButton)
        
        style = NSMutableParagraphStyle()
        style.lineSpacing = 2.0
        style.alignment = .center
        string = NSMutableAttributedString(string: "如果你的手机号开通了多个聊天号\n请使用聊天号对应的密码登录")
        string.addAttribute(.foregroundColor, value: UIColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1.0), range: string.rangeOfAll)
        string.addAttribute(.font, value: UIFont.systemFont(ofSize: 13.0, weight: .regular), range: string.rangeOfAll)
        string.addAttribute(.paragraphStyle, value: style, range: string.rangeOfAll)
        let hintLabel = UILabel()
        hintLabel.numberOfLines = 0
        hintLabel.attributedText = string
        hintLabel.textAlignment = .center
        hintLabel.sizeToFit()
        hintLabel.midX = scrollView.width/2.0
        hintLabel.maxY = scrollView.height - max(MN_TAB_SAFE_HEIGHT, 23.0)
        scrollView.addSubview(hintLabel)
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

// MARK: - Event
private extension TLRegistViewController {
    
    @objc func agree(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
    }
    
    @objc func registProtocolTouchUpInside() {
        let vc = TLWebViewController(url: USER_URL)
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc func privacyProtocolTouchUpInside() {
        let vc = TLWebViewController(url: PRIVACY_URL)
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc func sendButtonTouchUpInside(_ sender: UIButton) {
        
    }
    
    @objc func ensure() {
        
        view.endEditing(true)
        
        let profile: TLProfile = TLProfile(id: "525623200")
        navigationController?.pushViewController(TLPasscodeViewController(profile: profile), animated: true)
        
        return
        
        guard agreeBox.isSelected else {
            view.showMsgToast("请仔细阅读并同意\n《注册协议》《隐私协议》")
            return
        }
        
        guard let phone = firstTextField.text, phone.count > 0 else {
            view.showMsgToast(firstTextField.attributedPlaceholder!.string)
            return
        }
        
        guard let code = lastTextField.text, code.count > 0 else {
            view.showMsgToast(lastTextField.attributedPlaceholder!.string)
            return
        }
    }
}

// MARK: - Navigation
extension TLRegistViewController {
    
    override func navigationBarShouldCreateLeftBarItem() -> UIView? {
        let leftBarButton = UIButton(type: .custom)
        leftBarButton.size = CGSize(width: 25.0, height: 25.0)
        leftBarButton.setBackgroundImage(UIImage(named: "back"), for: .normal)
        leftBarButton.addTarget(self, action: #selector(navigationBarLeftBarItemTouchUpInside(_:)), for: .touchUpInside)
        return leftBarButton
    }
}
