//
//  MNTabBarController.swift
//  MNFoundation
//
//  Created by 冯盼 on 2021/8/15.
//  标签栏控制器

import UIKit

@objc protocol MNTabBarItemRepeatSelects: NSObjectProtocol {
    
    func tabBarController(_ tabBarController: MNTabBarController, repeatSelectItem index: Int) -> Void
}

class MNTabBarController: UITabBarController {
    
    /**标签栏*/
    private let _tabbar = MNTabBar()
    override var tabbar: MNTabBar? { _tabbar }
    
    /**设置子控制器*/
    @objc var controllers: [String]? {
        didSet {
            add(childControllers: controllers)
        }
    }
    
    /**设置控制器*/
    override var viewControllers: [UIViewController]? {
        get { super.viewControllers }
        set {
            super.viewControllers = newValue
            _tabbar.add(viewControllers: newValue)
        }
    }
    
    /**设置选择索引*/
    override var selectedIndex: Int {
        get { super.selectedIndex }
        set {
            _tabbar.selectedIndex = newValue
            super.selectedIndex = newValue
        }
    }
    
    /**设置选择控制器*/
    override var selectedViewController: UIViewController? {
        get { super.selectedViewController }
        set {
            if let vc = newValue, let index = viewControllers?.firstIndex(of: vc) {
                _tabbar.selectedIndex = index
            }
            super.selectedViewController = newValue
        }
    }
    
    /**设置控制器*/
    override func setViewControllers(_ viewControllers: [UIViewController]?, animated: Bool) {
        super.setViewControllers(viewControllers, animated: animated)
        _tabbar.add(viewControllers: viewControllers)
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        delegate = self
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        // 拒绝自动布局
        layoutExtendAdjustEdges()
        // 添加标签条
        tabBar.isHidden = true
        _tabbar.delegate = self
        _tabbar.backgroundColor = .white
        view.addSubview(_tabbar)
    }
    
    /**获取指定索引导航控制器的类*/
    @objc func shouldMove(viewController vc: UIViewController, to index: Int) -> UIViewController? {
        MNNavigationController(rootViewController: vc)
    }
    
    /**添加子控制器*/
    private func add(childControllers: [String]?) -> Void {
        self.viewControllers = nil
        guard let childs = childControllers else { return }
        guard let nameSpage = Bundle.main.infoDictionary!["CFBundleExecutable"] as? String else { return }
        var viewControllers: [UIViewController] = [UIViewController]()
        for idx in 0..<childs.count {
            let cls: AnyClass? = NSClassFromString("\(nameSpage).\(childs[idx])")
            guard let type = cls as? UIViewController.Type else { continue }
            var vc = type.init()
            if let obj = shouldMove(viewController: vc, to: idx) { vc = obj }
            viewControllers.append(vc)
        }
        self.viewControllers = viewControllers
    }
}

// MARK: - 标签栏按钮点击事件
extension MNTabBarController: MNTabBarDelegate {
    
    func tabBar(_ tabBar: MNTabBar, shouldSelectItemOf index: Int) -> Bool { true }
    
    func tabBar(_ tabBar: MNTabBar, selectItemOf index: Int) {
        selectedIndex = index
    }
    
    func tabBar(_ tabBar: MNTabBar, repeatSelectItemOf index: Int) {
        var viewController = viewControllers?[index]
        while let vc = viewController {
            if vc is UINavigationController {
                viewController = (vc as! UINavigationController).viewControllers.last
            } else if vc is UITabBarController {
                viewController = (vc as! UITabBarController).selectedViewController
            } else { break }
        }
        guard let delegate = viewController as? MNTabBarItemRepeatSelects else { return }
        delegate.tabBarController(self, repeatSelectItem: index)
    }
}

// MARK: - 获取标签栏
extension MNTabBarController {
    
    override var shouldAutorotate: Bool {
        guard let vc = selectedViewController else { return false }
        return vc.shouldAutorotate
    }
}

// MARK: - 方向支持
extension MNTabBarController: UITabBarControllerDelegate {
    
    func tabBarControllerSupportedInterfaceOrientations(_ tabBarController: UITabBarController) -> UIInterfaceOrientationMask {
        guard let vc = selectedViewController else { return .portrait }
        return vc.supportedInterfaceOrientations
    }
    
    func tabBarControllerPreferredInterfaceOrientationForPresentation(_ tabBarController: UITabBarController) -> UIInterfaceOrientation {
        guard let vc = selectedViewController else { return .portrait }
        return vc.preferredInterfaceOrientationForPresentation
    }
}

// MARK: - 状态栏
extension MNTabBarController {
    
    override var childForStatusBarStyle: UIViewController? { selectedViewController }
    override var childForStatusBarHidden: UIViewController? { selectedViewController }
}

// MARK: - 获取标签栏
extension UITabBarController {
    @objc var tabbar: MNTabBar? { nil }
}
