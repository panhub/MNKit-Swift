//
//  TLHomeViewController.swift
//  TLChat
//
//  Created by 冯盼 on 2022/7/21.
//  首页-翻译

import UIKit

class TLHomeViewController: MNExtendViewController {
    /// 输入框
    private let textField: UITextField = UITextField()
    /// 自定义导航栏高度
    override var navigationBarHeight: CGFloat { MN_NAV_BAR_HEIGHT + 10.0 }
    /// 源语种
    private lazy var from: TLLanguageView = {
        let view = TLLanguageView(frame: CGRect(x: 0.0, y: 0.0, width: 0.0, height: 23.0))
        view.mode = .from
        view.language = TLLanguage.auto
        return view
    }()
    /// 翻译目标语种
    private lazy var to: TLLanguageView = {
        let view = TLLanguageView(frame: CGRect(x: 0.0, y: 0.0, width: 0.0, height: 23.0))
        view.mode = .to
        view.language = TLLanguage.english
        return view
    }()
    
    override init() {
        super.init()
        title = "翻译"
        edges = []
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        navigationBar.translucent = false
        navigationBar.backgroundColor = VIEW_COLOR
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
        
        let convertButton = UIButton(type: .custom)
        convertButton.setBackgroundImage(UIImage(named: "translate-badge"), for: .normal)
        convertButton.height = 22.0
        convertButton.sizeFitToHeight()
        convertButton.midX = scrollView.width/2.0
        convertButton.adjustsImageWhenHighlighted = false
        convertButton.addTarget(self, action: #selector(convertButtonTouchUpInside), for: .touchUpInside)
        scrollView.addSubview(convertButton)
        
        from.minY = navigationBar.maxY + 5.0
        from.maxX = convertButton.minX - 10.0
        scrollView.addSubview(from)
        
        to.minY = from.minY
        to.minX = convertButton.maxX + 10.0
        scrollView.addSubview(to)
        
        convertButton.midY = from.midY
        
        let image: UIImage = UIImage(named: "regist-input-bg")!
        let inputView: UIImageView = UIImageView(image: image.stretchableImage(withLeftCapWidth: Int(image.size.width/2.0), topCapHeight: Int(image.size.height/2.0)))
        inputView.height = 65.0
        inputView.width = contentView.width - navigationBar.leftBarItem.minX*2.0
        inputView.midX = contentView.width/2.0
        inputView.minY = from.maxY + 23.0
        inputView.contentMode = .scaleToFill
        inputView.isUserInteractionEnabled = true
        scrollView.addSubview(inputView)
        
        // 搜索框
        textField.frame = inputView.bounds
        textField.delegate = self
        textField.font = .systemFont(ofSize: 18.0)
        textField.textColor = UIColor(red: 0.18, green: 0.22, blue: 0.36, alpha: 1.0)
        textField.backgroundColor = .clear
        textField.borderStyle = .none
        textField.clearButtonMode = .never
        textField.keyboardType = .default
        textField.returnKeyType = .done
        textField.contentVerticalAlignment = .center
        textField.contentHorizontalAlignment = .center
        textField.tintColor = UIColor(r: 69.0, g: 94.0, b: 229.0, a: 1.0)
        textField.attributedPlaceholder = NSAttributedString(string: "请输入要翻译的内容", attributes: [.font:textField.font!, .foregroundColor: textField.textColor!])
        let leftView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: 48.0, height: textField.height))
        let search = UIImageView(image: UIImage(named: "home-search"))
        search.size = CGSize(width: 18.0, height: 18.0)
        search.midY = leftView.height/2.0
        search.maxX = leftView.width - 8.0
        search.contentMode = .scaleAspectFit
        leftView.addSubview(search)
        textField.leftView = leftView
        textField.leftViewMode = .always
        textField.rightView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: 30.0, height: textField.height))
        textField.rightViewMode = .always
        textField.addTarget(self, action: #selector(textDidChange(_:)), for: .editingChanged)
        inputView.addSubview(textField)
        
        let texts: [String] = ["拍照翻译", "语音翻译"]
        let imgs: [String] = ["home-camera", "home-voice"]
        let m: CGFloat = 10.0
        let x: CGFloat = inputView.minX
        let y: CGFloat = inputView.maxY + 23.0
        let w: CGFloat = floor((inputView.width - CGFloat(texts.count - 1)*m)/CGFloat(texts.count))
        let h: CGFloat = ceil(w*0.75)
        UIView.grid(rect: CGRect(x: x, y: y, width: w, height: h), offset: UIOffset(horizontal: m, vertical: 0.0), count: texts.count, column: texts.count) { idx, rect, _ in
            
            let control = UIControl(frame: rect)
            scrollView.addSubview(control)
            
            let image: UIImage = UIImage(named: "home-button-bg")!
            let bg = UIImageView(frame: control.bounds)
            bg.contentMode = .scaleToFill
            bg.image = image.stretchableImage(withLeftCapWidth: Int(image.size.width/2.0), topCapHeight: Int(image.size.height/2.0))
            bg.isUserInteractionEnabled = false
            control.addSubview(bg)
            
            let imageView = UIImageView(image: UIImage(named: imgs[idx]))
            imageView.width = 38.0
            imageView.sizeFitToWidth()
            imageView.isUserInteractionEnabled = false
            control.addSubview(imageView)
            
            let label = UILabel()
            label.numberOfLines = 1
            label.text = texts[idx]
            label.textAlignment = .center
            label.font = .systemFont(ofSize: 17.0, weight: .regular)
            label.textColor = UIColor(red: 0.18, green: 0.22, blue: 0.36, alpha: 1.0)
            label.sizeToFit()
            label.width = ceil(label.width)
            label.height = ceil(label.height)
            label.isUserInteractionEnabled = false
            control.addSubview(label)
            
            imageView.midX = control.width/2.0
            imageView.minY = (control.height - imageView.height - label.height - 10.0)/2.0
            label.midX = imageView.midX
            label.minY = imageView.maxY + 10.0
        }
        
        // 欢迎
        let welcomeView = UIImageView(image: UIImage(named: "home-welcome"))
        welcomeView.minY = y + h + 23.0
        welcomeView.minX = inputView.minX
        welcomeView.width = inputView.width
        welcomeView.sizeFitToWidth()
        scrollView.addSubview(welcomeView)
        
        for (idx, text) in ["欢迎来到私密翻译君！", "Welcome to private translator Jun!"].enumerated() {
            
            let label = UILabel()
            label.numberOfLines = 1
            label.text = text
            label.textAlignment = .center
            label.font = .systemFont(ofSize: 16.0, weight: .regular)
            label.textColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
            label.sizeToFit()
            label.width = ceil(label.width)
            label.height = ceil(label.height)
            label.minX = 18.0
            label.minY = (welcomeView.height - label.height*2.0)/3.0
            if idx != 0 {
                label.maxY = welcomeView.height - label.minY
            }
            label.isUserInteractionEnabled = false
            welcomeView.addSubview(label)
            
            let imageView = UIImageView(image: UIImage(named: "home-voice-badge"))
            imageView.height = label.font!.pointSize
            imageView.sizeFitToHeight()
            imageView.maxX = welcomeView.width - label.minX
            imageView.midY = label.midY
            welcomeView.addSubview(imageView)
        }
        
        // 底部问题
        let issueView = UIView(frame: CGRect(x: inputView.minX, y: welcomeView.maxY + 23.0, width: inputView.width, height: 100.0))
        issueView.backgroundColor = UIColor(red: 0.91, green: 0.91, blue: 0.91, alpha: 1.0)
        issueView.layer.cornerRadius = floor(issueView.height/3.0)
        issueView.clipsToBounds = true
        scrollView.addSubview(issueView)
        
        var contentSize = scrollView.frame.size
        contentSize.height = max(issueView.maxY + max(MN_TAB_SAFE_HEIGHT, 25.0), contentSize.height)
        scrollView.contentSize = contentSize
        
        if TLHelper.helper.isShowHomeCourse {
            let courseView = TLHomeCourseView(frame: view.bounds)
            courseView.layout(rect: scrollView.convert(inputView.frame, to: view))
            view.addSubview(courseView)
        }
    }
}

// MARK: - UITextFieldDelegate
extension TLHomeViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        if let text = textField.text, text.count > 0 {
            // 翻译
        }
        return false
    }
}

// MARK: - Event
private extension TLHomeViewController {
    
    @objc func convertButtonTouchUpInside() {
        guard from.language.code != "auto" else { return }
        let language = from.language
        from.language = to.language
        to.language = language
    }
    
    /// 监听文字变化
    /// - Parameter textField: 输入框
    @objc func textDidChange(_ textField: UITextField) {
        if let _ = textField.markedTextRange {
            // 候选文字变化
        } else if let text = textField.text, text.count == PASSCODE_COUNT, text.isAllNumber {
            // 输入密码
            textField.resignFirstResponder()
            view.isUserInteractionEnabled = false
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.3) { [weak self] in
                self?.view.isUserInteractionEnabled = true
                NotificationCenter.default.post(name: .beginChatNotificationName, object: self, userInfo: [KEY_CHAT_ID:"0000000"])
            }
        }
    }
}

// MARK: - Navigation
extension TLHomeViewController {
    
    override func navigationBarShouldCreateLeftBarItem() -> UIView? {
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.textColor = .black
        titleLabel.numberOfLines = 1
        titleLabel.textAlignment = .center
        titleLabel.font = .systemFont(ofSize: 26.0, weight: .medium)
        titleLabel.sizeToFit()
        titleLabel.width = ceil(titleLabel.width)
        titleLabel.height = titleLabel.font!.pointSize
        return titleLabel
    }
    
    override func navigationBarShouldCreateRightBarItem() -> UIView? {
        let rightBarButton = UIButton(type: .custom)
        rightBarButton.size = CGSize(width: 40.0, height: 40.0)
        rightBarButton.clipsToBounds = true
        rightBarButton.layer.cornerRadius = rightBarButton.height/2.0
        rightBarButton.setBackgroundImage(UIImage(named: "home-avatar"), for: .normal)
        rightBarButton.adjustsImageWhenHighlighted = false
        rightBarButton.addTarget(self, action: #selector(navigationBarRightBarItemTouchUpInside(_:)), for: .touchUpInside)
        return rightBarButton
    }
    
    override func navigationBarDidCreatedBarItems(_ navigationBar: MNNavigationBar) {
        navigationBar.titleLabel.isHidden = true
        navigationBar.leftBarItem.maxY = navigationBar.height - 10.0 - (max(navigationBar.leftBarItem.height, navigationBar.rightBarItem.height) - navigationBar.leftBarItem.height)/2.0
        navigationBar.rightBarItem.midY = navigationBar.leftBarItem.midY
    }
    
    override func navigationBarRightBarItemTouchUpInside(_ rightBarItem: UIView!) {
        present(TLNavigationController(rootViewController: TLRegistViewController()), animated: true)
    }
}
