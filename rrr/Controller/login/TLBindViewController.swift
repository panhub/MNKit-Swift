//
//  TLBindViewController.swift
//  TLChat
//
//  Created by 冯盼 on 2022/7/22.
//  绑定成功

import UIKit

class TLBindViewController: MNExtendViewController {
    /// 注册信息
    private var profile: TLProfile
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
        titleLabel.text = "成功绑定账号"
        titleLabel.textColor = .black
        titleLabel.textAlignment = .center
        titleLabel.font = UIFont.systemFont(ofSize: 25.0, weight: .medium)
        titleLabel.sizeToFit()
        titleLabel.width = ceil(titleLabel.width)
        titleLabel.height = ceil(titleLabel.height)
        titleLabel.midX = scrollView.width/2.0
        titleLabel.minY = navigationBar.maxY + 5.0
        scrollView.addSubview(titleLabel)
        
        let subtitleLabel = UILabel()
        subtitleLabel.numberOfLines = 1
        subtitleLabel.text = "您已开通\(profile.count)个聊天号"
        subtitleLabel.textColor = UIColor(red: 0.77, green: 0.78, blue: 0.82, alpha: 1.0)
        subtitleLabel.textAlignment = .center
        subtitleLabel.font = UIFont.systemFont(ofSize: 17.0, weight: .medium)
        subtitleLabel.sizeToFit()
        subtitleLabel.width = ceil(subtitleLabel.width)
        subtitleLabel.height = ceil(subtitleLabel.height)
        subtitleLabel.midX = titleLabel.midX
        subtitleLabel.minY = titleLabel.maxY + 13.0
        scrollView.addSubview(subtitleLabel)
        
        let idView = UIView(frame: CGRect(x: MN_NAV_ITEM_MARGIN, y: subtitleLabel.maxY + 25.0, width: scrollView.width - MN_NAV_ITEM_MARGIN*2.0, height: 60.0))
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
        
        let userView = UIView(frame: CGRect(x: idView.minX, y: idView.maxY - idView.layer.cornerRadius, width: idView.width, height: 95.0))
        userView.backgroundColor = UIColor(red: 0.9, green: 0.89, blue: 0.98, alpha: 1.0)
        userView.layer.mask(radius: idView.layer.cornerRadius, corners: [.bottomLeft, .bottomRight])
        scrollView.insertSubview(userView, belowSubview: idView)
        
        let avatarView = UIImageView(frame: CGRect(x: 0.0, y: 0.0, width: 55.0, height: 55.0))
        avatarView.minX = 17.0
        avatarView.midY = (userView.height - idView.layer.cornerRadius)/2.0 + idView.layer.cornerRadius
        avatarView.clipsToBounds = true
        avatarView.layer.borderWidth = 1.5
        avatarView.layer.cornerRadius = avatarView.height/2.0
        avatarView.layer.borderColor = UIColor(r: 247.0, g: 242.0, b: 230.0, a: 1.0).cgColor
        avatarView.image = UIImage(named: "profile-avatar")
        userView.addSubview(avatarView)
        
        let vipView = UIImageView(image: UIImage(named: "bind-no-vip"))
        vipView.height = 28.0
        vipView.sizeFitToHeight()
        vipView.maxX = userView.width - avatarView.minX
        vipView.midY = avatarView.midY
        userView.addSubview(vipView)
        
        let nickLabel = UILabel()
        nickLabel.numberOfLines = 1
        nickLabel.textAlignment = .center
        nickLabel.textColor = .black
        nickLabel.font = .systemFont(ofSize: 17.0, weight: .medium)
        nickLabel.text = profile.nickname
        nickLabel.sizeToFit()
        nickLabel.width = ceil(nickLabel.width)
        nickLabel.height = ceil(nickLabel.height)
        nickLabel.minX = avatarView.maxX + 8.0
        nickLabel.midY = avatarView.midY
        nickLabel.width = min(nickLabel.width, vipView.minX - nickLabel.minX - 8.0)
        userView.addSubview(nickLabel)
        
        let courseView = UIImageView(image: UIImage(named: "bind-course"))
        courseView.minX = idView.minX
        courseView.minY = userView.maxY + 23.0
        courseView.width = idView.width
        courseView.sizeFitToWidth()
        scrollView.addSubview(courseView)
        
        let style = NSMutableParagraphStyle()
        style.lineSpacing = 2.0
        style.alignment = .center
        let string = NSMutableAttributedString(string: "在翻译界面输入该账号下的\n任一聊天号密码, 即可登录该聊天号")
        string.addAttribute(.foregroundColor, value: UIColor(red: 0.76, green: 0.78, blue: 0.77, alpha: 1.0), range: string.rangeOfAll)
        string.addAttribute(.font, value: UIFont.systemFont(ofSize: 14.0, weight: .regular), range: string.rangeOfAll)
        string.addAttribute(.paragraphStyle, value: style, range: string.rangeOfAll)
        let hintLabel = UILabel()
        hintLabel.numberOfLines = 0
        hintLabel.attributedText = string
        hintLabel.textAlignment = .center
        hintLabel.sizeToFit()
        hintLabel.width = ceil(hintLabel.width)
        hintLabel.height = ceil(hintLabel.height)
        hintLabel.midX = scrollView.width/2.0
        hintLabel.minY = courseView.maxY + 20.0
        scrollView.addSubview(hintLabel)
        
        let loginButton = UIButton(type: .custom)
        loginButton.frame = CGRect(x: idView.minX, y: hintLabel.maxY + 20.0, width: idView.width, height: 55.0)
        loginButton.titleLabel?.font = .systemFont(ofSize: 17.0, weight: .medium)
        loginButton.setTitle("去\(DISPLAY_NAME)登录", for: .normal)
        loginButton.setTitleColor(.black, for: .normal)
        loginButton.layer.cornerRadius = floor(loginButton.height/3.0)
        loginButton.clipsToBounds = true
        loginButton.setBackgroundImage(UIImage(color: UIColor(r: 100.0, g: 237.0, b: 193.0, a: 1.0)), for: .normal)
        loginButton.addTarget(self, action: #selector(login), for: .touchUpInside)
        scrollView.addSubview(loginButton)
        
        var contentSize = scrollView.frame.size
        contentSize.height = max(loginButton.maxY + max(MN_TAB_SAFE_HEIGHT, 25.0), contentSize.height)
        scrollView.contentSize = contentSize
    }
}

// MARK: - Event
private extension TLBindViewController {
    
    /// 登录
    @objc func login() {
        navigationController?.dismiss(animated: true)
    }
}

// MARK: - Navigation
extension TLBindViewController {
    
    override func navigationBarShouldCreateLeftBarItem() -> UIView? {
        let leftBarButton = UIButton(type: .custom)
        leftBarButton.size = CGSize(width: 25.0, height: 25.0)
        leftBarButton.setBackgroundImage(UIImage(named: "back"), for: .normal)
        leftBarButton.addTarget(self, action: #selector(navigationBarLeftBarItemTouchUpInside(_:)), for: .touchUpInside)
        return leftBarButton
    }
}
