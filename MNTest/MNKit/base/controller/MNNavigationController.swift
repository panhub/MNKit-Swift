//
//  MNNavigationController.swift
//  MNFoundation
//
//  Created by 冯盼 on 2021/8/16.
//  导航控制器

import UIKit

class MNNavigationController: UINavigationController {
    
    private var transition: MNTransitionDelegate!
    
    override init(rootViewController: UIViewController) {
        super.init(rootViewController: rootViewController)
        layoutExtendAdjustEdges()
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        // 隐藏系统导航栏
        navigationBar.isHidden = true
        // 设置转场代理
        MNTransitionDelegate().using(to: self)
    }
    
    override func didMove(toParent parent: UIViewController?) {
        super.didMove(toParent: parent)
        if let parent = parent as? UITabBarController, let delegate = transitionDelegate {
            delegate.tabBar = parent.tabbar ?? parent.tabBar
        }
    }
}

// MARK: - UINavigationControllerDelegate
extension MNNavigationController: UINavigationControllerDelegate {
    
    func navigationControllerSupportedInterfaceOrientations(_ navigationController: UINavigationController) -> UIInterfaceOrientationMask {
        guard let vc = topViewController else { return .portrait }
        return vc.supportedInterfaceOrientations
    }
    
    func navigationControllerPreferredInterfaceOrientationForPresentation(_ navigationController: UINavigationController) -> UIInterfaceOrientation {
        guard let vc = topViewController else { return .portrait }
        return vc.preferredInterfaceOrientationForPresentation
    }
}

// MARK: - 屏幕旋转相关
extension MNNavigationController {
    
    override var shouldAutorotate: Bool {
        guard let vc = topViewController else { return false }
        return vc.shouldAutorotate
    }
}

// MARK: - 状态栏样式
extension MNNavigationController {
    override var childForStatusBarStyle: UIViewController? { topViewController }
    override var childForStatusBarHidden: UIViewController? { topViewController }
}
