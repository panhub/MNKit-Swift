//
//  Progress+MNHelper.swift
//  MNFoundation
//
//  Created by 冯盼 on 2021/8/1.
//

import Foundation

public extension Progress {
    
    /**进度*/
    var completed: Double { fractionCompleted }
    
    /**百分比*/
    var percent: Int {
        let behavior: NSDecimalNumberHandler = NSDecimalNumberHandler(roundingMode: .down, scale: 0, raiseOnExactness: false, raiseOnOverflow: false, raiseOnUnderflow: false, raiseOnDivideByZero: false)
        let result: NSDecimalNumber = NSDecimalNumber(value: fractionCompleted).multiplying(by: NSDecimalNumber(value: 100.0), withBehavior: behavior)
        return result.intValue
    }
}
