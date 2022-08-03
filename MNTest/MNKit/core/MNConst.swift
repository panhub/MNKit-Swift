//
//  MNConst.swift
//  MNFoundation
//
//  Created by 冯盼 on 2021/7/14.
//  公共定义 全局依赖

import UIKit
import Foundation
import CoreGraphics

// 架包名
public let MN_KIT_NAME: String = "MNKit"
// iconfont字体文件名
public let MN_ICON_NAME: String = "iconfont"
// iconfont字体文件夹名
public let MN_FONT_DIR: String = "font"

// 是否是低分辨率屏
public let MN_IS_LOW_SCALE: Bool = UIScreen.main.scale <= 2.0
// 统一分割线高度
public let MN_SEPARATOR_HEIGHT: CGFloat = 0.7
// 宽高最小值
public let MN_SCREEN_MIN: CGFloat = UIScreen.Min
// 宽高最大值
public let MN_SCREEN_MAX: CGFloat = UIScreen.Max
// 屏幕宽
public var MN_SCREEN_WIDTH: CGFloat { UIScreen.main.bounds.width }
// 屏幕高
public var MN_SCREEN_HEIGHT: CGFloat { UIScreen.main.bounds.height }

// 状态栏高度
public let MN_STATUS_BAR_HEIGHT: CGFloat = UIApplication.StatusBarHeight
// 导航栏高度
public let MN_NAV_BAR_HEIGHT: CGFloat = UINavigationBar.Height
// 顶部栏总高度
public let MN_TOP_BAR_HEIGHT: CGFloat = (MN_STATUS_BAR_HEIGHT + MN_NAV_BAR_HEIGHT)
// 标签栏总高度
public let MN_TAB_BAR_HEIGHT: CGFloat = UITabBar.Height + UIWindow.Safe.bottom
// 底部安全区域高度
public let MN_TAB_SAFE_HEIGHT: CGFloat = UIWindow.Safe.bottom

// 是否是调试模式
#if DEBUG
public let MN_IS_DEBUG: Bool = true
#else
public let MN_IS_DEBUG: Bool = false
#endif

// 是否是模拟器
#if arch(i386) || arch(x86_64)
public let MN_IS_SIMULATOR: Bool = true
#else
public let MN_IS_SIMULATOR: Bool = false
#endif
