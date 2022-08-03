//
//  FileManager+MNExtension.swift
//  MNFoundation
//
//  Created by 冯盼 on 2021/12/9.
//  文件管理

import Foundation

extension FileManager {
    
    class var cache: String {
        let paths = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)
        guard paths.count > 0 else { return "" }
        return paths.first!
    }
    
    class var document: String {
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        guard paths.count > 0 else { return "" }
        return paths.first!
    }
    
    class var library: String {
        let paths = NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true)
        guard paths.count > 0 else { return "" }
        return paths.first!
    }
    
    class var preference: String {
        return "\(library)/Preferences"
    }
    
    class var temp: String { NSTemporaryDirectory() }
}
