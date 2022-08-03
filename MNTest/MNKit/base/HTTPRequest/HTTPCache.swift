//
//  HTTPDatabase.swift
//  MNFoundation
//
//  Created by 冯盼 on 2021/8/3.
//  网络数据缓存

import UIKit
import Foundation
import SQLite3

public class HTTPCache {
    /**定义存储项*/
    fileprivate struct Cache {
        var time: Int = 0
        var key: String!
        var value: Data!
    }
    /**默认表名*/
    public static let Table: String = "t_network_cache"
    /**默认数据库路径*/
    public static let Path: String = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first! + "/http_db.sqlite"
    /**操作线程*/
    private let queue = DispatchQueue(label: "com.mn.url.data.cache.queue", attributes: .concurrent)
    /**数据库路径*/
    private var path: String = Path
    /**数据库路径*/
    private var table: String = Table
    /**快速实例入口*/
    public static var `default`: HTTPCache = HTTPCache()
    /**线程安全*/
    private let semaphore = DispatchSemaphore(value: 1)
    /**句柄缓存*/
    private var stmts: [String: OpaquePointer] = [String: OpaquePointer]()
    /**数据库指针*/
    private var db: OpaquePointer!
    
    /**依据路径创建数据库*/
    public init(path: String = Path, table: String = Table) {
        if FileManager.default.fileExists(atPath: path) == false {
            do {
                try FileManager.default.createDirectory(atPath: (path as NSString).deletingLastPathComponent, withIntermediateDirectories: true, attributes: nil)
            } catch {
                #if DEBUG
                print("网络数据缓存数据库创建失败:\n\(path)\n")
                #endif
            }
        }
        self.path = path
        self.table = table
    }
    
    deinit {
        close()
    }
    
    /**
     缓存数据到数据库
     有则更新 无则插入 避免产生多条数据
     */
    public func setCache(_ cache :Any, forKey key:  String!) -> Bool {
        guard let _ = key else { return false }
        var data: Data?
        if #available(iOS 12.0, *) {
            data = try? NSKeyedArchiver.archivedData(withRootObject: cache, requiringSecureCoding: true)
        } else {
            data = NSKeyedArchiver.archivedData(withRootObject: cache)
        }
        guard let _ = data else { return false }
        var cache = Cache()
        cache.key = key!
        cache.value = data!
        var result: Bool = false
        semaphore.wait()
        let count = count(key: key)
        if count == 0 {
            result = setItem(cache)
        } else if count > 0 {
            result = updateItem(cache)
        }
        semaphore.signal()
        return result
    }
    
    /**
     异步缓存数据到数据库
     */
    public func setCache(_ cache: Any, forKey key:  String!, completion: ((Bool)->Void)? = nil) -> Void {
        queue.async { [weak self] in
            if let result = self?.setCache(cache, forKey: key) {
                if let callback = completion {
                    callback(result)
                }
            }
        }
    }
    
    /**
     读取缓存
     */
    public func cache(key: String!, out: Int = 0) -> Any? {
        guard let _ = key else { return nil }
        semaphore.wait()
        let result = item(key: key)
        semaphore.signal()
        guard let item = result, let _ = item.value else { return nil }
        if out > 0  {
            let time = time(nil) as Int
            guard time < (item.time + out) else { return nil }
        }
        if #available(iOS 11.0, *) {
            return try? NSKeyedUnarchiver.unarchivedObject(ofClasses: [AnyObject.self], from: item.value)
        } else {
            return NSKeyedUnarchiver.unarchiveObject(with: item.value)
        }
    }
    
    /**
     异步读取缓存
     */
    public func cache(_ key: String!, out: Int = 0, completion: ((Any?)->Void)? = nil) -> Void {
        queue.async { [weak self] in
            let result = self?.cache(key: key, out: out)
            if let callback = completion {
                callback(result)
            }
        }
    }
    
    /**
     是否包含某条数据
     */
    public func contains(key: String!) -> Bool {
        guard let _ = key else { return false }
        return count(key: key!) > 0
    }
    
    /**
     异步判断是否包含某条数据
     */
    public func contains(_ key: String!, completion: ((Bool)->Void)? = nil) -> Void {
        queue.async { [weak self] in
            if let result = self?.contains(key: key) {
                if let callback = completion {
                    callback(result)
                }
            }
        }
    }
    
    /**
     删除指定缓存
     */
    public func remove(for key: String!) -> Bool {
        guard let _ = key else { return false }
        semaphore.wait()
        let result = remove(key: key!)
        semaphore.signal()
        return result
    }
    
    /**
     异步删除指定缓存
     */
    public func remove(_ key: String!, completion: ((Bool)->Void)? = nil) -> Void {
        queue.async { [weak self] in
            if let result = self?.remove(for: key) {
                if let callback = completion {
                    callback(result)
                }
            }
        }
    }
    
    /**
     删除所有缓存
     */
    public func removeAll() -> Bool {
        return remove()
    }
    
    /**
     异步删除所有缓存
     */
    public func removeAll(completion: ((Bool)->Void)?) -> Void {
        queue.async { [weak self] in
            if let result = self?.removeAll() {
                if let callback = completion {
                    callback(result)
                }
            }
        }
    }
}

// MARK: - 数据库支持
fileprivate extension HTTPCache {
    /**打开数据库*/
    func open() -> Bool {
        if let _ = db { return true }
        if sqlite3_open(path.cString(using: .utf8), &db) == SQLITE_OK {
            if execute(sql: "create table if not exists '\(table)' (id integer primary key autoincrement, time integer, key text, value blob);") {
                #if DEBUG
                print("网络数据缓存:\n\(path)\n")
                #endif
                return true
            }
        }
        close()
        return false
    }
    
    /**关闭数据库*/
    func close() -> Void {
        guard let _ = db else { return }
        var result: Int32 = SQLITE_OK
        var retry: Bool = false
        repeat {
            result = sqlite3_close(db)
            if result == SQLITE_OK {
                retry = false
            } else if result == SQLITE_BUSY {
                retry = true
                while let stmt = sqlite3_next_stmt(db, nil) {
                    sqlite3_finalize(stmt)
                }
            } else {
                #if DEBUG
                print("无法关闭数据库")
                #endif
            }
        } while retry
        db = nil
    }
    
    /**保存数据项*/
    func setItem(_ item: Cache) -> Bool {
        guard let key = item.key, let value = item.value else { return false }
        let sql: String = "insert into \(table) (time, key, value) values (?1, ?2, ?3);"
        guard let stmt = stmt(sql: sql) else { return false }
        let time = time(nil) as Int
        sqlite3_bind_int(stmt, 1, Int32(time))
        sqlite3_bind_text(stmt, 2, key.cString(using: .utf8), -1, nil)
        sqlite3_bind_blob(stmt, 3, [UInt8](value), Int32(value.count), nil)
        return sqlite3_step(stmt) == SQLITE_DONE
    }
    
    /**更新数据*/
    func updateItem(_ item: Cache) -> Bool {
        guard let key = item.key, let value = item.value else { return false }
        let time = time(nil) as Int
        let sql: String = "update '\(table)' set time = ?1, value = ?2 where key = ?3;"
        guard let stmt = stmt(sql: sql) else { return false }
        sqlite3_bind_int(stmt, 1, Int32(time))
        sqlite3_bind_blob(stmt, 2, [UInt8](value), Int32(value.count), nil)
        sqlite3_bind_text(stmt, 3, key.cString(using: .utf8), -1, nil)
        return sqlite3_step(stmt) == SQLITE_DONE
    }
    
    /**获取指定数据*/
    func item(key: String) -> Cache? {
        let sql: String = "select time, key, value from '\(table)' where key = ?1;"
        guard let stmt = stmt(sql: sql) else { return nil }
        sqlite3_bind_text(stmt, 1, key.cString(using: .utf8), -1, nil);
        if sqlite3_step(stmt) == SQLITE_ROW {
            let time = sqlite3_column_int(stmt, 0)
            let char = sqlite3_column_text(stmt, 1)
            let bytes = sqlite3_column_blob(stmt, 2)
            let count = sqlite3_column_bytes(stmt, 2)
            var item = Cache()
            item.time = Int(time)
            if let _ = bytes {
                item.value = Data(bytes: bytes!, count: Int(count))
            }
            if let _ = char {
                item.key = String(cString: char!)
            } else {
                item.key = key
            }
            return item
        }
        return nil
    }
    
    /**获取数据数量*/
    func count(key: String) -> Int {
        let sql = "select count(*) from '\(table)' where key = '\(key)';"
        guard let stmt = stmt(sql: sql) else { return -1 }
        guard sqlite3_step(stmt) == SQLITE_ROW else { return -1 }
        return Int(sqlite3_column_int(stmt, 0))
    }
    
    /**删除指定数据*/
    func remove(key: String) -> Bool {
        guard open() else { return false }
        return execute(sql: "delete from '\(table)' where key = '\(key)';")
    }
    
    /**删除所有数据*/
    func remove() -> Bool {
        guard open() else { return false }
        return execute(sql: "delete from '\(table)';")
    }
    
    /**执行语句*/
    func execute(sql: String) -> Bool {
        return sqlite3_exec(db, sql.cString(using: .utf8), nil, nil, nil) == SQLITE_OK
    }
    
    /**获取句柄*/
    func stmt(sql: String) -> OpaquePointer? {
        guard open() else { return nil }
        var stmt: OpaquePointer? = stmts[sql]
        if let _ = stmt {
            sqlite3_reset(stmt!)
        } else if sqlite3_prepare_v2(db, sql.cString(using: .utf8), -1, &stmt, nil) == SQLITE_OK {
            stmts[sql] = stmt!
        }
        return stmt
    }
}
