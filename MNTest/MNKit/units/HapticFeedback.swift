//
//  HapticFeedback.swift
//  MNKit
//
//  Created by 冯盼 on 2022/3/15.
//  触觉反馈(适用于 iPhone 7、7 Plus 及其以上机型)

import UIKit
import Foundation
import AVFoundation

public class HapticFeedback {
    
    // UINotificationFeedbackGenerator
    @available(iOS 10.0, *)
    public class Notification {
        
        private static var generator: UINotificationFeedbackGenerator = {
            let generator = UINotificationFeedbackGenerator()
            generator.prepare()
            return generator
        }()
        
        private static func occurred(_ notificationType: UINotificationFeedbackGenerator.FeedbackType) {
            generator.notificationOccurred(notificationType)
            generator.prepare()
        }
        
        public static func success() {
            occurred(.success)
        }
        
        public static func warning() {
            occurred(.warning)
        }
        
        public static func error() {
            occurred(.error)
        }
    }
    
    // UIImpactFeedbackGenerator
    @available(iOS 10.0, *)
    public class Impact {
        
        //private static var generator: UIImpactFeedbackGenerator?
        
        public static func light() {
            impactOccurred(.light)
        }
        
        public static func medium() {
            impactOccurred(.medium)
        }
        
        public static func heavy() {
            impactOccurred(.heavy)
        }
        
        private static func impactOccurred(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
            let generator = UIImpactFeedbackGenerator(style: style)
            generator.prepare()
            generator.impactOccurred()
        }
    }
    
    // UISelectionFeedbackGenerator
    @available(iOS 10.0, *)
    public class Selection {
        
        private static var generator: UISelectionFeedbackGenerator = {
            let generator = UISelectionFeedbackGenerator()
            generator.prepare()
            return generator
        }()

        public static func changed() {
            generator.selectionChanged()
            generator.prepare()
        }
    }
    
    // AudioServicesPlaySystemSound
    public class AudioService {
        
        @available(iOS 9.0, *)
        public static func peek() {
            AudioServicesPlaySystemSound(1519)
        }
        
        @available(iOS 9.0, *)
        public static func pop() {
            AudioServicesPlaySystemSound(1520)
        }
        
        @available(iOS 9.0, *)
        public static func error() {
            AudioServicesPlaySystemSound(1521)
        }
        
        public static func vibration() {
            AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
        }
    }
    
    /// 振动反馈
    static func feedback() {
        if #available(iOS 10.0, *) {
            HapticFeedback.Impact.heavy()
        } else {
            HapticFeedback.AudioService.peek()
        }/* else {
            HapticFeedback.AudioService.vibration()
        }
        */
    }
}

