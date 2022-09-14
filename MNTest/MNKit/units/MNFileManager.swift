//
//  MNFileManager.swift
//  anhe
//
//  Created by 冯盼 on 2022/2/11.
//  文件管理

import Foundation

class MNFileManager {}

// MARK: - 计算文件大小
extension MNFileManager {
    
    /// 磁盘大小
    static var diskSize: Int64 {
        do {
            let attributes = try FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory())
            if let fileSize = (attributes[FileAttributeKey.systemSize] as? NSNumber)?.int64Value { return fileSize }
        } catch {
            #if DEBUG
            print("读取系统磁盘大小出错: \n\(error.localizedDescription)")
            #endif
        }
        return 0
    }
    
    /// 空余磁盘大小
    static var freeSize: Int64 {
        do {
            let attributes = try FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory())
            if let fileSize = (attributes[FileAttributeKey.systemFreeSize] as? NSNumber)?.int64Value { return fileSize }
        } catch {
            #if DEBUG
            print("读取空余磁盘大小出错: \n\(error.localizedDescription)")
            #endif
        }
        return 0
    }
    
    /// 磁盘使用大小
    static var diskUsedSize: Int64 {
        let total = diskSize
        let free = freeSize
        return max(0, total - free)
    }
    
    /// 计算路径下文件大小
    /// - Parameter url: 指定路径
    /// - Returns: 文件大小
    static func itemSize(at url: URL) -> Int {
        guard url.isFileURL else { return 0 }
        return itemSize(atPath: url.path)
    }
    
    /// 计算路径下文件大小
    /// - Parameter filePath: 指定路径
    /// - Returns: 文件大小
    static func itemSize(atPath filePath: String) -> Int {
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: filePath, isDirectory: &isDirectory) else { return 0 }
        if isDirectory.boolValue {
            // 文件夹
            guard let subpaths = FileManager.default.subpaths(atPath: filePath) else { return 0 }
            var fileSize: Int = 0
            for subpath in subpaths {
                let pathExtension = subpath.pathExtension
                if pathExtension.count > 0 {
                    fileSize += itemSize(atPath: filePath.appendingPathComponent(subpath))
                }
            }
            return fileSize
        }
        // 文件
        return fileSize(atPath: filePath)
    }
    
    /// 计算单个文件大小
    /// - Parameter filePath: 文件路径
    /// - Returns: 文件大小
    static func fileSize(atPath filePath: String) -> Int {
        guard FileManager.default.fileExists(atPath: filePath, isDirectory: nil) else { return 0 }
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: filePath)
            if let fileSize = (attributes[FileAttributeKey.size] as? NSNumber)?.intValue { return fileSize }
        } catch {
            #if DEBUG
            print("读取文件大小出错: \n\(error.localizedDescription)")
            #endif
        }
        return 0
    }
}

// MARK: - 创建文件夹
extension MNFileManager {
    
    static func createDirectory(atPath path: String, withIntermediateDirectories createIntermediates: Bool, attributes: [FileAttributeKey : Any]? = nil) -> Bool {
        do {
            try FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: createIntermediates, attributes: attributes)
        } catch {
            #if DEBUG
            print("创建文件夹失败 path: \(path)")
            #endif
            return false
        }
        return true
    }
    
    static func createDirectory(at url: URL, withIntermediateDirectories createIntermediates: Bool, attributes: [FileAttributeKey : Any]? = nil) -> Bool {
        do {
            try FileManager.default.createDirectory(at: url, withIntermediateDirectories: createIntermediates, attributes: attributes)
        } catch {
            #if DEBUG
            print("创建文件夹失败 url: \(url)")
            #endif
            return false
        }
        return true
    }
}

// MARK: - 复制文件
extension MNFileManager {
    
    static func copyItem(atPath srcPath: String, toPath dstPath: String) -> Bool {
        guard FileManager.default.fileExists(atPath: srcPath) else { return false }
        try? FileManager.default.removeItem(atPath: dstPath)
        do {
            try FileManager.default.createDirectory(at: URL(fileURLWithPath: dstPath).deletingLastPathComponent(), withIntermediateDirectories: true, attributes: nil)
        } catch {
            #if DEBUG
            print("复制文件失败 at: \(srcPath) to: \(dstPath)")
            #endif
            return false
        }
        do {
            try FileManager.default.copyItem(atPath: srcPath, toPath: dstPath)
        } catch {
            #if DEBUG
            print("复制文件失败 at: \(srcPath) to: \(dstPath)")
            #endif
            return false
        }
        return true
    }
    
    static func copyItem(at srcURL: URL, to dstURL: URL) -> Bool {
        guard FileManager.default.fileExists(atPath: srcURL.path) else { return false }
        try? FileManager.default.removeItem(at: dstURL)
        do {
            try FileManager.default.createDirectory(at: dstURL.deletingLastPathComponent(), withIntermediateDirectories: true, attributes: nil)
        } catch {
            #if DEBUG
            print("复制文件失败 at: \(srcURL) to: \(dstURL)")
            #endif
            return false
        }
        do {
            try FileManager.default.copyItem(at: srcURL, to: dstURL)
        } catch {
            #if DEBUG
            print("复制文件失败 at: \(srcURL) to: \(dstURL)")
            #endif
            return false
        }
        return true
    }
}

// MARK: - 移动文件
extension MNFileManager {
    
    static func moveItem(atPath srcPath: String, toPath dstPath: String) -> Bool {
        guard FileManager.default.fileExists(atPath: srcPath) else { return false }
        try? FileManager.default.removeItem(atPath: dstPath)
        do {
            try FileManager.default.createDirectory(at: URL(fileURLWithPath: dstPath).deletingLastPathComponent(), withIntermediateDirectories: true, attributes: nil)
        } catch {
            #if DEBUG
            print("移动文件失败 at: \(srcPath) to: \(dstPath)")
            #endif
            return false
        }
        guard createDirectory(at: URL(fileURLWithPath: dstPath).deletingLastPathComponent(), withIntermediateDirectories: true, attributes: nil) else { return false }
        do {
            try FileManager.default.moveItem(atPath: srcPath, toPath: dstPath)
        } catch {
            #if DEBUG
            print("移动文件失败 at: \(srcPath) to: \(dstPath)")
            #endif
            return false
        }
        return true
    }
    
    static func moveItem(at srcURL: URL, to dstURL: URL) -> Bool {
        guard FileManager.default.fileExists(atPath: srcURL.path) else { return false }
        try? FileManager.default.removeItem(at: dstURL)
        do {
            try FileManager.default.createDirectory(at: dstURL.deletingLastPathComponent(), withIntermediateDirectories: true, attributes: nil)
        } catch {
            #if DEBUG
            print("移动文件失败 at: \(srcURL) to: \(dstURL)")
            #endif
            return false
        }
        do {
            try FileManager.default.moveItem(at: srcURL, to: dstURL)
        } catch {
            #if DEBUG
            print("移动文件失败 at: \(srcURL) to: \(dstURL)")
            #endif
            return false
        }
        return true
    }
}

// MARK: - 删除文件
extension MNFileManager {
    
    static func removeItem(atPath path: String) -> Bool {
        do {
            try FileManager.default.removeItem(atPath: path)
        } catch {
            #if DEBUG
            print("删除文件失败 path: \(path)")
            #endif
            return false
        }
        return true
    }
    
    static func removeItem(at url: URL) -> Bool {
        do {
            try FileManager.default.removeItem(at: url)
        } catch {
            #if DEBUG
            print("删除文件失败 url: \(url)")
            #endif
            return false
        }
        return true
    }
}
