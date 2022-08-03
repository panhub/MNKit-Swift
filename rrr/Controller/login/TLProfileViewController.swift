//
//  TLProfileViewController.swift
//  TLChat
//
//  Created by 冯盼 on 2022/7/22.
//  设置头像/昵称

import UIKit

class TLProfileViewController: MNExtendViewController {
    /// 注册信息
    private var profile: TLProfile
    /// 昵称
    private let textField: UITextField = UITextField()
    /// 头像
    private let avatarButton: UIButton = UIButton(type: .custom)
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
        titleLabel.text = "设置聊天号的头像和昵称"
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
        let image: UIImage = UIImage(named: "profile-input-bg")!
        let h: CGFloat = 55.0
        let titles: [String] = ["头像:", "昵称:"]
        let placeholders: [String] = ["", "请输入昵称"]
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
            
            if idx == 0 {
                // 头像
                avatarButton.size = CGSize(width: rect.height, height: rect.height)
                avatarButton.midY = rect.midY
                avatarButton.minX = label.maxX + 10.0
                avatarButton.clipsToBounds = true
                avatarButton.layer.cornerRadius = avatarButton.height/2.0
                avatarButton.setBackgroundImage(UIImage(named: "profile-avatar"), for: .normal)
                avatarButton.adjustsImageWhenHighlighted = true
                avatarButton.addTarget(self, action: #selector(avatarButtonTouchUpInside(_:)), for: .touchUpInside)
                scrollView.addSubview(avatarButton)
                label.midY = avatarButton.midY
            } else {
                // 昵称
                let imageView = UIImageView(frame: rect)
                imageView.minX = label.maxX + 10.0
                imageView.width = rect.width - imageView.minX
                imageView.image = image.stretchableImage(withLeftCapWidth: Int(image.size.width/2.0), topCapHeight: Int(image.size.height/2.0))
                imageView.isUserInteractionEnabled = true
                imageView.contentMode = .scaleToFill
                scrollView.addSubview(imageView)
                
                label.midY = imageView.midY
                
                textField.frame = imageView.bounds
                //textField.delegate = self
                textField.font = .systemFont(ofSize: 17.0, weight: .medium)
                textField.textColor = UIColor(red: 0.18, green: 0.22, blue: 0.36, alpha: 1.0)
                textField.backgroundColor = .clear
                textField.borderStyle = .none
                textField.clearButtonMode = .never
                textField.keyboardType = .default
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
        }
        
        let ensureButton = UIButton(type: .custom)
        ensureButton.frame = CGRect(x: x, y: y + h*2.0 + m + ceil(m*1.5), width: w, height: h)
        ensureButton.titleLabel?.font = .systemFont(ofSize: 17.0, weight: .medium)
        ensureButton.setTitle("确定", for: .normal)
        ensureButton.setTitleColor(.black, for: .normal)
        ensureButton.layer.cornerRadius = floor(ensureButton.height/3.0)
        ensureButton.clipsToBounds = true
        ensureButton.setBackgroundImage(UIImage(color: UIColor(r: 100.0, g: 237.0, b: 193.0, a: 1.0)), for: .normal)
        ensureButton.addTarget(self, action: #selector(ensure), for: .touchUpInside)
        scrollView.addSubview(ensureButton)
        
        var contentSize = scrollView.frame.size
        contentSize.height = max(ensureButton.maxY + max(MN_TAB_SAFE_HEIGHT, 25.0), contentSize.height)
        scrollView.contentSize = contentSize
    }
}

// MARK: - Event
private extension TLProfileViewController {
    /// 选择头像
    /// - Parameter sender: 头像按钮
    @objc func avatarButtonTouchUpInside(_ sender: UIButton) {
        view.endEditing(true)
        let picker = MNAssetPicker.picker
        picker.options.minPickingCount = 1
        picker.options.maxPickingCount = 1
        picker.options.isAllowsPreview = false
        picker.options.isAllowsTaking = false
        picker.options.isAllowsExportHeifc = false
        picker.options.isAllowsExportMov = false
        picker.options.isAllowsSlidingPicking = false
        picker.options.isAllowsOriginalExport = false
        picker.options.shouldOptimizeExportImage = true
        picker.options.isUsingFullScreenPresentation = true
        picker.options.shouldExportLiveResource = false
        picker.options.isAllowsPickingVideo = false
        picker.options.isAllowsPickingGif = true
        picker.options.isAllowsPickingPhoto = true
        picker.options.isAllowsPickingLivePhoto = true
        picker.options.isUsingPhotoPolicyPickingGif = true
        picker.options.isUsingPhotoPolicyPickingLivePhoto = true
        picker.options.isAllowsMultiplePickingGif = false
        picker.options.isAllowsMultiplePickingVideo = false
        picker.options.isAllowsMultiplePickingPhoto = false
        picker.options.isAllowsMultiplePickingLivePhoto = false
        picker.options.isShowPickingNumber = false
        picker.present { _, assets in
            sender.setBackgroundImage(assets.first?.content as? UIImage, for: .selected)
            if let _ = sender.backgroundImage(for: .selected) {
                sender.isSelected = true
            }
        }
    }
    
    @objc func ensure() {
        
        view.endEditing(true)
        
        guard avatarButton.isSelected, let avatar = avatarButton.backgroundImage(for: .selected) else {
            view.showMsgToast("请选择头像")
            return
        }
        
        
        guard let text = textField.text, text.count > 0 else {
            view.showMsgToast(textField.attributedPlaceholder!.string)
            return
        }
        
        let nickname = text.replacingOccurrences(of: " ", with: "")
        guard nickname.count > 0 else {
            view.showMsgToast("昵称不合法")
            return
        }
        
        profile.nickname = nickname
        navigationController?.pushViewController(TLBindViewController(profile: profile), animated: true)
    }
}

// MARK: - Navigation
extension TLProfileViewController {
    
    override func navigationBarShouldCreateLeftBarItem() -> UIView? {
        let leftBarButton = UIButton(type: .custom)
        leftBarButton.size = CGSize(width: 25.0, height: 25.0)
        leftBarButton.setBackgroundImage(UIImage(named: "back"), for: .normal)
        leftBarButton.addTarget(self, action: #selector(navigationBarLeftBarItemTouchUpInside(_:)), for: .touchUpInside)
        return leftBarButton
    }
}
