//
//  MNDatabase.swift
//  MNFoundation
//
//  Created by 冯盼 on 2022/3/4.
//  数据库解决方案

import SQLite3
import Foundation
import AVFoundation
import ObjectiveC.runtime
import CoreGraphics.CGBase

extension Dictionary where Key == String, Value == Any {
    var sql: String? { (self as [String:Any?]).sql }
}

extension Dictionary where Key == String, Value == Any? {
    var sql: String {
        var elements: [String] = [String]()
        for (key, value) in self {
            guard let value = value else {
                elements.append("\(key) = NULL")
                continue
            }
            var string: String = "\(key) = "
            if (value is String || value is NSString) {
                string.append(contentsOf: "'\(value)'")
            } else if (value is Int || value is Double || value is CGFloat || value is Float || value is Int64 || value is Int32 || value is Int16 || value is Int8 || value is Float32 || value is Float64) {
                string.append(contentsOf: "\(value)")
            } else if value is Bool {
                string.append(contentsOf: (value as! Bool) ? "1" : "0")
            } else if value is ObjCBool {
                string.append(contentsOf: (value as! ObjCBool).boolValue ? "1" : "0")
            } else if value is NSNumber {
                string.append(contentsOf: (value as! NSNumber).stringValue)
            } else if #available(iOS 14.0, *), value is Float16 {
                string.append(contentsOf: "\(value)")
            }
            elements.append(string)
        }
        return elements.joined(separator: " AND ")
    }
}

/// 数量/最大值/最小值
protocol MNColumnResult {}
extension Int64: MNColumnResult {}
extension Double: MNColumnResult {}
extension MNColumnResult {
    var intValue: Int {
        if self is Int64 {
            return Int(self as! Int64)
        }
        return Int(self as! Double)
    }
    var doubleValue: Double {
        if self is Int64 {
            return Double(self as! Int64)
        }
        return self as! Double
    }
}

/// 自定义表字段
protocol MNColumnConvertible: NSObjectProtocol {
    static var supportedTableColumns: [String:MNTableColumn.ColumnType] { get }
}

fileprivate let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

/// 表字段
struct MNTableColumn {
    /// 类型
    enum ColumnType: String {
        case integer, real, text, blob
    }
    /// 自增主键
    fileprivate static let PrimaryKey: String = "id"
    /// 字段名
    var name: String = ""
    /// 类型
    var type: ColumnType = .integer
    /// 建表语句
    fileprivate var sql: String {
        var sql: String = "\(name) \(type.rawValue) NOT NULL DEFAULT "
        switch type {
        case .integer:
            sql.append(contentsOf: "0")
        case .real:
            sql.append(contentsOf: "0.0")
        case .text:
            sql.append(contentsOf: "''")
        case .blob:
            sql.append(contentsOf: "[]")
        }
        return sql
    }
    /// 默认值
    fileprivate var `default`: Any {
        switch type {
        case .integer:
            return 0
        case .real:
            return 0.0
        case .text:
            return ""
        case .blob:
            return Data()
        }
    }
    
    /// 构造器
    /// - Parameters:
    ///   - name: 表字段名
    ///   - type: 表字段类型
    init(name: String, type: ColumnType) {
        self.type = type
        self.name = name
    }
}

extension MNTableColumn: Equatable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.name.lowercased() == rhs.name.lowercased()
    }
}

/// 排序方式
enum MNColumnOrderResult {
    case ascending(String)
    case descending(String)
    
    var sql: String {
        switch self {
        case .ascending(let field):
            return "ORDER BY \(field) ASC"
        case .descending(let field):
            return "ORDER BY \(field) DESC"
        }
    }
}

/// SQLite3数据库支持方案
class MNDatabase {
    // 默认数据库名
    static var name: String { "ahdata" }
    // 默认后缀
    static var `extension`: String { "sqlite" }
    // 快速构造入口
    static let `default`: MNDatabase = MNDatabase()
    // 信号量加锁保证线程安全
    private let semaphore = DispatchSemaphore(value: 1)
    // 数据操作队列
    private let queue: DispatchQueue = DispatchQueue(label: "com.mn.database.queue", qos: .default, attributes: .concurrent)
    // 数据库路径
    let path: String
    // 数据库
    private var db: OpaquePointer?
    // 表名
    private var tables: [String] = [String]()
    // 句柄
    private var stmts: [String:OpaquePointer] = [String:OpaquePointer]()
    // 表字段
    private var tableColumns: [String:[MNTableColumn]] = [String:[MNTableColumn]]()
    // 类字段缓存
    private var classColumns: [String:[MNTableColumn]] = [String:[MNTableColumn]]()
    /// 默认路径
    static var defaultPath: String {
        let documentPath: String = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        let errorPath: String = "\(documentPath)/\(MNDatabase.name).\(MNDatabase.extension)"
        guard FileManager.default.fileExists(atPath: errorPath) == false else { return errorPath }
        var folderPath: String = "\(documentPath)/MNKit"
        do {
            try FileManager.default.createDirectory(atPath: folderPath, withIntermediateDirectories: true, attributes: nil)
        } catch {
            folderPath = documentPath
        }
        return "\(folderPath)/\(MNDatabase.name).\(MNDatabase.extension)"
    }
    
    /// 便捷初始化器
    private convenience init() {
        self.init(path: MNDatabase.defaultPath)
    }
    
    /// 指定初始化器
    /// - Parameter path: 数据库路径
    init(path: String) {
        self.path = path
        var result: Bool = true
        do {
            try FileManager.default.createDirectory(at: URL(fileURLWithPath: path).deletingLastPathComponent(), withIntermediateDirectories: true, attributes: nil)
        } catch {
            result = false
            #if DEBUG
            print("创建数据路文件夹失败: \(path)")
            #endif
        }
        if result {
            #if DEBUG
            print("数据库路径: \(path)\n")
            #endif
        }
    }
}

// MARK: - 打开/关闭
extension MNDatabase {
    
    /// 打开数据库
    /// - Returns: 是否打开数据库
    func `open`() -> Bool {
        semaphore.wait()
        let result: Bool = opendb()
        if result {
            // 加载表
            var stmt: OpaquePointer?
            let sql: String = "select name from sqlite_master where type = 'table';"
            if sqlite3_prepare_v2(db, sql.cString(using: .utf8), -1, &stmt, nil) == SQLITE_OK {
                repeat {
                    let result = sqlite3_step(stmt)
                    if result == SQLITE_ROW {
                        guard let value = sqlite3_column_text(stmt, 0) else { continue }
                        let name: String = String(cString: value)
                        tables.append(name)
                    } else {
                        if result == SQLITE_ERROR {
                            #if DEBUG
                            let msg: String = String(cString: sqlite3_errmsg(db), encoding: .utf8) ?? ""
                            print("sqlite select table error (\(result)): \(msg)")
                            #endif
                        }
                        break
                    }
                } while (true)
                sqlite3_finalize(stmt)
                stmt = nil
            }
        } else {
            #if DEBUG
            print("打开数据库失败")
            #endif
        }
        semaphore.signal()
        return result
    }
    
    /// 关闭数据库
    func close() {
        semaphore.wait()
        closedb()
        stmts.removeAll()
        tables.removeAll()
        semaphore.signal()
    }
}

// MARK: - 创建表
extension MNDatabase {
    
    /// 创建表
    /// - Parameters:
    ///   - tableName: 表名
    ///   - fields: 字段集合
    /// - Returns: 是否创建成功
    func create(table tableName: String, fields: [String:MNTableColumn.ColumnType]) -> Bool {
        create(table: tableName, columns: fields.compactMap({ MNTableColumn(name: $0.key, type: $0.value)}))
    }
    
    /// 异步创建表
    /// - Parameters:
    ///   - tableName: 表名
    ///   - fields: 字段
    ///   - que: 使用的队列
    ///   - completionHandler: 结果回调
    func create(table tableName: String, fields: [String:MNTableColumn.ColumnType], using que: DispatchQueue? = nil, completion completionHandler: ((Bool)->Void)?) {
        (que ?? queue).async { [weak self] in
            guard let self = self else { return }
            let result = self.create(table: tableName, fields: fields)
            completionHandler?(result)
        }
    }
    
    /// 创建表
    /// - Parameters:
    ///   - tableName: 表名
    ///   - cls: 表参照类
    /// - Returns: 是否创建成功
    func create(table tableName: String, class cls: AnyObject.Type) -> Bool {
        create(table: tableName, columns: columns(class: cls))
    }
    
    /// 异步创建表
    /// - Parameters:
    ///   - tableName: 表名
    ///   - cls: 表参照模型
    ///   - que: 使用的队列
    ///   - completionHandler: 结束回调
    func create(table tableName: String, class cls: AnyObject.Type, using que: DispatchQueue? = nil, completion completionHandler: ((Bool)->Void)?) {
        (que ?? queue).async { [weak self] in
            guard let self = self else { return }
            let result = self.create(table: tableName, class: cls)
            completionHandler?(result)
        }
    }
    
    /// 创建表
    /// - Parameters:
    ///   - tableName: 表名
    ///   - columns: 表字段
    /// - Returns: 是否创建成功
    func create(table tableName: String, columns: [MNTableColumn]) -> Bool {
        guard tableName.count > 0, columns.count > 0 else { return false }
        guard open() else { return false }
        guard exists(table:tableName) == false else { return true }
        var columns = columns.reduce([MNTableColumn]()) { $0.contains($1) ? $0 : $0 + [$1] }
        columns.removeAll { $0.name.lowercased() == MNTableColumn.PrimaryKey }
        guard columns.count > 0 else { return false }
        columns.sort { $0.name.lowercased() < $1.name.lowercased() }
        var elements: [String] = columns.compactMap { $0.sql }
        elements.insert("\(MNTableColumn.PrimaryKey) \(MNTableColumn.ColumnType.integer.rawValue) PRIMARY KEY AUTOINCREMENT NOT NULL DEFAULT 0", at: 0)
        let sql: String = "CREATE TABLE IF NOT EXISTS '\(tableName)' (\(elements.joined(separator: ", ")));"
        semaphore.wait()
        let result: Bool = execute(sql)
        if result {
            tables.append(tableName)
        }
        semaphore.signal()
        return result
    }
    
    /// 异步创建表
    /// - Parameters:
    ///   - tableName: 表名
    ///   - columns: 字段集合
    ///   - que: 使用的队列
    ///   - completionHandler: 结束回调
    func createTable(table tableName: String, columns: [MNTableColumn], using que: DispatchQueue? = nil, completion completionHandler: ((Bool)->Void)?) {
        (que ?? queue).async { [weak self] in
            guard let self = self else { return }
            let result = self.create(table: tableName, columns: columns)
            completionHandler?(result)
        }
    }
}

// MARK: - 删除
extension MNDatabase {
    
    /// 删除表
    /// - Parameter tableName: 表名
    /// - Returns: 是否删除成功
    func delete(table tableName: String) -> Bool {
        guard tableName.count > 0, open() else { return false }
        let sql: String = "DROP TABLE IF EXISTS '\(tableName)';"
        semaphore.wait()
        let result = execute(sql)
        if result {
            tables.removeAll { $0 == tableName }
        }
        semaphore.signal()
        return result
    }
    
    /// 删除表
    /// - Parameters:
    ///   - tableName: 表名
    ///   - que: 使用的队列
    ///   - completionHandler: 结束回调
    func delete(table tableName: String, using que: DispatchQueue? = nil, completion completionHandler: ((Bool)->Void)?) {
        (que ?? queue).async { [weak self] in
            guard let self = self else { return }
            let result = self.delete(table: tableName)
            completionHandler?(result)
        }
    }
    
    /// 删除表中数据
    /// - Parameters:
    ///   - tableName: 表名
    ///   - condition: 条件
    /// - Returns: 执行结果
    func delete(from tableName: String, where condition: String? = nil) -> Bool {
        guard tableName.count > 0 else { return false }
        guard exists(table:tableName) else { return false }
        var sql: String = "DELETE FROM '\(tableName)'"
        if let string = condition, string.count > 0 {
            sql.append(contentsOf: " WHERE \(string)")
        }
        sql.append(contentsOf: ";")
        semaphore.wait()
        let result = execute(sql)
        semaphore.signal()
        return result
    }
    
    /// 异步删除表中数据
    /// - Parameters:
    ///   - tableName: 表名
    ///   - condition: 条件
    ///   - que: 使用队列
    ///   - completionHandler: 结果回调
    func delete(from tableName: String, where condition: String? = nil, using que: DispatchQueue? = nil, completion completionHandler: ((Bool)->Void)?) {
        (que ?? queue).async { [weak self] in
            guard let self = self else { return }
            let result = self.delete(from: tableName, where: condition)
            completionHandler?(result)
        }
    }
}

// MARK: - 插入数据
extension MNDatabase {
    
    /// 插入数据
    /// - Parameters:
    ///   - tableName: 表名
    ///   - model: 模型
    /// - Returns: 是否插入成功
    func insert(into tableName: String, row model: AnyObject) -> Bool {
        return insert(into: tableName, columns: columns(obj: model))
    }
    
    /// 异步插入数据
    /// - Parameters:
    ///   - tableName: 表名
    ///   - model: 模型
    ///   que: 使用队列
    ///   - completionHandler: 结束回调
    func insert(into tableName: String, row model: AnyObject, using que: DispatchQueue? = nil, completion completionHandler: ((Bool)->Void)?) {
        (que ?? queue).async { [weak self] in
            guard let self = self else { return }
            let result = self.insert(into: tableName, row: model)
            completionHandler?(result)
        }
    }
    
    /// 插入数据
    /// - Parameters:
    ///   - tableName: 表名
    ///   - fields: 字段集合
    /// - Returns: 是否插入成功
    func insert(into tableName: String, columns fields: [String:Any]) -> Bool {
        guard tableName.count > 0, fields.count > 0 else { return false }
        guard exists(table:tableName) else { return false }
        let tableColumns = columns(table: tableName)
        var columns: [String:Any] = [String:Any]()
        for (key, value) in fields {
            if key.lowercased() == MNTableColumn.PrimaryKey { continue }
            let result: [MNTableColumn] = tableColumns.filter { $0.name == key }
            guard result.count > 0 else { continue }
            switch value {
            case Optional<Any>.none:
                columns[key] = result.first!.default
            default:
                columns[key] = value
            }
        }
        guard columns.count > 0 else { return false }
        var values: [Any] = [Any]()
        var former: String = "INSERT INTO '\(tableName)' ("
        var latter: String = " VALUES ("
        for (key, value) in columns {
            values.append(value)
            former.append(contentsOf: "\(key),")
            latter.append(contentsOf: "?\(values.count),")
        }
        if former.hasSuffix(",") {
            former.removeLast()
        }
        former.append(contentsOf: ")")
        if latter.hasSuffix(",") {
            latter.removeLast()
        }
        latter.append(contentsOf: ");")
        let sql: String = former + latter
        var result: Int32 = SQLITE_ERROR
        semaphore.wait()
        if let stmt = stmt(sql) {
            guard bind(stmt, values: values) else {
                semaphore.signal()
                #if DEBUG
                print("sqlite insert into table '\(tableName)' 绑定数据失败")
                #endif
                return false
            }
            result = sqlite3_step(stmt)
            if result == SQLITE_ERROR {
                #if DEBUG
                let msg: String = String(cString: sqlite3_errmsg(db), encoding: .utf8) ?? ""
                print("sqlite insert into table '\(tableName)' (\(result)): \(msg)")
                #endif
            }
        }
        semaphore.signal()
        return result == SQLITE_DONE
    }
    
    /// 异步插入数据
    /// - Parameters:
    ///   - tableName: 表名
    ///   - fields: 字段数据集合
    ///   - que: 使用队列
    ///   - completionHandler: 结束回调
    func insert(into tableName: String, columns fields: [String:Any], using que: DispatchQueue? = nil, completion completionHandler: ((Bool)->Void)?) {
        (que ?? queue).async { [weak self] in
            guard let self = self else { return }
            let result = self.insert(into: tableName, columns: fields)
            completionHandler?(result)
        }
    }
    
    /// 从指定表中导入数据
    /// - Parameters:
    ///   - tableName: 表名
    ///   - fromTableName: 指定表
    /// - Returns: 是否执行成功
    func insert(into tableName: String, from fromTableName: String) -> Bool {
        guard tableName.count > 0, fromTableName.count > 0 else { return false }
        guard exists(table:tableName), exists(table:fromTableName) else { return false }
        let sql: String = "REPLACE INTO '\(tableName)' SELECT * FROM '\(fromTableName)';"
        semaphore.wait()
        let result = execute(sql)
        semaphore.signal()
        return result
    }
    
    /// 异步从指定表中导入数据
    /// - Parameters:
    ///   - tableName: 表名
    ///   - fromTableName: 指定表
    ///   - que: 使用队列
    ///   - completionHandler: 结束回调
    func insert(into tableName: String, from fromTableName: String, using que: DispatchQueue? = nil, completion completionHandler: ((Bool)->Void)?) {
        (que ?? queue).async { [weak self] in
            guard let self = self else { return }
            let result = self.insert(into: tableName, from: fromTableName)
            completionHandler?(result)
        }
    }
}

// MARK: - 更新数据
extension MNDatabase {
    
    /// 更新数据
    /// - Parameters:
    ///   - tableName: 表名
    ///   - condition: 条件(nil则更新全部内容)
    ///   - fields: 更新内容[字段:值]
    /// - Returns: 是否更新成功
    func update(table tableName: String, where condition: String? = nil, columns fields: [String:Any]) -> Bool {
        guard tableName.count > 0, fields.count > 0 else { return false }
        guard exists(table:tableName) else { return false }
        let tableColumns = columns(table: tableName)
        var columns: [String:Any] = [String:Any]()
        for (key, value) in fields {
            if key.lowercased() == MNTableColumn.PrimaryKey { continue }
            let result: [MNTableColumn] = tableColumns.filter { $0.name == key }
            guard result.count > 0 else { continue }
            switch value {
            case Optional<Any>.none:
                columns[key] = result.first!.default
            default:
                columns[key] = value
            }
        }
        guard columns.count > 0 else { return false }
        var values: [Any] = [Any]()
        var sql: String = "UPDATE '\(tableName)' SET"
        for (key, value) in columns {
            values.append(value)
            sql.append(contentsOf: " \(key)=?\(values.count),")
        }
        if sql.hasSuffix(",") {
            sql.removeLast()
        }
        if let string = condition, string.count > 0 {
            sql.append(contentsOf: " WHERE \(string)")
        }
        sql.append(contentsOf: ";")
        var result = Int32.min
        semaphore.wait()
        if let stmt = stmt(sql) {
            guard bind(stmt, values: values) else {
                semaphore.signal()
                #if DEBUG
                print("sqlite update table '\(tableName)' 绑定数据失败")
                #endif
                return false
            }
            result = sqlite3_step(stmt)
            if result == SQLITE_ERROR {
                #if DEBUG
                let msg: String = String(cString: sqlite3_errmsg(db), encoding: .utf8) ?? ""
                print("sqlite update table '\(tableName)' (\(result)): \(msg)")
                #endif
            }
        }
        semaphore.signal()
        return result == SQLITE_DONE
    }
    
    /// 异步更新数据
    /// - Parameters:
    ///   - tableName: 表名
    ///   - condition: 条件
    ///   - fields: 更新内容[字段:值]
    ///   - que: 使用队列
    ///   - completionHandler: 结果回调
    func update(table tableName: String, where condition: String? = nil, columns fields: [String:Any], using que: DispatchQueue? = nil, completion completionHandler: ((Bool)->Void)?) {
        (que ?? queue).async { [weak self] in
            guard let self = self else { return }
            let result = self.update(table: tableName, where: condition, columns: fields)
            completionHandler?(result)
        }
    }
    
    /// 更新数据
    /// - Parameters:
    ///   - tableName: 表名
    ///   - condition: 条件
    ///   - model: 数据模型
    /// - Returns: 是否更新成功
    func update(table tableName: String, where condition: String? = nil, row model: AnyObject) -> Bool {
        return update(table: tableName, where: condition, columns: columns(obj: model))
    }
    
    /// 异步更新数据
    /// - Parameters:
    ///   - tableName: 表名
    ///   - condition: 条件
    ///   - model: 数据模型
    ///   - que: 使用队列
    ///   - completionHandler: 结果回调
    func update(table tableName: String, where condition: String? = nil, row model: AnyObject, using que: DispatchQueue? = nil, completion completionHandler: ((Bool)->Void)?) {
        (que ?? queue).async { [weak self] in
            guard let self = self else { return }
            let result = self.update(table: tableName, where: condition, row: model)
            completionHandler?(result)
        }
    }
    
    /// 更新表名
    /// - Parameters:
    ///   - tableName: 原表名
    ///   - name: 新表名
    /// - Returns: 是否更新成功
    func update(_ tableName: String, name: String) -> Bool {
        guard tableName.count > 0, name.count > 0 else { return false }
        guard exists(table:tableName), exists(table:name) == false else { return false }
        let sql: String = "ALTER TABLE '\(tableName)' RENAME TO '\(name)';"
        semaphore.wait()
        let result = execute(sql)
        if result {
            tables.removeAll { $0 == tableName }
            tables.append(name)
        }
        semaphore.signal()
        return result
    }
    
    /// 异步更新表名
    /// - Parameters:
    ///   - tableName: 原表名
    ///   - name: 新表名
    ///   - que: 使用的队列
    ///   - completionHandler: 结果回调
    func update(_ tableName: String, name: String, using que: DispatchQueue? = nil, completion completionHandler: ((Bool)->Void)?) {
        (que ?? queue).async { [weak self] in
            guard let self = self else { return }
            let result = self.update(tableName, name: name)
            completionHandler?(result)
        }
    }
    
    /// 更新表字段
    /// - Parameters:
    ///   - tableName: 表名
    ///   - cls: 模型类
    /// - Returns: 是否更新成功
    func update(_ tableName: String, class cls: AnyObject.Type) -> Bool {
        guard tableName.count > 0 else { return false }
        guard exists(table: tableName) else { return false }
        let clsColumns = columns(class: cls)
        guard clsColumns.count > 0 else { return false }
        let tabColumns = columns(table: tableName)
        guard tabColumns.count > 0 else { return false }
        // 需要增加字段
        let adds: [MNTableColumn] = clsColumns.filter { column in
            let name = column.name
            if name.lowercased() == MNTableColumn.PrimaryKey { return false }
            return tabColumns.filter { $0.name.lowercased() == name.lowercased() }.count <= 0
        }
        // 需要删除的字段
        let removes: [MNTableColumn] = tabColumns.filter { column in
            let name = column.name
            if name.lowercased() == MNTableColumn.PrimaryKey { return false }
            return clsColumns.filter { $0.name.lowercased() == name.lowercased() }.count <= 0
        }
        guard adds.count + removes.count > 0 else { return true }
        semaphore.wait()
        guard beginTransaction() else {
            semaphore.signal()
            return false
        }
        var result: Bool = true
        if adds.count > 0 {
            for column in adds {
                let sql: String = "ALTER TABLE '\(tableName)' ADD COLUMN \(column.sql);"
                guard execute(sql) else {
                    result = false
                    break
                }
            }
        }
        if result, removes.count > 0 {
            for column in removes {
                let sql: String = "ALTER TABLE '\(tableName)' DROP COLUMN \(column.name);"
                guard execute(sql) else {
                    result = false
                    break
                }
            }
        }
        if result {
            commit()
            tableColumns.removeAll()
        } else {
            rollback()
        }
        semaphore.signal()
        return result
    }
    
    /// 异步更新表字段
    /// - Parameters:
    ///   - tableName: 表名
    ///   - cls: 表参照类
    ///   - que: 使用的队列
    ///   - completionHandler: 回调
    func update(_ tableName: String, class cls: AnyObject.Type, using que: DispatchQueue? = nil, completion completionHandler: ((Bool)->Void)?) {
        (que ?? queue).async { [weak self] in
            guard let self = self else { return }
            let result = self.update(tableName, class: cls)
            completionHandler?(result)
        }
    }
}

// MARK: - 查询
extension MNDatabase {
    
    /// 是否存在表
    /// - Parameter tableName: 表名
    /// - Returns: 是否存在表
    func exists(table tableName: String) -> Bool {
        guard open() else { return false }
        semaphore.wait()
        let result: Bool = tables.contains(tableName)
        semaphore.signal()
        return result
    }
    
    /// 获取表字段信息
    /// - Parameter tableName: 表名
    /// - Returns: 表字段集合
    func columns(table tableName: String) -> [MNTableColumn] {
        var columns: [MNTableColumn] = [MNTableColumn]()
        semaphore.wait()
        if let value = tableColumns[tableName] {
            columns.append(contentsOf: value)
        } else {
            // 查找数据库
            var stmt: OpaquePointer?
            let sql: String = "pragma table_info ('\(tableName)');"
            if sqlite3_prepare_v2(db, sql.cString(using: .utf8), -1, &stmt, nil) == SQLITE_OK {
                repeat {
                    let result = sqlite3_step(stmt)
                    if result == SQLITE_ROW {
                        //let index = sqlite3_column_int(stmt, 0)
                        guard let cName = sqlite3_column_text(stmt, 1), let cType = sqlite3_column_text(stmt, 2) else { continue }
                        guard let type = MNTableColumn.ColumnType(rawValue: String(cString: cType).lowercased()) else { continue }
                        let name = String(cString: cName)
                        if name.lowercased() == MNTableColumn.PrimaryKey { continue }
                        columns.append(MNTableColumn(name: name, type: type))
                    } else {
                        // 结束
                        if result != SQLITE_DONE {
                            columns.removeAll()
                        }
                        if result == SQLITE_ERROR {
                            #if DEBUG
                            let msg: String = String(cString: sqlite3_errmsg(db), encoding: .utf8) ?? ""
                            print("select table columns failed (\(result)): \(msg)")
                            #endif
                        }
                        break
                    }
                } while (true)
                sqlite3_finalize(stmt)
                if columns.count > 0 {
                    tableColumns[tableName] = columns
                }
            }
        }
        semaphore.signal()
        return columns
    }
    
    /// 查询数量
    /// - Parameters:
    ///   - tableName: 表名
    ///   - condition: 条件
    /// - Returns: 结束回调
    func selectCount(from tableName: String, where condition: String? = nil) -> Int? {
        guard tableName.count > 0 else { return nil }
        guard exists(table: tableName) else { return nil }
        var sql: String = "SELECT COUNT(*) FROM '\(tableName)'"
        if let string = condition, string.count > 0 {
            sql.append(contentsOf: " WHERE \(string)")
        }
        sql.append(contentsOf: ";")
        var count: Int? = nil
        semaphore.wait()
        if let stmt = stmt(sql) {
            let result = sqlite3_step(stmt)
            if result == SQLITE_ROW {
                count = Int(sqlite3_column_int(stmt, 0))
            } else if result == SQLITE_ERROR {
                #if DEBUG
                let msg: String = String(cString: sqlite3_errmsg(db), encoding: .utf8) ?? ""
                print("select table '\(tableName)' count failed (\(result)): \(msg)")
                #endif
            }
        }
        semaphore.signal()
        return count
    }
    
    /// 异步查询数量
    /// - Parameters:
    ///   - tableName: 表名
    ///   - condition: 条件
    ///   - que: 使用队列
    ///   - completionHandler: 结果回调
    func selectCount(from tableName: String, where condition: String? = nil, using que: DispatchQueue? = nil, completion completionHandler: ((Int?)->Void)?) {
        (que ?? queue).async { [weak self] in
            guard let self = self else { return }
            let result = self.selectCount(from: tableName, where: condition)
            completionHandler?(result)
        }
    }
    
    /// 对指定列求和
    /// - Parameters:
    ///   - tableName: 表名
    ///   - column: 列字段名
    ///   - condition: 限制条件
    /// - Returns: 求和结果
    func selectSum(from tableName: String, column: String, where condition: String? = nil) -> MNColumnResult? {
        guard tableName.count > 0, column.count > 0 else { return nil }
        guard exists(table: tableName) else { return nil }
        let columns: [MNTableColumn] = columns(table: tableName).filter { $0.name == column }
        guard columns.count > 0 else { return nil }
        var sql: String = "SELECT SUM(\(column)) FROM '\(tableName)'"
        if let string = condition, string.count > 0 {
            sql.append(contentsOf: " WHERE \(string)")
        }
        sql.append(contentsOf: ";")
        var sum: MNColumnResult? = nil
        semaphore.wait()
        if let stmt = stmt(sql) {
            let result = sqlite3_step(stmt)
            if result == SQLITE_ROW {
                if columns.first!.type == .integer {
                    sum = sqlite3_column_int64(stmt, 0)
                } else {
                    sum = sqlite3_column_double(stmt, 0)
                }
            } else if result == SQLITE_ERROR {
                #if DEBUG
                let msg: String = String(cString: sqlite3_errmsg(db), encoding: .utf8) ?? ""
                print("select table '\(tableName)' sum (\(column)) failed (\(result)): \(msg)")
                #endif
            }
        }
        semaphore.signal()
        return sum
    }
    
    /// 异步对指定列求和
    /// - Parameters:
    ///   - tableName: 表名
    ///   - column: 列字段名
    ///   - condition: 限制条件
    ///   - que: 使用的队列
    ///   - completionHandler: 结束回调
    func selectSum(from tableName: String, column: String, where condition: String? = nil, using que: DispatchQueue? = nil, completion completionHandler: ((MNColumnResult?)->Void)?) {
        (que ?? queue).async { [weak self] in
            guard let self = self else { return }
            let result = self.selectSum(from: tableName, column: column, where: condition)
            completionHandler?(result)
        }
    }
    
    /// 对指定列求最大值
    /// - Parameters:
    ///   - tableName: 表名
    ///   - column: 列字段
    ///   - condition: 查询条件
    /// - Returns: 最大值
    func selectMax(from tableName: String, column: String, where condition: String?) -> Double? {
        guard tableName.count > 0, column.count > 0 else { return nil }
        guard exists(table: tableName) else { return nil }
        var sql: String = "SELECT MAX(\(column)) FROM '\(tableName)'"
        if let string = condition, string.count > 0 {
            sql.append(contentsOf: " WHERE \(string)")
        }
        sql.append(contentsOf: ";")
        var max: Double? = nil
        semaphore.wait()
        if let stmt = stmt(sql) {
            let result = sqlite3_step(stmt)
            if result == SQLITE_ROW {
                max = sqlite3_column_double(stmt, 0)
            } else if result == SQLITE_ERROR {
                #if DEBUG
                let msg: String = String(cString: sqlite3_errmsg(db), encoding: .utf8) ?? ""
                print("select table '\(tableName)' max (\(column)) failed (\(result)): \(msg)")
                #endif
            }
        }
        semaphore.signal()
        return max
    }
    
    /// 异步对指定列求最大值
    /// - Parameters:
    ///   - tableName: 表名
    ///   - column: 列字段
    ///   - condition: 查询条件
    ///   - que: 使用的队列
    ///   - completionHandler: 结果回调
    func selectMax(from tableName: String, column: String, where condition: String?, using que: DispatchQueue? = nil, completion completionHandler: ((Double?)->Void)?) {
        (que ?? queue).async { [weak self] in
            guard let self = self else { return }
            let result = self.selectMax(from: tableName, column: column, where: condition)
            completionHandler?(result)
        }
    }
    
    /// 对指定列求最小值
    /// - Parameters:
    ///   - tableName: 表名
    ///   - column: 列字段
    ///   - condition: 查询条件
    /// - Returns: 最小值
    func selectMin(from tableName: String, column: String, where condition: String?) -> Double? {
        guard tableName.count > 0, column.count > 0 else { return nil }
        guard exists(table: tableName) else { return nil }
        var sql: String = "SELECT MIN(\(column)) FROM '\(tableName)'"
        if let string = condition, string.count > 0 {
            sql.append(contentsOf: " WHERE \(string)")
        }
        sql.append(contentsOf: ";")
        var min: Double? = nil
        semaphore.wait()
        if let stmt = stmt(sql) {
            let result = sqlite3_step(stmt)
            if result == SQLITE_ROW {
                min = sqlite3_column_double(stmt, 0)
            } else if result == SQLITE_ERROR {
                #if DEBUG
                let msg: String = String(cString: sqlite3_errmsg(db), encoding: .utf8) ?? ""
                print("select table '\(tableName)' min (\(column)) failed (\(result)): \(msg)")
                #endif
            }
        }
        semaphore.signal()
        return min
    }
    
    /// 异步对指定列求最小值
    /// - Parameters:
    ///   - tableName: 表名
    ///   - column: 列字段
    ///   - condition: 查询条件
    ///   - que: 使用队列
    ///   - completionHandler: 结果回调
    func selectMin(from tableName: String, column: String, where condition: String?, using que: DispatchQueue? = nil, completion completionHandler: ((Double?)->Void)?) {
        (que ?? queue).async { [weak self] in
            guard let self = self else { return }
            let result = self.selectMin(from: tableName, column: column, where: condition)
            completionHandler?(result)
        }
    }
    
    /// 查询符合条件的数据模型
    /// - Parameters:
    ///   - tableName: 表名
    ///   - condition: 条件
    ///   - order: 排序字段
    ///   - range: 数量限制
    ///   - cls: 数据模型的类型
    /// - Returns: 数据模型集合
    func selectRows<T: NSObject>(from tableName: String, where condition: String? = nil, order: MNColumnOrderResult? = nil, limit range: NSRange? = nil, class cls: T.Type) -> [T]? {
        let columns = columns(class: cls)
        guard columns.count > 0 else { return nil }
        guard let rows = selectRows(tableName, where: condition, order: order, limit: range) else { return nil }
        return rows.compactMap { row in
            let model = T.self.init()
            for (field, value) in row {
                guard columns.filter ({ $0.name == field }).count > 0 else { continue }
                model.setValue(value, forKey: field)
            }
            return model
        }
    }
    
    /// 异步查询符合条件的数据模型
    /// - Parameters:
    ///   - tableName: 表名
    ///   - condition: 条件
    ///   - order: 排序字段
    ///   - range: 数量限制
    ///   - cls: 数据模型的类型
    ///   - que: 使用队列
    ///   - completionHandler: 结果回调
    func selectRows<T: NSObject>(from tableName: String, where condition: String? = nil, order: MNColumnOrderResult? = nil, limit range: NSRange? = nil, class cls: T.Type, using que: DispatchQueue? = nil, completion completionHandler: (([T]?)->Void)?) {
        (que ?? queue).async { [weak self] in
            guard let self = self else { return }
            let result = self.selectRows(from: tableName, where: condition, order: order, limit: range, class: cls)
            completionHandler?(result)
        }
    }
    
    /// 查询符合条件的数据
    /// - Parameters:
    ///   - tableName: 表名
    ///   - condition: 条件
    ///   - order: 排序字段
    ///   - range: 数量限制
    /// - Returns: 数据集合
    func selectRows(_ tableName: String, where condition: String? = nil, order: MNColumnOrderResult? = nil, limit range: NSRange? = nil) -> [[String:Any]]? {
        guard tableName.count > 0 else { return nil }
        guard exists(table: tableName) else { return nil }
        let columns = columns(table: tableName)
        guard columns.count > 0 else { return nil }
        let fields: [String] = columns.compactMap { $0.name }
        var sql: String = "SELECT \(fields.joined(separator: ", ")) FROM '\(tableName)'"
        if let string = condition, string.count > 0 {
            sql.append(contentsOf: " WHERE \(string)")
        }
        if let order = order {
            sql.append(contentsOf: " \(order.sql)")
        }
        if let range = range, range.length > 0 {
            // location = 0 可以省略
            if range.location > 0 {
                sql.append(contentsOf: " LIMIT \(range.location), \(range.length)")
            } else {
                sql.append(contentsOf: " LIMIT \(range.length)")
            }
        }
        sql.append(contentsOf: ";")
        var rows: [[String:Any]]?
        semaphore.wait()
        if let stmt = stmt(sql: sql) {
            rows = [[String:Any]]()
            repeat {
                let result = sqlite3_step(stmt)
                if result == SQLITE_ROW {
                    // 取值
                    var value: Any
                    var row: [String:Any] = [String:Any]()
                    for index in 0..<columns.count {
                        let column = columns[index]
                        switch column.type {
                        case .integer:
                            value = Int(sqlite3_column_int64(stmt, Int32(index)))
                        case .real:
                            value = sqlite3_column_double(stmt, Int32(index))
                        case .text:
                            if let text = sqlite3_column_text(stmt, Int32(index)) {
                                value = String(cString: text)
                            } else {
                                value = ""
                            }
                        case .blob:
                            if let bytes = sqlite3_column_blob(stmt, Int32(index)) {
                                let count = sqlite3_column_bytes(stmt, Int32(index))
                                value = Data(bytes: bytes, count: Int(count))
                            } else {
                                value = Data()
                            }
                        }
                        row[column.name] = value
                    }
                    rows?.append(row)
                } else {
                    // 失败
                    if result != SQLITE_DONE {
                        rows?.removeAll()
                        rows = nil
                    }
                    // 出错
                    if result == SQLITE_ERROR {
                        #if DEBUG
                        let msg: String = String(cString: sqlite3_errmsg(db), encoding: .utf8) ?? ""
                        print("select table '\(tableName)' row failed (\(result)): \(msg)")
                        #endif
                    }
                    break
                }
            } while true
            sqlite3_finalize(stmt)
        }
        semaphore.signal()
        return rows
    }
}

// MARK: - 数据库
fileprivate extension MNDatabase {
    
    /// 开启数据库
    /// - Returns: 是否开启成功
    func opendb() -> Bool {
        if let _ = db { return true }
        let result: Int32 = sqlite3_open(path.cString(using: .utf8), &db)
        return result == SQLITE_OK
    }
    
    /// 关闭数据库
    func closedb() {
        guard let _ = db else { return }
        repeat {
            let result = sqlite3_close(db)
            if result == SQLITE_BUSY {
                while let stmt = sqlite3_next_stmt(db, nil) {
                    sqlite3_finalize(stmt)
                }
            } else {
                if result == SQLITE_ERROR {
                    #if DEBUG
                    let msg: String = String(cString: sqlite3_errmsg(db), encoding: .utf8) ?? ""
                    print("sqlite close failed (\(result)): \(msg)")
                    #endif
                }
                break
            }
        } while (true)
        db = nil
    }
    
    /// 开始事务
    /// - Returns: 是否开启成功
    func beginTransaction() -> Bool { execute("BEGIN TRANSACTION;") }
    
    /// 提交任务
    /// - Returns: 是否提交成功
    func commit() {
        let _ = execute("COMMIT TRANSACTION;")
    }
    
    /// 回滚任务
    /// - Returns: 是否回滚成功
    func rollback() {
        let _ = execute("ROLLBACK TRANSACTION;")
    }
    
    /// 执行语句
    /// - Parameter sql: 语句
    /// - Returns: 是否执行成功
    func execute(_ sql: String) -> Bool {
        guard sql.count > 0, let _ = db else { return false }
        let result = sqlite3_exec(db, sql.cString(using: .utf8), nil, nil, nil)
        if result == SQLITE_ERROR {
            #if DEBUG
            let msg: String = String(cString: sqlite3_errmsg(db), encoding: .utf8) ?? ""
            print("execute sql \"\(sql)\" failed (\(result)): \(msg)")
            #endif
        }
        return result == SQLITE_OK
    }
    
    /// 获取缓存句柄没有就创建并缓存
    /// - Parameter sql: 数据库语句
    /// - Returns: 句柄
    func stmt(_ sql: String) -> OpaquePointer? {
        guard sql.count > 0 else { return nil }
        if let stmt = stmts[sql] {
            sqlite3_reset(stmt)
            return stmt
        }
        if let stmt = stmt(sql: sql) {
            stmts[sql] = stmt
            return stmt
        }
        return nil
    }
    
    /// 创建句柄
    /// - Parameter sql: 数据库语句
    /// - Returns: 句柄
    func stmt(sql: String) -> OpaquePointer? {
        guard sql.count > 0 else { return nil }
        var stmt: OpaquePointer?
        let result = sqlite3_prepare_v2(db, sql.cString(using: .utf8), -1, &stmt, nil)
        if result == SQLITE_ERROR {
            #if DEBUG
            let msg: String = String(cString: sqlite3_errmsg(db), encoding: .utf8) ?? ""
            print("sqlite stmt prepare error (\(result)): \(msg)")
            #endif
        }
        return stmt
    }
}

// MARK: - 辅助
fileprivate extension MNDatabase {
    
    /// 查询模型在数据库中的字段
    /// - Parameter obj: 模型对象
    /// - Returns: [字段:值]
    func columns(obj: AnyObject) -> [String:Any] {
        var result: [String:Any] = [String:Any]()
        guard let cls = object_getClass(obj) else { return result }
        let columns = columns(class: cls)
        guard columns.count > 0 else { return result }
        let children: Mirror.Children = Mirror(reflecting: obj).children
        guard children.count > 0 else { return result }
        for (label, value) in children {
            guard let name = label else { continue }
            let array: [MNTableColumn] = columns.filter { $0.name == name }
            guard array.count > 0 else { continue }
            let column = array.first!
            // ExpressibleByNilLiteral
            switch value {
            case Optional<Any>.none:
                // 处理nil
                result[column.name] = column.default
            default:
                // 处理枚举
                let mirror = Mirror(reflecting: value)
                if let style = mirror.displayStyle, style == .enum {
                    result[column.name] = obj.value(forKey:column.name) ?? column.default
                } else {
                    result[column.name] = value
                }
            }
        }
        return result
    }
    
    /// 类映射的表字段
    /// - Parameter cls: 指定类
    /// - Returns: 表字段
    func columns(class cls: AnyObject.Type) -> [MNTableColumn] {
        let clsString: String = NSStringFromClass(cls)
        var columns: [MNTableColumn] = [MNTableColumn]()
        //guard let superclass = class_getSuperclass(cls), superclass == NSObject.self else { return columns }
        semaphore.wait()
        if let value = classColumns[clsString] {
            columns.append(contentsOf: value)
        }
        if columns.count <= 0, let convertible = cls as? MNColumnConvertible.Type {
            for column in convertible.supportedTableColumns {
                columns.append(MNTableColumn(name: column.key, type: column.value))
            }
            if columns.count > 0 {
                classColumns[clsString] = columns
            }
        }
        if columns.count <= 0 {
            var count: UInt32 = 0
            if let properties = class_copyPropertyList(cls, &count) {
                for idx in 0..<count {
                    let property = properties[Int(idx)]
                    guard let name = String(cString: property_getName(property), encoding: .utf8) else { continue }
                    if name.lowercased() == MNTableColumn.PrimaryKey { continue }
                    guard let type = columnType(property: property) else { continue }
                    columns.append(MNTableColumn(name: name, type: type))
                }
                free(properties)
            }
            if columns.count > 0 {
                classColumns[clsString] = columns
            }
        }
        semaphore.signal()
        return columns
    }
    
    /// 属性在数据库中对应的字段类型
    /// - Parameter property: 属性
    /// - Returns: 字段类型
    func columnType(property: objc_property_t) -> MNTableColumn.ColumnType? {
        guard let attr = property_getAttributes(property), let string = String(cString: attr, encoding: .utf8) else { return nil }
        let attributes: [String] = string.components(separatedBy: ",")
        // 只读属性不做表字段
        guard attributes.contains("R") == false else { return nil }
        // NSString
        if attributes.contains("T@\"NSString\"") { return .text }
        // NSNumber Double Float CGFloat
        if attributes.contains("T@\"NSNumber\"") || attributes.contains("Td") || attributes.contains("Tf") { return .real }
        // Int BOOL NSInteger NSUInteger
        if attributes.contains("Ti") || attributes.contains("TB") || attributes.contains("Tq") || attributes.contains("TQ") { return .integer }
        // NSData
        if attributes.contains("T@\"NSData\"") { return .blob }
        return nil
    }
    
    /// 绑定句柄
    /// - Parameters:
    ///   - stmt: 句柄
    ///   - values: 值集合
    func bind(_ stmt: OpaquePointer, values: [Any]) -> Bool {
        var flag: Bool = true
        for idx in 1...values.count {
            var result: Int32 = SQLITE_ERROR
            let element = values[idx - 1]
            if let value = element as? String {
                result = sqlite3_bind_text(stmt, Int32(idx), value, -1, SQLITE_TRANSIENT)
            } else if let value = element as? NSString {
                result = sqlite3_bind_text(stmt, Int32(idx), value.utf8String, -1, SQLITE_TRANSIENT)
            } else if let value = element as? Bool {
                result = sqlite3_bind_int64(stmt, Int32(idx), value ? sqlite3_int64(1) : sqlite3_int64(0))
            } else if let value = element as? ObjCBool {
                result = sqlite3_bind_int64(stmt, Int32(idx), value.boolValue ? sqlite3_int64(1) : sqlite3_int64(0))
            } else if let value = element as? Int {
                result = sqlite3_bind_int64(stmt, Int32(idx), sqlite3_int64(value))
            } else if let value = element as? Int64 {
                result = sqlite3_bind_int64(stmt, Int32(idx), value as sqlite3_int64)
            } else if let value = element as? Int32 {
                result = sqlite3_bind_int64(stmt, Int32(idx), sqlite3_int64(value))
            } else if let value = element as? Int16 {
                result = sqlite3_bind_int64(stmt, Int32(idx), sqlite3_int64(value))
            } else if let value = element as? Int8 {
                result = sqlite3_bind_int64(stmt, Int32(idx), sqlite3_int64(value))
            } else if let value = element as? Double {
                result = sqlite3_bind_double(stmt, Int32(idx), value)
            } else if let value = element as? CGFloat {
                result = sqlite3_bind_double(stmt, Int32(idx), Double(value))
            } else if let value = element as? Float {
                result = sqlite3_bind_double(stmt, Int32(idx), Double(value))
            } else if #available(iOS 14.0, *), let value = element as? Float16 {
                result = sqlite3_bind_double(stmt, Int32(idx), Double(value))
            } else if let value = element as? Data {
                var bytes = [UInt8](value)
                result = sqlite3_bind_blob(stmt, Int32(idx), &bytes, Int32(bytes.count), SQLITE_TRANSIENT)
            } else if let value = element as? NSData {
                result = sqlite3_bind_blob(stmt, Int32(idx), value.bytes, Int32(value.length), SQLITE_TRANSIENT)
            } else if let value = element as? NSNumber {
                let double: Double = value.doubleValue
                let int64: sqlite3_int64 = value.int64Value
                let difference: Double = fabs(Double(int64)) - fabs(double)
                if fabs(difference) <= 0.001 {
                    result = sqlite3_bind_int64(stmt, Int32(idx), int64)
                } else {
                    result = sqlite3_bind_double(stmt, Int32(idx), double)
                }
            }
            guard result == SQLITE_OK else {
                flag = false
                break
            }
        }
        return flag
    }
}
