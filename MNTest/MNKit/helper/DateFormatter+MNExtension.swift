//
//  NSDateFormatter+MNExtension.swift
//  MNFoundation
//
//  Created by 冯盼 on 2021/10/27.
//

import Foundation

extension DateFormatter {
    
    /// 时间格式
    @objc static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "mm:ss"
        return formatter
    }()
}
