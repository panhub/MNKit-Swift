//
//  Progress+MNHelper.swift
//  MNFoundation
//
//  Created by 冯盼 on 2021/8/1.
//

import Foundation

public extension Progress {
    /**百分比*/
    var percent: Int { Int(fractionCompleted*100) }
    /**进度*/
    var completed: Double { fractionCompleted }
}
