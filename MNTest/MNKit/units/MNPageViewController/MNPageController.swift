//
//  MNPageController.swift
//  anhe
//
//  Created by 冯盼 on 2022/5/27.
//  分页控制器

import UIKit

class MNPageController: UIViewController {
    
    // 框架适配
    override var isChildViewController: Bool { true }
    
    // 标记位置
    private(set) var frame: CGRect = UIScreen.main.bounds
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    init(frame: CGRect) {
        super.init(nibName: nil, bundle: nil)
        self.frame = frame
        // view的边缘允许额外布局的情况，默认为UIRectEdgeAll，意味着全屏布局(带穿透效果)
        edgesForExtendedLayout = .all
        // 额外布局是否包括不透明的Bar，默认为false
        extendedLayoutIncludesOpaqueBars = true
        // iOS11 后 additionalSafeAreaInsets 可抵消系统的安全区域
        if #available(iOS 11.0, *) {
            additionalSafeAreaInsets = .zero
        } else {
            // 是否自动调整滚动视图的内边距,默认true 系统将会根据导航条和TabBar的情况自动增加上下内边距以防止被Bar遮挡
            automaticallyAdjustsScrollViewInsets = false
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        let view = UIView(frame: frame)
        view.backgroundColor = .white
        self.view = view
    }
}

// MARK: - 禁止自动更新生命周期
extension MNPageController {
    override var shouldAutomaticallyForwardAppearanceMethods: Bool { false }
}

// MARK: - 方向限制
extension MNPageController {
    override var shouldAutorotate: Bool { false }
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { .portrait }
    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation { .portrait }
}
