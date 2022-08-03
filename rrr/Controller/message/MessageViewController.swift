//
//  ConversationViewController.swift
//  TLChat
//
//  Created by 冯盼 on 2022/7/22.
//  会话控制器

import UIKit

class MessageViewController: MNListViewController {
    /// 列表样式
    override var listType: MNListViewController.ListType { .table }
    /// 自定义导航栏高度
    override var navigationBarHeight: CGFloat { MN_NAV_BAR_HEIGHT + 10.0 }
    /// 表头
    private lazy var headerView: MessageHeaderView = {
        let headerView = MessageHeaderView(frame: tableView.bounds)
        return headerView
    }()
    /// 指示图
    private lazy var indicatorView: MNActivityIndicatorView = {
        let indicatorView = MNActivityIndicatorView(frame: CGRect(x: 0.0, y: 0.0, width: 18.0, height: 18.0))
        indicatorView.color = .black
        indicatorView.lineWidth = 1.5
        indicatorView.hidesWhenStopped = true
        return indicatorView
    }()
    
    override init() {
        super.init()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        tableView.removeObserver(self, forKeyPath: "contentOffset")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        navigationBar.translucent = false
        navigationBar.backgroundColor = .white
        navigationBar.shadowView.isHidden = true
        
        contentView.backgroundColor = .white
        tableView.frame = contentView.bounds
        tableView.backgroundColor = .white
        tableView.tableHeaderView = headerView
        tableView.keyboardDismissMode = .onDrag
        
        tableView.addObserver(self, forKeyPath: "contentOffset", options: [.old, .new], context: nil)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if let keyPath = keyPath, keyPath == "contentOffset" {
            guard let offset = change?[.newKey] as? CGPoint else { return }
            navigationBar.shadowView.isHidden = offset.y <= 0.0
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
}

// MARK: - Navigation
extension MessageViewController {
    
    override func navigationBarShouldCreateLeftBarItem() -> UIView? {
        
        let leftBarItem: UIView = UIView()
        
        let titleLabel = UILabel()
        titleLabel.text = "消息"
        titleLabel.textColor = .black
        titleLabel.numberOfLines = 1
        titleLabel.textAlignment = .center
        titleLabel.font = .systemFont(ofSize: 26.0, weight: .medium)
        titleLabel.sizeToFit()
        titleLabel.width = ceil(titleLabel.width)
        titleLabel.height = titleLabel.font!.pointSize
        
        leftBarItem.height = titleLabel.height
        leftBarItem.addSubview(titleLabel)
        
        indicatorView.minX = titleLabel.maxX + 8.0
        indicatorView.midY = titleLabel.midY
        leftBarItem.width = indicatorView.maxX
        leftBarItem.addSubview(indicatorView)
        
        return leftBarItem
    }
    
    override func navigationBarShouldCreateRightBarItem() -> UIView? {
        let rightBarButton = UIButton(type: .custom)
        rightBarButton.size = CGSize(width: 23.0, height: 23.0)
        rightBarButton.clipsToBounds = true
        rightBarButton.layer.cornerRadius = rightBarButton.height/2.0
        rightBarButton.setBackgroundImage(UIImage(named: "message-more"), for: .normal)
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
    }
}

// MARK: - Tab
extension MessageViewController {
    override var isRootViewController: Bool { true }
    override var tabBarItemTitle: String? { "消息" }
    override var tabBarItemImage: UIImage? { UIImage(named: "tab-message") }
    override var tabBarItemSelectedImage: UIImage? { UIImage(named: "tab-message-highlight") }
    override var tabBarItemTitleFont: UIFont { .systemFont(ofSize: 12.0, weight: .medium) }
    override var tabBarItemTitleColor: UIColor { UIColor(red: 0.4, green: 0.4, blue: 0.4, alpha: 1.0) }
    override var tabBarItemSelectedTitleColor: UIColor { .black }
}
