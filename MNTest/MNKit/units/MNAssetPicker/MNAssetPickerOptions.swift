//
//  MNAssetPickerOptions.swift
//  MNFoundation
//
//  Created by 冯盼 on 2021/9/27.
//  资源选择器配置信息 allowsMultipleSelection

import UIKit
import Foundation

@objc protocol MNAssetPickerDelegate {
    /**
     资源选择器取消事件
     @param picker 资源选择器
     */
    @objc optional func assetPicker(didCancel picker: MNAssetPicker) -> Void
    /**
     资源选择器结束选择事件
     @param picker 资源选择器
     @param assets 资源数组
     */
    func assetPicker(_ picker: MNAssetPicker, didFinishPicking assets: [MNAsset]) -> Void
}

/**
 选择器样式
 */
@objc enum MNAssetPickerMode: Int {
    case light = 0 // 白色
    case dark = 1 // 暗黑
}

/// 相册资源选择条件
class MNAssetPickerOptions: NSObject {
    /**
     最多选择数量
     */
    @objc var maxPickingCount: Int = 1
    /**
     至少选择数量 <default 0 不限制>
     */
    @objc var minPickingCount: Int = 0
    /**
     是否允许编辑<"maxPickingCount==1"有效>
     */
    @objc var isAllowsEditing: Bool = false
    /**
     是否允许预览
     */
    @objc var isAllowsPreview: Bool = false
    /**
     是否允许显示文件大小
     */
    @objc var isShowFileSize: Bool = false
    /**
     是否允许挑选图片
     */
    @objc var isAllowsPickingPhoto: Bool = true
    /**
     是否允许挑选多张图片
     */
    @objc var isAllowsMultiplePickingPhoto: Bool = true
    /**
     是否允许挑选视频
     */
    @objc var isAllowsPickingVideo: Bool = true
    /**
     是否允许挑选多个视频
     */
    @objc var isAllowsMultiplePickingVideo: Bool = true
    /**
     是否允许挑选GIF
     */
    @objc var isAllowsPickingGif: Bool = true
    /**
     是否允许挑选多张GIF
     */
    @objc var isAllowsMultiplePickingGif: Bool = true
    /**
     是否允许挑选LivePhoto
     */
    @objc var isAllowsPickingLivePhoto: Bool = true
    /**
     是否允许挑选多张LivePhoto
     */
    @objc var isAllowsMultiplePickingLivePhoto: Bool = true
    /**
     是否允许混合选择<'isAllowsMixPicking == false'时根据首选资源类型限制>
     */
    @objc var isAllowsMixPicking: Bool = true
    /**
     #available(iOS 10.0, *)
     是否允许输出heif/heic格式图片
     */
    @objc var isAllowsHeifcExporting: Bool = false
    /**
     是否允许输出Mov格式视频
     */
    @objc var isAllowsMovExporting: Bool = false
    /**
     如果需要压缩 压缩系数
     */
    @objc var compressionQuality: CGFloat = 1.0
    /**
     把GIF当做Image使用
     */
    @objc var isUsingPhotoPolicyPickingGif: Bool = false
    /**
     把LivePhoto当做Image使用
     */
    @objc var isUsingPhotoPolicyPickingLivePhoto: Bool = false
    /**
     当未响应退出代理方法时是否允许内部自行退出
     */
    @objc var isAllowsAutoDismiss: Bool = true
    /**
     是否允许滑动选择
     */
    @objc var isAllowsSlidePicking: Bool = false
    /**
     视频编辑界面是否允许调整视频尺寸
     */
    @objc var isAllowsResizingVideoSize: Bool = false
    /**
     是否允许切换相册
     */
    @objc var isAllowsPickingAlbum: Bool = true
    /**
     是否显示空相簿
     */
    @objc var isShowEmptyAlbum: Bool = false
    /**
     是否导出LivePhoto的资源文件
     */
    @objc var shouldExportLiveResource: Bool = false
    /**
     显示的列数
     */
    @objc var numberOfColumns: Int = 4
    /**
     资源项行间隔
     */
    @objc var minimumLineSpacing: CGFloat = 4.0
    /**
     资源项列间隔
     */
    @objc var minimumInteritemSpacing: CGFloat = 4.0
    /**
     是否升序排列
     */
    @objc var isSortAscending: Bool = true
    /**
     图片调整比例
     */
    @objc var cropScale: CGFloat = 1.0
    /**
     导出视频的最小时长<仅视频有效 不符合时长要求的视频裁剪或隐藏处理>
     */
    @objc var minExportDuration: TimeInterval = 0.0
    /**
     导出视频的最大时长<仅视频有效 不符合时长要求的视频裁剪或隐藏处理>
     */
    @objc var maxExportDuration: TimeInterval = 0.0
    /**
     视频导出路径
     */
    @objc var outputURL: URL?
    /**
     视频导出质量<default 'AVAssetExportPresetMediumQuality'>
     */
    @objc var exportPreset: String?
    /**
     预览图大小<太大会影响性能>
     */
    @objc var renderSize: CGSize = CGSize(width: 250.0, height: 250.0)
    /**
     主题颜色 UIColor(red: 23.0/255.0, green: 79.0/255.0, blue: 218.0/255.0, alpha: 1.0)
     */
    @objc var color: UIColor = UIColor(red: 72.0/255.0, green: 122.0/255.0, blue: 245.0/255.0, alpha: 1.0)
    /**
     辅助颜色
     */
    @objc var tintColor: UIColor = .black
    /**
     背景样式
     */
    @objc var mode: MNAssetPickerMode = .dark
    /**
     交互事件代理
     */
    @objc weak var delegate: MNAssetPickerDelegate?
    /**
     分析文件位置及大小的队列
     */
    @objc let queue: DispatchQueue = DispatchQueue(label: "com.mn.asset.picker.queue", attributes: .concurrent)
}

// MARK: - 辅助
extension MNAssetPickerOptions {
    // 顶部栏高度
    @objc var topBarHeight: CGFloat { MN_TOP_BAR_HEIGHT }
    // 底部栏高度
    @objc var toolBarHeight: CGFloat { max(MN_TAB_BAR_HEIGHT, 55.0) }
    /**内容布局*/
    @objc var contentInset: UIEdgeInsets {
        UIEdgeInsets(top: topBarHeight, left: 0.0, bottom: maxPickingCount > 1 ? toolBarHeight : 0.0, right: 0.0)
    }
    /**背景颜色*/
    @objc var backgroundColor: UIColor { mode == .light ? .white : UIColor(red: 51.0/255.0, green: 51.0/255.0, blue: 51.0/255.0, alpha: 1.0) }
}

// MARK: - Export
extension MNAssetPickerOptions {
    
    /**文件导入位置*/
    @objc func exportURL(pathExtension: String) -> URL {
        if let url = outputURL {
            if url.isFileURL {
                if FileManager.default.fileExists(atPath: url.path) {
                    return url.deletingLastPathComponent().appendingPathComponent("\(Int(Date().timeIntervalSince1970*1000))").appendingPathExtension(url.pathExtension)
                }
                return url
            }
            return url.appendingPathComponent("\(Int(Date().timeIntervalSince1970*1000))").appendingPathExtension(url.pathExtension)
        }
        return URL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first!).appendingPathComponent("\(Int(Date().timeIntervalSince1970*1000.0))").appendingPathExtension(pathExtension)
    }
}
