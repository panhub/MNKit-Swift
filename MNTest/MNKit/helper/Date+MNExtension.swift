//
//  Date+MNExtension.swift
//  MNFoundation
//
//  Created by 冯盼 on 2021/10/27.
//

import Foundation

extension Date {
    
    /**时间戳 - 秒*/
    static var timestamps: String { "\(Int(Date().timeIntervalSince1970))" }
    
    /**时间戳 - 毫秒*/
    static var shortTimestamps: String { "\(Int(Date().timeIntervalSince1970*1000.0))" }
    
    /**格式化*/
    var stringValue: String { stringValue(format: "yyyy-MM-dd HH:mm:ss") }
    
    /**播放时间格式*/
    var timeValue: String {
        let formatter = DateFormatter.timeFormatter
        if timeIntervalSince1970 >= 3600.0 {
            formatter.dateFormat = "H:mm:ss"
        } else {
            formatter.dateFormat = "mm:ss"
        }
        return formatter.string(from: self)
    }
    
    func stringValue(format: String) -> String {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(secondsFromGMT: 3600*8)
        formatter.dateFormat = format
        return formatter.string(from: self)
    }
}

extension NSDate {
    
    @objc static func playTime(interval timeInterval: TimeInterval) -> String { Date(timeIntervalSince1970: timeInterval).timeValue }
}
