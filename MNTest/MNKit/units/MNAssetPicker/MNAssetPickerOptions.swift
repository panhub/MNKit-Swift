//
//  MNAssetPickerOptions.swift
//  MNFoundation
//
//  Created by 冯盼 on 2021/9/27.
//  资源选择器配置信息

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
    @objc optional func assetPicker(_ picker: MNAssetPicker, didFinishPicking assets: [MNAsset]) -> Void
}

class MNAssetPickerOptions: NSObject {
    /**
     选择器样式
     */
    @objc enum AssetPickerMode: Int {
        case light = 0 // 白色
        case dark = 1 // 暗黑
    }
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
     视频拍摄最大长度
    */
    @objc var maxCaptureDuration: TimeInterval = 30.0
    /**
     是否允许拍照/录像
     */
    @objc var isAllowsTaking: Bool = false
    /**
     是否允许储存图片/视频到系统相册
     */
    @objc var isAllowsWriting: Bool = false
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
     #available(iOS 10.0, *)
     是否允许输出heif/heic格式图片
     */
    @objc var isAllowsExportHeifc: Bool = false
    /**
     如果需要采取压缩 压缩系数
     */
    @objc var compressionQuality: CGFloat = 0.7
    /**
     是否允许输出Mov格式图片
     */
    @objc var isAllowsExportMov: Bool = false
    /**
     把GIF当做Image使用
     */
    @objc var isUsingPhotoPolicyPickingGif: Bool = false
    /**
     把LivePhoto当做Image使用
     */
    @objc var isUsingPhotoPolicyPickingLivePhoto: Bool = false
    /**
     是否允许混合选择<'isAllowsMixPicking == false'时根据首选资源类型限制>
     */
    @objc var isAllowsMixPicking: Bool = true
    /**
     当代理未响应时是否允许自动退出
     */
    @objc var isAllowsAutoDismiss: Bool = true
    /**
     是否允许滑动选择
     */
    @objc var isAllowsSlidingPicking: Bool = false
    /**
     视频编辑界面是否允许调整视频尺寸
     */
    @objc var isAllowsResizingVideoSize: Bool = false
    /**
     显示选择索引
     */
    @objc var isShowPickingNumber: Bool = true
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
     优化导出的图片<接近于微信朋友圈质量>
     */
    @objc var shouldOptimizeExportImage: Bool = false
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
     是否原图输出<内部使用>
     */
    @objc var isOriginalExport: Bool = false
    /**
     是否允许以原图导出<使用原图则 'allowsOptimizeExporting' 无效>
     */
    @objc var isAllowsOriginalExport: Bool = true
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
    @objc var mode: AssetPickerMode = .dark
    /**
     交互事件代理
     */
    @objc weak var delegate: MNAssetPickerDelegate?
    /**
     弹出/落下样式
     */
    @objc var isUsingFullScreenPresentation: Bool = true
    /**
     监听相册变化以改变
     */
    @objc var isAllowsObserveLibraryChange: Bool = false
    /**
     分析文件位置及大小的队列
     */
    @objc let queue: DispatchQueue = DispatchQueue(label: "com.mn.asset.queue", attributes: .concurrent)
}

// MARK: - 辅助
extension MNAssetPickerOptions {
    // 顶部栏高度
    @objc var topbarHeight: CGFloat { isUsingFullScreenPresentation ? MN_TOP_BAR_HEIGHT : 55.0 }
    // 底部栏高度
    @objc var toolbarHeight: CGFloat { max(MN_TAB_BAR_HEIGHT, 55.0) }
    /**内容布局*/
    @objc var contentInset: UIEdgeInsets {
        UIEdgeInsets(top: topbarHeight, left: 0.0, bottom: (maxPickingCount <= 1 && isAllowsPreview == false) ? 0.0 : toolbarHeight, right: 0.0)
    }
    /**背景颜色*/
    @objc var backgroundColor: UIColor { mode == .light ? .white : UIColor(red: 51.0/255.0, green: 51.0/255.0, blue: 51.0/255.0, alpha: 1.0) }
    /**是否优化质量*/
    @objc var isUsingOptimizeExport: Bool { (isAllowsOriginalExport && isOriginalExport == false) || (isAllowsOriginalExport == false && shouldOptimizeExportImage) }
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
