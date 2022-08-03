//
//  MNDeviceMotior.swift
//  MNFoundation
//
//  Created by 冯盼 on 2021/12/12.
//  设备状态检测

import UIKit
import CoreMotion
import ObjectiveC

let MNDeviceOrientationChangeKey: String = "com.mn.device.orientation.change.key"
let deviceOrientationDidChange: Notification.Name = Notification.Name(rawValue: "com.mn.device.orientation.did.change")

class MNDeviceMotior: NSObject {
    /**更新间隔**/
    var updateInterval: TimeInterval = 0.0
    /**是否发送改变通知**/
    var isAllowsPostNotificationWhenChange: Bool = false
    /**设备方向**/
    private(set) var orientation: UIDeviceOrientation = .unknown
    /**检测者**/
    private var manager: CMMotionManager = CMMotionManager()
    
    func start() {
        guard manager.isAccelerometerAvailable, manager.isAccelerometerActive == false else { return }
        manager.accelerometerUpdateInterval = updateInterval
        manager.startAccelerometerUpdates(to: OperationQueue()) { [weak self] accelerometerData, error in
            guard error == nil, let data = accelerometerData, let self = self else { return }
            let x = data.acceleration.x
            let y = data.acceleration.y
            var orientation = self.orientation
            if fabs(x) <= fabs(y) {
                if y >= 0.0 {
                    orientation = .portraitUpsideDown
                } else {
                    orientation = .portrait
                }
            } else {
                if x >= 0.0 {
                    orientation = .landscapeRight
                } else {
                    orientation = .landscapeLeft
                }
            }
            guard orientation != self.orientation else { return }
            self.orientation = orientation
            guard self.isAllowsPostNotificationWhenChange else { return }
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: deviceOrientationDidChange, object: [MNDeviceOrientationChangeKey:orientation])
            }
        }
    }
    
    func stop() {
        guard manager.isAccelerometerAvailable, manager.isAccelerometerAvailable else { return }
        manager.stopAccelerometerUpdates()
    }
    
    func beginGeneratingDeviceOrientationNotifications() {
        objc_sync_enter(self)
        isAllowsPostNotificationWhenChange = true
        objc_sync_exit(self)
    }
    
    func endGeneratingDeviceOrientationNotifications() {
        objc_sync_enter(self)
        isAllowsPostNotificationWhenChange = false
        objc_sync_exit(self)
    }
}
