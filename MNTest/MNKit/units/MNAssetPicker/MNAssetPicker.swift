//
//  MNAssetPicker.swift
//  MNFoundation
//
//  Created by 冯盼 on 2021/9/27.
//  资源选择器

import UIKit

typealias MNAssetCancelHandler = (MNAssetPicker)->Void
typealias MNAssetPickingHandler = (MNAssetPicker, [MNAsset])->Void

class MNAssetPicker: UINavigationController {
    /**是否动态*/
    private var isAnimated: Bool = true
    /**取消回调*/
    private var cancelHandler: MNAssetCancelHandler?
    /**选择回调*/
    private var pickingHandler: MNAssetPickingHandler!
    /**配置信息*/
    @objc lazy var options: MNAssetPickerOptions! = {
        return (viewControllers.first as? MNAssetPickerController)?.options
    }()
    
    /**图片选择器*/
    @objc static var picker: MNAssetPicker {
        return MNAssetPicker(rootViewController: MNAssetPickerController())
    }
    
    convenience init() {
        self.init(rootViewController: MNAssetPickerController())
    }
    
    private override init(navigationBarClass: AnyClass?, toolbarClass: AnyClass?) {
        super.init(navigationBarClass: navigationBarClass, toolbarClass: toolbarClass)
    }
    
    private override init(rootViewController: UIViewController) {
        super.init(rootViewController: rootViewController)
    }
    
    private override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        navigationBar.isHidden = true
        
        edgesForExtendedLayout = .all
        extendedLayoutIncludesOpaqueBars = true
        if #available(iOS 11.0, *) {
            additionalSafeAreaInsets = .zero
        } else {
            automaticallyAdjustsScrollViewInsets = false
        }
    }
}

// MARK: - 调起资源选择器
extension MNAssetPicker {
    
    @objc func present(pickingHandler: @escaping MNAssetPickingHandler, cancelHandler: MNAssetCancelHandler? = nil) {
        present(in: nil, animated: true, pickingHandler: pickingHandler, cancelHandler: cancelHandler)
    }
    
    @objc func present(in viewController: UIViewController? = nil, animated: Bool = true, pickingHandler: @escaping MNAssetPickingHandler, cancelHandler: MNAssetCancelHandler? = nil) {
        guard let parent = (viewController ?? MNAssetPicker.present) else { return }
        isAnimated = animated
        options.delegate = self
        self.cancelHandler = cancelHandler
        self.pickingHandler = pickingHandler
        self.modalPresentationStyle = .fullScreen
        parent.present(self, animated: (animated && UIApplication.shared.applicationState == .active), completion: nil)
    }
}

// MARK: - 调起资源选择器
extension MNAssetPicker: MNAssetPickerDelegate {
    
    func assetPicker(didCancel picker: MNAssetPicker) {
        if options.isAllowsAutoDismiss {
            dismiss(animated: (isAnimated && UIApplication.shared.applicationState == .active)) { [weak self] in
                guard let self = self else { return }
                self.cancelHandler?(self)
            }
        } else {
            cancelHandler?(picker)
        }
    }
    
    func assetPicker(_ picker: MNAssetPicker, didFinishPicking assets: [MNAsset]) {
        if options.isAllowsAutoDismiss {
            dismiss(animated: (isAnimated && UIApplication.shared.applicationState == .active)) { [weak self] in
                guard let self = self else { return }
                self.pickingHandler?(self, assets)
            }
        } else {
            pickingHandler?(self, assets)
        }
    }
}

// MARK: - Helper
extension MNAssetPicker {
    @objc static func fileSize(_ fileSize: Int) -> String { fileSize.fileSizeValue }
}

// MARK: - 屏幕旋转相关
extension MNAssetPicker {
    
    override var shouldAutorotate: Bool { false }
    func navigationControllerSupportedInterfaceOrientations(_ navigationController: UINavigationController) -> UIInterfaceOrientationMask { .portrait }
    func navigationControllerPreferredInterfaceOrientationForPresentation(_ navigationController: UINavigationController) -> UIInterfaceOrientation { .portrait }
}

// MARK: - 状态栏
extension MNAssetPicker {
    override var childForStatusBarStyle: UIViewController? { topViewController }
    override var childForStatusBarHidden: UIViewController? { topViewController }
}
