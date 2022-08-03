//
//  FindViewController.swift
//  TLChat
//
//  Created by 冯盼 on 2022/7/22.
//

import UIKit

class FindViewController: MNListViewController {
    /// 列表样式
    override var listType: MNListViewController.ListType { .table }
    /// 自定义导航栏高度
    override var navigationBarHeight: CGFloat { MN_NAV_BAR_HEIGHT + 10.0 }
    /// 表头
    private lazy var headerView: FindHeaderView = {
        let headerView = FindHeaderView(frame: CGRect(x: 0.0, y: 0.0, width: tableView.width, height: navigationBar.maxY + 80.0))
        headerView.color = UIColor(red: 0.39, green: 0.93, blue: 0.76, alpha: 1.0)
        return headerView
    }()
    
    override init() {
        super.init()
        edges = [.bottom]
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
        
        tableView.frame = contentView.bounds
        tableView.backgroundColor = contentView.backgroundColor
        tableView.tableHeaderView = headerView
        
        tableView.addSubview(headerView)
    }
}

// MARK: - Navigation
extension FindViewController {
    
    override func navigationBarShouldCreateLeftBarItem() -> UIView? {
        
        let titleLabel = UILabel()
        titleLabel.text = "发现"
        titleLabel.textColor = .black
        titleLabel.numberOfLines = 1
        titleLabel.textAlignment = .center
        titleLabel.font = .systemFont(ofSize: 26.0, weight: .medium)
        titleLabel.sizeToFit()
        titleLabel.width = ceil(titleLabel.width)
        titleLabel.height = titleLabel.font!.pointSize
        return titleLabel
    }
    
    override func navigationBarDidCreatedBarItems(_ navigationBar: MNNavigationBar) {
        navigationBar.titleLabel.isHidden = true
        navigationBar.leftBarItem.maxY = navigationBar.height - 10.0 - (max(navigationBar.leftBarItem.height, navigationBar.rightBarItem.height) - navigationBar.leftBarItem.height)/2.0
        navigationBar.rightBarItem.midY = navigationBar.leftBarItem.midY
    }
}


// MARK: - Tab
extension FindViewController {
    override var isRootViewController: Bool { true }
    override var tabBarItemTitle: String? { "发现" }
    override var tabBarItemImage: UIImage? { UIImage(named: "tab-find") }
    override var tabBarItemSelectedImage: UIImage? { UIImage(named: "tab-find-highlight") }
    override var tabBarItemTitleFont: UIFont { .systemFont(ofSize: 12.0, weight: .medium) }
    override var tabBarItemTitleColor: UIColor { UIColor(red: 0.4, green: 0.4, blue: 0.4, alpha: 1.0) }
    override var tabBarItemSelectedTitleColor: UIColor { .black }
}

