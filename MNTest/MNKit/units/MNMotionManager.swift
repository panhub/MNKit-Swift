//
//  MNMotionManager.swift
//  anhe
//
//  Created by 冯盼 on 2022/3/9.
//  设备检测支持

import Foundation
import CoreMotion

class MNMotionManager {
    // 检测实例
    private let motionManager: CMMotionManager = CMMotionManager()
    // 唯一实例
    static let `default`: MNMotionManager = MNMotionManager()
    
    private init() {
        motionManager.gyroUpdateInterval = 0.5
        motionManager.deviceMotionUpdateInterval = 0.1
        motionManager.magnetometerUpdateInterval = 0.1
        motionManager.accelerometerUpdateInterval = 0.1
    }
}

// MARK: - DeviceMotionUpdates
extension MNMotionManager {
    
    var deviceMotion: CMDeviceMotion? { motionManager.deviceMotion }
    
    var deviceMotionUpdateInterval: TimeInterval {
        get { motionManager.deviceMotionUpdateInterval }
        set { motionManager.deviceMotionUpdateInterval = newValue }
    }
    
    /// 监测设备
    /// - Parameter updatesHandler: 监测结果回调
    func startDeviceMotionUpdates(handler updatesHandler: ((CMDeviceMotion)->Void)?)  {
        guard motionManager.isDeviceMotionAvailable, motionManager.isDeviceMotionActive == false else { return }
        motionManager.startDeviceMotionUpdates(to: OperationQueue.main) { deviceMotion, _ in
            guard let data = deviceMotion else { return }
            updatesHandler?(data)
        }
    }
    
    /// 停止设备监测
    func stopDeviceMotionUpdates() {
        guard motionManager.isDeviceMotionAvailable, motionManager.isDeviceMotionActive else { return }
        motionManager.stopDeviceMotionUpdates()
    }
}

// MARK: - AccelerometerUpdates
extension MNMotionManager {
    
    var accelerometerData: CMAccelerometerData? { motionManager.accelerometerData }
    
    var accelerometerUpdateInterval: TimeInterval {
        get { motionManager.accelerometerUpdateInterval }
        set { motionManager.accelerometerUpdateInterval = newValue }
    }
    
    func startAccelerometerUpdates(handler updatesHandler: ((CMAccelerometerData)->Void)?) {
        guard motionManager.isAccelerometerAvailable, motionManager.isAccelerometerActive == false else { return }
        motionManager.startAccelerometerUpdates(to: OperationQueue.main) { accelerometerData, _ in
            guard let data = accelerometerData else { return }
            updatesHandler?(data)
        }
    }
    
    func stopAccelerometerUpdates() {
        guard motionManager.isAccelerometerAvailable, motionManager.isAccelerometerActive else { return }
        motionManager.stopAccelerometerUpdates()
    }
}

// MARK: - GyroUpdates
extension MNMotionManager {
    
    var magnetometerData: CMMagnetometerData? { motionManager.magnetometerData }
    
    var magnetometerUpdateInterval: TimeInterval {
        get { motionManager.magnetometerUpdateInterval }
        set { motionManager.magnetometerUpdateInterval = newValue }
    }
    
    func startGyroUpdates(handler updatesHandler: ((CMGyroData)->Void)?) {
        guard motionManager.isGyroAvailable, motionManager.isGyroActive == false else { return }
        motionManager.startGyroUpdates(to: OperationQueue.main) { gyroData, _ in
            guard let data = gyroData else { return }
            updatesHandler?(data)
        }
    }
    
    func stopGyroUpdates() {
        guard motionManager.isGyroAvailable, motionManager.isGyroActive else { return }
        motionManager.stopGyroUpdates()
    }
}

// MARK: - MagnetometerUpdates
extension MNMotionManager {
    
    var gyroData: CMGyroData? { motionManager.gyroData }
    
    var gyroUpdateInterval: TimeInterval {
        get { motionManager.gyroUpdateInterval }
        set { motionManager.gyroUpdateInterval = newValue }
    }
    
    func startMagnetometerUpdates(handler updatesHandler: ((CMMagnetometerData)->Void)?) {
        guard motionManager.isMagnetometerAvailable, motionManager.isMagnetometerActive == false else { return }
        motionManager.startMagnetometerUpdates(to: OperationQueue.main) { magnetometerData, _ in
            guard let data = magnetometerData else { return }
            updatesHandler?(data)
        }
    }
    
    func stopMagnetometerUpdates() {
        guard motionManager.isMagnetometerAvailable, motionManager.isMagnetometerActive else { return }
        motionManager.stopMagnetometerUpdates()
    }
}
 
