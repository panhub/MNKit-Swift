//
//  MNCapturePhoto.swift
//  MNFoundation
//
//  Created by 冯盼 on 2021/12/14.
//  拍摄照片实例

import UIKit
import CoreMedia

class MNCapturePhoto: NSObject {
    
    /**图片实例*/
    var image: UIImage!
    /**图片数据流*/
    var imageData: Data!
    /**时长**/
    var duration: CMTime = .invalid
    /**图片所在时间**/
    var photoDisplayTime: CMTime = .invalid
    /**视频路径*/
    var videoURL: URL!
    /**是否是LivePhoto**/
    var isLivePhoto: Bool = false
    
    private override init() {
        super.init()
    }
    
    convenience init?(imageData: Data?) {
        guard let data = imageData, let image = UIImage(data: data)?.resizingOrientation else { return nil }
        self.init()
        self.image = image
        self.imageData = imageData
    }
}
