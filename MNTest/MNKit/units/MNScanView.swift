//
//  MNScanView.swift
//  anhe
//
//  Created by 冯盼 on 2022/3/28.
//  扫描视图

import UIKit

class MNScanView: UIView {
    
    var image: UIImage?
    
    var scanRect: CGRect = .zero
    
    var cornerSize: CGSize = CGSize(width: 2.0, height: 15.0)
    
    var cornerColor: UIColor = .white
    
    var borderWidth: CGFloat = 1.0
    
    var borderColor: UIColor = .white
    
    private let scanLine: UIImageView = UIImageView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(scanLine)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func prepareScanning() {
        guard scanRect.isEmpty == false, let image = image, image.size.isEmpty == false else { return }
        // 扫描线
        scanLine.image = image
        scanLine.width = scanRect.width
        scanLine.height = ceil(image.size.height/image.size.width*scanRect.width)
        scanLine.minY = scanRect.minY
        scanLine.midX = scanRect.midX
        scanLine.contentMode = .scaleAspectFit
        scanLine.contentScaleFactor = UIScreen.main.scale
        // 扫描动画
        if scanLine.layer.animation(forKey: "com.scan.lin.animation") == nil {
            let animation = CABasicAnimation(keyPath: "transform.translation.y")
            animation.toValue = scanRect.height - scanLine.height
            animation.duration = 2.0
            animation.beginTime = CACurrentMediaTime()
            animation.repeatCount = Float.greatestFiniteMagnitude
            animation.autoreverses = false
            animation.isRemovedOnCompletion = false
            animation.fillMode = .forwards
            animation.timingFunction = CAMediaTimingFunction(name: .easeOut)
            scanLine.layer.add(animation, forKey: "com.scan.lin.animation")
            stopScanning()
        }
    }
    
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
        guard scanRect.isEmpty == false else { return }
        
        UIColor.clear.setFill()
        UIRectFill(scanRect)
        
        guard let context = UIGraphicsGetCurrentContext() else { return }
        context.setLineCap(.butt)
        // 边框
        if borderWidth > 0.0 {
            
            context.setLineWidth(borderWidth)
            context.setStrokeColor(borderColor.cgColor)
            context.addRect(scanRect.inset(by: UIEdgeInsets(top: -borderWidth/2.0, left: -borderWidth/2.0, bottom: -borderWidth/2.0, right: -borderWidth/2.0)))
            context.strokePath()
        }
        // 边角
        if cornerSize.width > 0.0, cornerSize.height > 0.0 {
            
            context.setLineWidth(cornerSize.width)
            context.setStrokeColor(cornerColor.cgColor)
            
            context.move(to: CGPoint(x: scanRect.minX + borderWidth/2.0 + cornerSize.width/2.0, y: scanRect.minY + borderWidth/2.0 + cornerSize.height))
            context.addLine(to: CGPoint(x: scanRect.minX + borderWidth/2.0 + cornerSize.width/2.0, y: scanRect.minY + borderWidth/2.0 + cornerSize.width/2.0))
            context.addLine(to: CGPoint(x: scanRect.minX + borderWidth/2.0 + cornerSize.height, y: scanRect.minY + borderWidth/2.0 + cornerSize.width/2.0))
            
            context.move(to: CGPoint(x: scanRect.maxX - borderWidth/2.0 - cornerSize.width/2.0, y: scanRect.minY + borderWidth/2.0 + cornerSize.height))
            context.addLine(to: CGPoint(x: scanRect.maxX - borderWidth/2.0 - cornerSize.width/2.0, y: scanRect.minY + borderWidth/2.0 + cornerSize.width/2.0))
            context.addLine(to: CGPoint(x: scanRect.maxX - borderWidth/2.0 - cornerSize.height, y: scanRect.minY + borderWidth/2.0 + cornerSize.width/2.0))
            
            context.move(to: CGPoint(x: scanRect.minX + borderWidth/2.0 + cornerSize.width/2.0, y: scanRect.maxY - borderWidth/2.0 - cornerSize.height))
            context.addLine(to: CGPoint(x: scanRect.minX + borderWidth/2.0 + cornerSize.width/2.0, y: scanRect.maxY - borderWidth/2.0 - cornerSize.width/2.0))
            context.addLine(to: CGPoint(x: scanRect.minX + borderWidth/2.0 + cornerSize.height, y: scanRect.maxY - borderWidth/2.0 - cornerSize.width/2.0))
            
            context.move(to: CGPoint(x: scanRect.maxX - borderWidth/2.0 - cornerSize.width/2.0, y: scanRect.maxY - borderWidth/2.0 - cornerSize.height))
            context.addLine(to: CGPoint(x: scanRect.maxX - borderWidth/2.0 - cornerSize.width/2.0, y: scanRect.maxY - borderWidth/2.0 - cornerSize.width/2.0))
            context.addLine(to: CGPoint(x: scanRect.maxX - borderWidth/2.0 - cornerSize.height, y: scanRect.maxY - borderWidth/2.0 - cornerSize.width/2.0))
            
            context.strokePath()
        }
    }
}

extension MNScanView {
    
    func startScanning() {
        guard scanLine.layer.speed == 0.0 else { return }
        let pausedTime = scanLine.layer.timeOffset
        scanLine.layer.speed = 1.0
        scanLine.layer.timeOffset = 0.0
        scanLine.layer.beginTime = 0.0
        let timeSincePause = scanLine.layer.convertTime(CACurrentMediaTime(), from: nil) - pausedTime
        scanLine.layer.beginTime = timeSincePause
    }
    
    func stopScanning() {
        scanLine.layer.pauseAnimation()
        guard scanLine.layer.speed == 1.0 else { return }
        let pausedTime = scanLine.layer.convertTime(CACurrentMediaTime(), from: nil)
        scanLine.layer.speed = 0.0
        scanLine.layer.timeOffset = pausedTime
    }
}
