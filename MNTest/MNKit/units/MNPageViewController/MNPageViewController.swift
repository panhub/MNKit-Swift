//
//  MNPageViewController.swift
//  anhe
//
//  Created by 冯盼 on 2022/5/27.
//  分页控制器

import UIKit

class MNPageViewController: MNPageController {
    /// 修改头视图的偏移
    var fixedHeight: CGFloat = 0.0
    /// 当前偏移
    private(set) var contentOffset: CGPoint = .zero
    /// 配置信息
    let options: MNSegmentViewOptions = MNSegmentViewOptions()
    /// 交互代理
    weak var delegate: MNPageViewControllerDelegate?
    /// 数据源代理
    weak var dataSource: MNPageViewControllerDataSource?
    /// 公共头视图
    private(set) lazy var headerView: UIView = {
        let headerView = dataSource?.pageViewControllerHeaderView?(self) ?? UIView()
        headerView.minY = 0.0
        headerView.midX = profileView.bounds.midX
        return headerView
    }()
    /// 加载分段列表与公共头视图
    private(set) lazy var profileView: UIView = {
        let profileView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: view.frame.width, height: 0.0))
        return profileView
    }()
    /// 分段控制
    private(set) lazy var segmentView: MNPageSegmentView = {
        let segmentView = MNPageSegmentView(frame: CGRect(x: 0.0, y: 0.0, width: profileView.frame.width, height: options.itemSize.height))
        segmentView.dataSource = self
        return segmentView
    }()
    /// 子控制器
    private(set) lazy var pageController: MNPageScrollController = {
        let pageController = MNPageScrollController(frame: view.bounds)
        return pageController
    }()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        view.backgroundColor = .white
        
        //
        pageController.willMove(toParent: self)
        addChild(pageController)
        view.addSubview(pageController.view)
        pageController.didMove(toParent: self)
        
        profileView.addSubview(headerView)
        segmentView.minY = headerView.maxY
        profileView.addSubview(segmentView)
        view.addSubview(profileView)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        pageController.beginAppearanceTransition(true, animated: animated)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        pageController.endAppearanceTransition()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        pageController.beginAppearanceTransition(false, animated: animated)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        pageController.endAppearanceTransition()
    }
    
    /// 加载分段控制与头视图
    private func reloadProfileView() {
        headerView.minY = 0.0
        headerView.minX = 0.0
        profileView.addSubview(headerView)
        segmentView.minY = headerView.maxY
        profileView.addSubview(segmentView)
        profileView.height = segmentView.maxY
        view.addSubview(profileView)
    }
}

// MARK: - MNPageSegmentDataSource
extension MNPageViewController: MNPageSegmentDataSource {
    
    var subpageTitles: [String] { dataSource?.subpageTitles ?? [] }
    
    var segmentRightView: UIView? { dataSource?.segmentRightView ?? nil }
}
