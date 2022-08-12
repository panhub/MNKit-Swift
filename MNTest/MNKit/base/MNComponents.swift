//
//  MNComponents.swift
//  MNTest
//
//  Created by 冯盼 on 2022/8/3.
//

import UIKit
import Foundation
import CoreGraphics

// MARK: - UIImage
public extension UIImage {
    
    /// fontIcon的Unicode
    struct Unicode : RawRepresentable, Equatable {
        /// 返回
        static let back = UIImage.Unicode(rawValue: "\u{e602}")
        /// 关闭
        static let close = UIImage.Unicode(rawValue: "\u{e64d}")
        /// 刷新
        static let refresh = UIImage.Unicode(rawValue: "\u{e620}")
        
        public var rawValue: String
        public init(_ rawValue: String) {
            self.rawValue = rawValue
        }
        public init(rawValue: String) {
            self.rawValue = rawValue
        }
        
        public static func == (lhs: UIImage.Unicode, rhs: UIImage.Unicode) -> Bool { lhs.rawValue == rhs.rawValue }
    }
    
    /// 构造iconfont内图片
    /// - Parameters:
    ///   - unicode: 代码
    ///   - color: 颜色
    ///   - size: 尺寸
    convenience init?(unicode: UIImage.Unicode, color: UIColor = UIColor.black, size: CGFloat = 10.0*UIScreen.main.scale) {
        //let string = Int(unicode.rawValue, radix: 16).map { String(Unicode.Scalar($0)!) }
        guard let font = UIFont.iconFont(ofSize: size*UIScreen.main.scale) else { return nil }
        UIGraphicsBeginImageContext(CGSize(width: size*UIScreen.main.scale, height: size*UIScreen.main.scale))
        (unicode.rawValue as NSString).draw(at: .zero, withAttributes: [.font: font, .foregroundColor: color])
        guard let cgImage = UIGraphicsGetImageFromCurrentImageContext()?.cgImage else { return nil }
        self.init(cgImage: cgImage, scale: UIScreen.main.scale, orientation: .up)
    }
}

// MARK: - UIFont
public extension UIFont {
    
    /// 标记注册iconfont结果
    static let isRegisterIconfont: Bool = {
        if registerFont(name: MN_ICON_NAME) {
            #if DEBUG
            print("~注册iconfont成功~")
            #endif
            return true
        }
        return false
    }()
    
    /// 获取iconfont
    /// - Parameter fontSize: 大小
    /// - Returns: iconfont
    class func iconFont(ofSize fontSize: CGFloat) -> UIFont? {
        guard isRegisterIconfont else { return nil }
        return UIFont(name: MN_ICON_NAME, size: fontSize)
    }
    
    /// 注册框架内字体
    /// - Parameter fontName: 字体名
    /// - Returns: 是否注册成功
    class func registerFont(name fontName: String) -> Bool {
        guard let bundle = Bundle(name: MN_KIT_NAME) else { return false }
        guard let path = bundle.path(forResource: fontName, ofType: "ttf", inDirectory: MN_FONT_DIR) else { return false }
        return registerFont(atPath: path)
    }
    
    /// 注册指定路径下的字体
    /// - Parameter path: 字体路径
    /// - Returns: 是否注册成功
    class func registerFont(atPath path: String) -> Bool {
        guard FileManager.default.fileExists(atPath: path) else { return false }
        guard let fontDataProvider = CGDataProvider(url: (NSURL.fileURL(withPath: path) as CFURL)) else { return false }
        guard let fontRef = CGFont(fontDataProvider) else { return false }
        var error: Unmanaged<CFError>?
        let result = CTFontManagerRegisterGraphicsFont(fontRef, &error)
        return result
    }
}

// MARK: - UIViewController
public extension UIViewController {
    
    /// 禁止对滚动视图进行布局
    @objc func layoutExtendAdjustEdges() {
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
    
    /// 依据情况出栈或模态弹出
    /// - Parameters:
    ///   - animated: 是否动态显示
    ///   - completionHandler: 结束回调(对模态弹出有效)
    @objc func pop(animated: Bool = true, completion completionHandler: (()->Void)? = nil) {
        if let nav = navigationController {
            if nav.viewControllers.count > 1 {
                nav.popViewController(animated: animated)
            } else if let _ = nav.presentingViewController {
                nav.dismiss(animated: animated, completion: completionHandler)
            }
        } else if let _ = presentingViewController {
            dismiss(animated: animated, completion: completionHandler)
        }
    }
}

// MARK: - UIView
public extension UIView {
    
    /// 背景图片
    @objc var background: UIImage? {
        set {
            if let imageView = self as? UIImageView {
                imageView.image = newValue
            } else if let button = self as? UIButton {
                button.setBackgroundImage(newValue, for: .normal)
            } else {
                layer.background = newValue
            }
        }
        get {
            if let imageView = self as? UIImageView {
                return imageView.image ?? imageView.highlightedImage
            } else if let button = self as? UIButton {
                return button.currentBackgroundImage ?? button.currentImage
            } else {
                return layer.background
            }
        }
    }
}

// MARK: - CALayer
public extension CALayer {
    
    /// 背景图片
    @objc var background: UIImage? {
        set { contents = newValue?.cgImage }
        get {
            guard let contents = self.contents else { return nil }
            return UIImage(cgImage: contents as! CGImage)
        }
    }
    
    /// 暂停动画
    func pauseAnimation() {
        guard speed == 1.0 else { return }
        let pausedTime = convertTime(CACurrentMediaTime(), from: nil)
        speed = 0.0
        timeOffset = pausedTime
    }
    
    /// 继续动画
    func resumeAnimation() {
        guard speed == 0.0 else { return }
        let pausedTime = timeOffset
        speed = 1.0
        timeOffset = 0.0
        beginTime = 0.0
        let timeSincePause = convertTime(CACurrentMediaTime(), from: nil) - pausedTime
        beginTime = timeSincePause
    }
    
    /// 重置动画
    func resetAnimation() {
        speed = 1.0
        timeOffset = 0.0
        beginTime = 0.0
    }
}
