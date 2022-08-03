//
//  MineViewController.swift
//  TLChat
//
//  Created by 冯盼 on 2022/7/22.
//

import UIKit

class MineViewController: MNListViewController {
    /// 表格样式
    override var listType: MNListViewController.ListType { .table }
    /// 扫描
    private let scanButton = UIButton(type: .custom)
    /// 疑问
    private let queryButton = UIButton(type: .custom)
    /// 表头
    private lazy var headerView: MineHeaderView = {
        let headerView = MineHeaderView(frame: tableView.bounds)
        return headerView
    }()
    
    override init() {
        super.init()
        title = "我的"
        edges = []
        statusBarStyle = .lightContent
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
        navigationBar.backgroundColor = .clear
        navigationBar.titleLabel.alpha = 0.0
        navigationBar.shadowView.alpha = 0.0
        
        tableView.frame = contentView.bounds
        tableView.tableHeaderView = headerView
        
        tableView.addObserver(self, forKeyPath: "contentOffset", options: [.old, .new], context: nil)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if let keyPath = keyPath, keyPath == "contentOffset" {
            guard let offset = change?[.newKey] as? CGPoint else { return }
            updateNavigationBar(offset.y < (headerView.avatarButton.midY - navigationBar.maxY))
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
    
    private func updateNavigationBar(_ isHidden: Bool) {
        guard scanButton.isSelected == isHidden else { return }
        scanButton.isSelected = !isHidden
        queryButton.isSelected = !isHidden
        setStatusBarStyle(isHidden ? .lightContent : .default)
        UIView.animate(withDuration: UIApplication.shared.statusBarOrientationAnimationDuration, delay: 0.0, options: [.beginFromCurrentState], animations: { [weak self] in
            guard let self = self else { return }
            self.navigationBar.titleLabel.alpha = isHidden ? 0.0 : 1.0
            self.navigationBar.shadowView.alpha = isHidden ? 0.0 : 1.0
            self.navigationBar.backgroundColor = isHidden ? .clear : .white
        }, completion: nil)
    }
}

// MARK: - 
extension MineViewController {
}

// MARK: - Navigation
extension MineViewController {
    
    override func navigationBarShouldCreateRightBarItem() -> UIView? {
        let rightBarItem = UIView(frame: CGRect(x: 0.0, y: 0.0, width: 0.0, height: 22.0))
        scanButton.size = CGSize(width: rightBarItem.height - 1.0, height: rightBarItem.height - 1.0)
        scanButton.midY = rightBarItem.height/2.0
        scanButton.setBackgroundImage(UIImage(named: "mine-scan-white"), for: .normal)
        scanButton.setBackgroundImage(UIImage(named: "mine-scan"), for: .selected)
        scanButton.adjustsImageWhenHighlighted = false
        scanButton.addTarget(self, action: #selector(navigationBarRightBarItemTouchUpInside(_:)), for: .touchUpInside)
        rightBarItem.addSubview(scanButton)
        queryButton.tag = 1
        queryButton.size = CGSize(width: rightBarItem.height, height: rightBarItem.height)
        queryButton.midY = scanButton.midY
        queryButton.minX = scanButton.maxX + 20.0
        queryButton.setBackgroundImage(UIImage(named: "mine-query-white"), for: .normal)
        queryButton.setBackgroundImage(UIImage(named: "mine-query"), for: .selected)
        queryButton.adjustsImageWhenHighlighted = false
        queryButton.addTarget(self, action: #selector(navigationBarRightBarItemTouchUpInside(_:)), for: .touchUpInside)
        rightBarItem.addSubview(queryButton)
        rightBarItem.width = queryButton.maxX
        return rightBarItem
    }
    
    override func navigationBarDidCreatedBarItems(_ navigationBar: MNNavigationBar) {
        navigationBar.rightBarItem.maxY = navigationBar.height - 10.0
        navigationBar.titleLabel.midY = navigationBar.rightBarItem.midY
    }
}

// MARK: - Tab
extension MineViewController {
    override var isRootViewController: Bool { true }
    override var tabBarItemTitle: String? { "我的" }
    override var tabBarItemImage: UIImage? { UIImage(named: "tab-mine") }
    override var tabBarItemSelectedImage: UIImage? { UIImage(named: "tab-mine-highlight") }
    override var tabBarItemTitleFont: UIFont { .systemFont(ofSize: 12.0, weight: .medium) }
    override var tabBarItemTitleColor: UIColor { UIColor(red: 0.4, green: 0.4, blue: 0.4, alpha: 1.0) }
    override var tabBarItemSelectedTitleColor: UIColor { .black }
}
