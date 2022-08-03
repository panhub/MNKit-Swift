//
//  TLPasscodeViewController.swift
//  TLChat
//
//  Created by 冯盼 on 2022/7/21.
//  设置密码

import UIKit

class TLPasscodeViewController: MNExtendViewController {
    /// 注册信息
    private var profile: TLProfile
    /// 密码输入框
    private var firstTextField: UITextField = UITextField()
    /// 确认密码
    private var lastTextField: UITextField = UITextField()
    /// 自定义导航高度
    override var navigationBarHeight: CGFloat { MN_NAV_BAR_HEIGHT + 10.0 }
    
    init(profile: TLProfile) {
        self.profile = profile
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
        
        let titleLabel = UILabel()
        titleLabel.numberOfLines = 1
        titleLabel.text = "设置密码"
        titleLabel.textColor = .black
        titleLabel.textAlignment = .center
        titleLabel.font = UIFont.systemFont(ofSize: 25.0, weight: .medium)
        titleLabel.sizeToFit()
        titleLabel.width = ceil(titleLabel.width)
        titleLabel.height = ceil(titleLabel.height)
        titleLabel.minX = MN_NAV_ITEM_MARGIN
        titleLabel.minY = navigationBar.maxY + 5.0
        scrollView.addSubview(titleLabel)
        
        let idView = UIView(frame: CGRect(x: MN_NAV_ITEM_MARGIN, y: titleLabel.maxY + 10.0, width: scrollView.width - MN_NAV_ITEM_MARGIN*2.0, height: 60.0))
        idView.clipsToBounds = true
        idView.layer.cornerRadius = floor(idView.height/4.0)
        idView.backgroundColor = UIColor(r: 42.0, g: 49.0, b: 78.0, a: 1.0)
        scrollView.addSubview(idView)
        
        let badgeView = UIImageView(image: UIImage(named: "id-badge"))
        badgeView.width = 20.0
        badgeView.sizeFitToWidth()
        idView.addSubview(badgeView)
        
        let idLabel = UILabel()
        idLabel.text = "聊天号: \(profile.id)"
        idLabel.font = .systemFont(ofSize: 20.0, weight: .medium)
        idLabel.numberOfLines = 1
        idLabel.textColor = UIColor(red: 0.39, green: 0.93, blue: 0.76, alpha: 1)
        idLabel.textAlignment = .center
        idLabel.sizeToFit()
        idLabel.width = ceil(idLabel.width)
        idLabel.height = ceil(idLabel.height)
        idView.addSubview(idLabel)
        
        badgeView.midY = idView.height/2.0
        badgeView.minX = (idView.width - badgeView.width - idLabel.width - 7.0)/2.0
        idLabel.midY = badgeView.midY
        idLabel.minX = badgeView.maxX + 7.0
        
        let m: CGFloat = 18.0
        let y: CGFloat = ceil(idView.maxY) + 30.0
        let x: CGFloat = idView.minX
        let w: CGFloat = idView.width
        let image: UIImage = UIImage(named: "passcode-input-bg")!
        let h: CGFloat = 55.0
        let textFields: [UITextField] = [firstTextField, lastTextField]
        let titles: [String] = ["设置密码:", "重复密码:"]
        let placeholders: [String] = ["请输入\(PASSCODE_COUNT)位数字密码", "请再次输入密码"]
        UIView.grid(rect: CGRect(x: x, y: y, width: w, height: h), offset: UIOffset(horizontal: 0.0, vertical: m), count: titles.count, column: 1) { idx, rect, _ in
            
            let label = UILabel()
            label.numberOfLines = 1
            label.font = .systemFont(ofSize: 17.0, weight: .medium)
            label.textColor = .black
            label.textAlignment = .center
            label.text = titles[idx]
            label.sizeToFit()
            label.width = ceil(label.width)
            label.height = ceil(label.height)
            label.minX = rect.minX
            scrollView.addSubview(label)
            
            let imageView = UIImageView(frame: rect)
            imageView.minX = label.maxX + 10.0
            imageView.width = rect.width - imageView.minX
            imageView.image = image.stretchableImage(withLeftCapWidth: Int(image.size.width/2.0), topCapHeight: Int(image.size.height/2.0))
            imageView.isUserInteractionEnabled = true
            imageView.contentMode = .scaleToFill
            scrollView.addSubview(imageView)
            
            label.midY = imageView.midY
            
            let textField = textFields[idx]
            textField.frame = imageView.bounds
            //textField.delegate = self
            textField.font = .systemFont(ofSize: 17.0, weight: .medium)
            textField.textColor = UIColor(red: 0.18, green: 0.22, blue: 0.36, alpha: 1.0)
            textField.backgroundColor = .clear
            textField.borderStyle = .none
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
        }
        
        let text: String = " 温馨提示:"
        let hint: String = "\(text)\n为确保您的隐私, 密码无法找回请您务必牢记聊天号对应的密码"
        let style = NSMutableParagraphStyle()
        style.lineSpacing = 6.0
        let string = NSMutableAttributedString(string: hint)
        string.addAttribute(.foregroundColor, value: UIColor(red: 0.4, green: 0.4, blue: 0.4, alpha: 1.0), range: string.rangeOfAll)
        string.addAttribute(.foregroundColor, value: UIColor(red: 1.0, green: 0.69, blue: 0.15, alpha: 1.0), range: (hint as NSString).range(of: text))
        string.insert(NSAttributedString(image: UIImage(named: "passcode-hint"), font: .systemFont(ofSize: 13.0), resizing: 0.0), at: 0)
        string.addAttribute(.font, value: UIFont.systemFont(ofSize: 13.0), range: string.rangeOfAll)
        string.addAttribute(.paragraphStyle, value: style, range: string.rangeOfAll)
        let hintLabel = UILabel()
        hintLabel.numberOfLines = 0
        hintLabel.attributedText = string
        hintLabel.size = string.size(width: w)
        hintLabel.width = ceil(hintLabel.width)
        hintLabel.height = ceil(hintLabel.height)
        hintLabel.minX = x
        hintLabel.minY = y + h*2.0 + m + m
        scrollView.addSubview(hintLabel)
        
        let nextButton = UIButton(type: .custom)
        nextButton.frame = CGRect(x: x, y: hintLabel.maxY + ceil(m*1.5), width: w, height: h)
        nextButton.titleLabel?.font = .systemFont(ofSize: 17.0, weight: .medium)
        nextButton.setTitle("下一步", for: .normal)
        nextButton.setTitleColor(.black, for: .normal)
        nextButton.layer.cornerRadius = floor(nextButton.height/3.0)
        nextButton.clipsToBounds = true
        nextButton.setBackgroundImage(UIImage(color: UIColor(r: 100.0, g: 237.0, b: 193.0, a: 1.0)), for: .normal)
        nextButton.addTarget(self, action: #selector(nextButtonTouchUpInside), for: .touchUpInside)
        scrollView.addSubview(nextButton)
        
        var contentSize = scrollView.frame.size
        contentSize.height = max(nextButton.maxY + max(MN_TAB_SAFE_HEIGHT, 25.0), contentSize.height)
        scrollView.contentSize = contentSize
    }
}

// MARK: - Event
private extension TLPasscodeViewController {
    
    @objc func nextButtonTouchUpInside() {
        navigationController?.pushViewController(TLProfileViewController(profile: profile), animated: true)
    }
}

// MARK: - Navigation
extension TLPasscodeViewController {
    
    override func navigationBarShouldCreateLeftBarItem() -> UIView? {
        let leftBarButton = UIButton(type: .custom)
        leftBarButton.size = CGSize(width: 25.0, height: 25.0)
        leftBarButton.setBackgroundImage(UIImage(named: "back"), for: .normal)
        leftBarButton.addTarget(self, action: #selector(navigationBarLeftBarItemTouchUpInside(_:)), for: .touchUpInside)
        return leftBarButton
    }
}
