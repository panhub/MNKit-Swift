//
//  MNPathUtilities.swift
//  anhe
//
//  Created by 冯盼 on 2022/2/11.
//  文件路径

import Foundation

public func MNDocumentDirectory() -> String {
    NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
}

public func MNLibraryDirectory() -> String {
    NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true).first!
}

public func MNCachesDirectory() -> String {
    NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first!
}

public func MNPreferencesDirectory() -> String {
    MNLibraryAppending("Preferences")
}

public func MNDocumentAppending(_ pathComponent: String) -> String {
    MNDocumentDirectory().appendingPathComponent(pathComponent)
}

public func MNLibraryAppending(_ pathComponent: String) -> String {
    MNLibraryDirectory().appendingPathComponent(pathComponent)
}

public func MNCachesAppending(_ pathComponent: String) -> String {
    MNCachesDirectory().appendingPathComponent(pathComponent)
}

// MARK: - Path
extension String {
    
    var pathComponents: [String] { (self as NSString).pathComponents }

    var isAbsolutePath: Bool { (self as NSString).isAbsolutePath }

    var lastPathComponent: String { (self as NSString).lastPathComponent }

    var deletingLastPathComponent: String { (self as NSString).deletingLastPathComponent }

    var pathExtension: String { (self as NSString).pathExtension }

    var deletingPathExtension: String { (self as NSString).deletingPathExtension }

    func appendingPathComponent(_ str: String) -> String {
        return (self as NSString).appendingPathComponent(str)
    }
    
    func appendingPathExtension(_ str: String) -> String? {
        return (self as NSString).appendingPathExtension(str)
    }
}

