//
//  MNDatePicker.swift
//  MNTest
//
//  Created by 冯盼 on 2022/9/16.
//  日期选择器

import UIKit

// MARK: - MNDatePicker.Module
fileprivate extension MNDatePicker.Module {
    
    /// 是否是简写形式
    var isAbbr: Bool {
        switch self {
        case .year(abbr: let flag, suffix: _): return flag
        case .month(abbr: let flag, lang: _, suffix: _): return flag
        case .day(abbr: let flag, suffix: _): return flag
        case .hour(abbr: let flag, lang: _, clock12: _, suffix: _): return flag
        case .minute(abbr: let flag, suffix: _): return flag
        case .second(abbr: let flag, suffix: _): return flag
        }
    }
    
    /// 后缀
    var suffix: String {
        switch self {
        case .year(abbr: _, suffix: let suffix): return suffix
        case .month(abbr: _, lang: _, suffix: let suffix): return suffix
        case .day(abbr: _, suffix: let suffix): return suffix
        case .hour(abbr: _, lang: _, clock12: _, suffix: let suffix): return suffix
        case .minute(abbr: _, suffix: let suffix): return suffix
        case .second(abbr: _, suffix: let suffix): return suffix
        }
    }
    
    /// 语言
    var lang: MNDatePicker.Language {
        switch self {
        case .month(abbr: _, lang: let lang, suffix: _): return lang
        case .hour(abbr: _, lang: let lang, clock12: _, suffix: _): return lang
        default: return .arabic
        }
    }
    
    /// 是否使用12小时制
    var is12HourClock: Bool {
        switch self {
        case .hour(abbr: _, lang: _, clock12: let flag, suffix: _): return flag
        default: return false
        }
    }
}

// MARK: - MNDatePicker.Module
extension Array where Element == MNDatePicker.Module {
    
    /// 年配件
    var year: MNDatePicker.Module? {
        for element in self {
            switch element {
            case .year(abbr: _, suffix: _): return element
            default: break
            }
        }
        return nil
    }
    
    /// 月配件
    var month: MNDatePicker.Module? {
        for element in self {
            switch element {
            case .month(abbr: _, lang: _, suffix: _): return element
            default: break
            }
        }
        return nil
    }
    
    /// 日配件
    var day: MNDatePicker.Module? {
        for element in self {
            switch element {
            case .day(abbr: _, suffix: _): return element
            default: break
            }
        }
        return nil
    }
    
    /// 时配件
    var hour: MNDatePicker.Module? {
        for element in self {
            switch element {
            case .hour(abbr: _, lang: _, clock12: _, suffix: _): return element
            default: break
            }
        }
        return nil
    }
    
    /// 分配件
    var minute: MNDatePicker.Module? {
        for element in self {
            switch element {
            case .minute(abbr: _, suffix: _): return element
            default: break
            }
        }
        return nil
    }
    
    /// 秒配件
    var second: MNDatePicker.Module? {
        for element in self {
            switch element {
            case .second(abbr: _, suffix: _): return element
            default: break
            }
        }
        return nil
    }
}

// MARK: - MNDatePicker.Component
fileprivate extension Array where Element: MNDatePicker.Component {
    
    /// 获取时间段的配件索引
    var indexOfStage: Int? {
        for (index, element) in self.enumerated() {
            switch element.style {
            case .stage: return index
            default: break
            }
        }
        return nil
    }
    
    /// 获取年的配件索引
    var indexOfYear: Int? {
        for (index, element) in self.enumerated() {
            switch element.style {
            case .year: return index
            default: break
            }
        }
        return nil
    }
    
    /// 获取月的配件索引
    var indexOfMonth: Int? {
        for (index, element) in self.enumerated() {
            switch element.style {
            case .month: return index
            default: break
            }
        }
        return nil
    }
    
    /// 获取日的配件索引
    var indexOfDay: Int? {
        for (index, element) in self.enumerated() {
            switch element.style {
            case .day: return index
            default: break
            }
        }
        return nil
    }
    
    /// 获取时的配件索引
    var indexOfHour: Int? {
        for (index, element) in self.enumerated() {
            switch element.style {
            case .hour: return index
            default: break
            }
        }
        return nil
    }
    
    /// 获取分的配件索引
    var indexOfMinute: Int? {
        for (index, element) in self.enumerated() {
            switch element.style {
            case .minute: return index
            default: break
            }
        }
        return nil
    }
    
    /// 获取秒的配件索引
    var indexOfSecond: Int? {
        for (index, element) in self.enumerated() {
            switch element.style {
            case .month: return index
            default: break
            }
        }
        return nil
    }
}

// MARK: - MNDatePicker
class MNDatePicker: UIView {
    
    /// 内部保存当前时间
    fileprivate struct Time {
        var year: String = ""
        var month: String = ""
        var day: String = ""
        var hour: String = ""
        var minute: String = ""
        var second: String = ""
    }
    
    /// 语言(阿拉伯语 中文 英文)
    enum Language {
        case arabic, chinese, english
    }
    
    /// 日期组件
    enum Module {
        /// 年（是否简写 后缀）
        case year(abbr: Bool, suffix: String)
        /// 月（是否简写 语言 后缀）
        case month(abbr: Bool, lang: MNDatePicker.Language, suffix: String)
        /// 日（是否简写 后缀）
        case day(abbr: Bool, suffix: String)
        /// 时（是否简写 语言 是否12时制 后缀）
        case hour(abbr: Bool, lang: MNDatePicker.Language, clock12: Bool, suffix: String)
        /// 分（是否简写 后缀）
        case minute(abbr: Bool, suffix: String)
        /// 秒（是否简写 后缀）
        case second(abbr: Bool, suffix: String)
    }
    
    /// 日期配件模型
    fileprivate class Component {
        
        enum Style {
            case year, month, day, hour, minute, second, stage, suffix
        }
        
        /// 配件类型
        let style: MNDatePicker.Component.Style
        /// 行数
        var rows: [String] = [String]()
        /// 配件宽度
        var width: CGFloat = 0.0
        
        init(style: Style) {
            self.style = style
        }
        
        /// 找出最宽的项并追加宽度作为配件宽度
        /// - Parameters:
        ///   - font: 字体限制
        ///   - padding: 追加宽度
        func widthToFit(font: UIFont, padding: CGFloat) {
            let width = rows.reduce(0.0, { partialResult, string in
                let w = (string as NSString).size(withAttributes: [.font:font]).width
                return max(w, partialResult)
            })
            self.width = ceil(width) + padding
        }
    }
    
    /// 字体
    var font: UIFont?
    /// 字体颜色
    var textColor: UIColor?
    /// 组件集合
    var modules: [Module] = [.year(abbr: false, suffix: "-"), .month(abbr: false, lang: .arabic, suffix: "-"), .day(abbr: false, suffix: " "), .hour(abbr: false, lang: .arabic, clock12: false, suffix: ":"), .minute(abbr: false, suffix: ":"), .second(abbr: false, suffix: "")]
    /// 最早的时间
    var minimumDate: Date = Date(timeIntervalSince1970: 0.0)
    /// 最晚的时间
    var maximumDate: Date = Date()
    /// 行高
    var rowHeight: CGFloat = 40.0
    /// 组建间隔
    var spacing: CGFloat = 13.0
    /// 时区
    var timeZone: TimeZone {
        get { calendar.timeZone }
        set {
            calendar.timeZone = newValue
            formatter.timeZone = newValue
        }
    }
    /// 选择项颜色
    override var tintColor: UIColor! {
        get { picker.tintColor }
        set { picker.tintColor = newValue }
    }
    /// 适配选择器位置
    override var frame: CGRect {
        get { super.frame }
        set {
            super.frame = newValue
            picker.frame = bounds
        }
    }
    /// 记录当前时间
    private var time: Time = Time()
    /// 组件集合
    private var components: [Component] = [Component]()
    /// 选择器控件
    private lazy var picker: UIPickerView = {
        let picker = UIPickerView(frame: bounds)
        picker.delegate = self
        picker.dataSource = self
        picker.backgroundColor = .clear
        picker.tintColor = UIColor(red: 220.0/255.0, green: 220.0/255.0, blue: 220.0/255.0, alpha: 1.0)
        return picker
    }()
    /// 格式化器
    private let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone.current
        return formatter
    }()
    /// 日历
    private lazy var calendar: Calendar = {
        var calendar = Calendar.current
        calendar.timeZone = TimeZone.current
        return calendar
    }()
    /// 日期显示
    private var rowLabel: UILabel {
        let label = UILabel()
        label.numberOfLines = 1
        label.textColor = textColor ?? .black
        label.textAlignment = .center
        label.font = font ?? .systemFont(ofSize: 16.0, weight: .medium)
        return label
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(picker)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func willMove(toSuperview newSuperview: UIView?) {
        if let _ = newSuperview {
            selectDate(maximumDate, animated: false)
        }
        super.willMove(toSuperview: newSuperview)
    }
    
    override func sizeToFit() {
        let contentSize = contentSize
        let autoresizingMask = autoresizingMask
        self.autoresizingMask = []
        var rect: CGRect = frame
        rect.size.width = contentSize.width
        rect.size.height = max(contentSize.height, 245.0)
        frame = rect
        self.autoresizingMask = autoresizingMask
    }
}

extension MNDatePicker {
    
    ///let dateString = Date.now.formatted(.iso8601.year().month().day().dateSeparator(.dash).dateTimeSeparator(.space).time(includingFractionalSeconds: false) .timeSeparator(.colon))
    
    /// 获取选择器最佳尺寸
    var contentSize: CGSize {
        if components.count <= 0 {
            reloadComponents()
        }
        let width = components.reduce(0.0, { $0 + $1.width }) + 100.0
        return CGSize(width: width, height: frame.height)
    }
    
    /// 当前选择的时间
    var date: Date {
        // 年
        var year: String = time.year
        if let index = components.indexOfYear {
            let component = components[index]
            let row = picker.selectedRow(inComponent: index)
            year = self.year(of: component.rows[row])
        }
        // 月
        var month: String = time.month
        if let index = components.indexOfMonth {
            let row = picker.selectedRow(inComponent: index)
            month = "\(row + 1)"
            if month.count == 1 {
                month.insert("0", at: month.startIndex)
            }
        }
        // 日
        var day: String = time.day
        if let index = components.indexOfDay {
            reloadDayComponent()
            let component = components[index]
            let row = picker.selectedRow(inComponent: index)
            day = component.rows[row]
            if day.count == 1 {
                day.insert("0", at: day.startIndex)
            }
        }
        // 时
        var hour: String = time.hour
        if let index = components.indexOfHour, let module = modules.hour {
            let component = components[index]
            let row = picker.selectedRow(inComponent: index)
            var value: Int = NSDecimalNumber(string: component.rows[row]).intValue
            if module.is12HourClock {
                // 需要转换为24时制
                if value == 12 { value = 0 }
                if let section = components.indexOfStage, picker.selectedRow(inComponent: section) == 1 {
                    // 下午
                    value += 12
                }
            }
            hour = "\(value)"
            if hour.count == 1 {
                hour.insert("0", at: hour.startIndex)
            }
        }
        // 分
        var minute: String = time.minute
        if let index = components.indexOfMinute {
            let component = components[index]
            let row = picker.selectedRow(inComponent: index)
            minute = component.rows[row]
            if minute.count == 1 {
                minute.insert("0", at: minute.startIndex)
            }
        }
        // 秒
        var second: String = time.second
        if let index = components.indexOfSecond {
            let component = components[index]
            let row = picker.selectedRow(inComponent: index)
            second = component.rows[row]
            if second.count == 1 {
                second.insert("0", at: second.startIndex)
            }
        }
        // 生成时间
        let string: String = "\(year)-\(month)-\(day) \(hour):\(minute):\(second)"
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.date(from: string) ?? maximumDate
    }
    
    /// 指定选择日期
    /// - Parameters:
    ///   - date: 日期
    ///   - animated: 是否使用动画
    func selectDate(_ date: Date, animated: Bool) {
        
        // 刷新配件
        if components.count <= 0 {
            reloadComponents()
        }
        
        formatter.dateFormat = "yyyy M d H m s"
        let selectDate: Date = min(max(minimumDate, date), maximumDate)
        let times: [String] = formatter.string(from: selectDate).components(separatedBy: " ")
        let time: Time = Time(year: times[0], month: times[1], day: times[2], hour: times[3], minute: times[4], second: times[5])
        
        for (index, component) in components.enumerated() {
            switch component.style {
            case .year:
                // 年
                guard let module = modules.year else { continue }
                var string: String = time.year
                if module.isAbbr {
                    let begin = string.startIndex
                    let end = string.index(string.startIndex, offsetBy: 1)
                    string.removeSubrange(begin...end)
                }
                if let idx = component.rows.firstIndex(of: string) {
                    picker.selectRow(idx, inComponent: index, animated: animated)
                }
            case .month:
                // 月
                guard let module = modules.month else { continue }
                let month: Int = NSDecimalNumber(string: time.month).intValue
                let months: [String] = months(of: module.lang, abbr: module.isAbbr)
                let string: String = months[month - 1]
                if let idx = component.rows.firstIndex(of: string) {
                    picker.selectRow(idx, inComponent: index, animated: animated)
                }
            case .day:
                // 天
                guard let module = modules.day else { continue }
                var string: String = time.day
                if module.isAbbr == false, string.count == 1 {
                    string.insert("0", at: string.startIndex)
                }
                if let idx = component.rows.firstIndex(of: string) {
                    picker.selectRow(idx, inComponent: index, animated: animated)
                }
            case .hour:
                // 时段
                guard let module = modules.hour else { continue }
                let is12HourClock = module.is12HourClock
                let hour: Int = NSDecimalNumber(string: time.hour).intValue
                if is12HourClock, let section = components.indexOfStage {
                    let idx = hour < 12 ? 0 : 1
                    picker.selectRow(idx, inComponent: section, animated: animated)
                }
                // 时
                var string: String = time.hour
                if is12HourClock {
                    formatter.dateFormat = "yyyy MM dd h mm ss"
                    let array: [String] = formatter.string(from: selectDate).components(separatedBy: " ")
                    if array.count > 3 {
                        string = array[3]
                    }
                }
                if module.isAbbr == false, string.count == 1 {
                    string.insert("0", at: string.startIndex)
                }
                if let idx = component.rows.firstIndex(of: string) {
                    picker.selectRow(idx, inComponent: index, animated: animated)
                }
            case .minute:
                // 分
                guard let module = modules.minute else { continue }
                var string: String = time.minute
                if module.isAbbr == false, string.count == 1 {
                    string.insert("0", at: string.startIndex)
                }
                if let idx = component.rows.firstIndex(of: string) {
                    picker.selectRow(idx, inComponent: index, animated: animated)
                }
            case .second:
                // 秒
                guard let module = modules.second else { continue }
                var string: String = time.second
                if module.isAbbr == false, string.count == 1 {
                    string.insert("0", at: string.startIndex)
                }
                if let idx = component.rows.firstIndex(of: string) {
                    picker.selectRow(idx, inComponent: index, animated: animated)
                }
            default: break
            }
        }
        
        // 刷新日配件
        reloadDayComponent()
    }
    
    /// 重载配件
    func reloadComponents() {
        
        if minimumDate >= maximumDate {
            minimumDate = Date(timeIntervalSince1970: 0.0)
        }
        if maximumDate == minimumDate {
            maximumDate = Date()
        }
        
        formatter.dateFormat = "yyyy MM dd HH mm ss"
        let times = formatter.string(from: maximumDate).components(separatedBy: " ")
        time.year = times[0]
        time.month = times[1]
        time.day = times[2]
        time.hour = times[3]
        time.minute = times[4]
        time.second = times[5]
        
        let font: UIFont = font ?? .systemFont(ofSize: 16.0, weight: .medium)
        
        // 年
        components.removeAll()
        if let module = modules.year {
            
            formatter.dateFormat = "yyyy"
            
            let minYear: Int = NSDecimalNumber(string: formatter.string(from: minimumDate)).intValue
            let maxYear: Int = NSDecimalNumber(string: formatter.string(from: maximumDate)).intValue
            
            let isAbbr: Bool = module.isAbbr
            let component = Component(style: .year)
            for year in minYear...maxYear {
                var string: String = "\(year)"
                if isAbbr {
                    let begin = string.startIndex
                    let end = string.index(string.startIndex, offsetBy: 1)
                    string.removeSubrange(begin...end)
                }
                component.rows.append(string)
            }
            component.widthToFit(font: font, padding: spacing)
            components.append(component)
            
            append(suffix: module.suffix)
        }
        
        // 月
        if let module = modules.month {
            let component = Component(style: .month)
            component.rows = months(of: module.lang, abbr: module.isAbbr)
            component.widthToFit(font: font, padding: spacing)
            components.append(component)
            
            append(suffix: module.suffix)
        }
        
        // 日
        if let module = modules.day {
            
            let isAbbr: Bool = module.isAbbr
            let component = Component(style: .day)
            for day in 1..<32 {
                var string: String = "\(day)"
                if isAbbr == false, string.count == 1 {
                    string.insert("0", at: string.startIndex)
                }
                component.rows.append(string)
            }
            component.width = ceil(("00" as NSString).size(withAttributes: [.font:font]).width) + spacing
            components.append(component)
            
            append(suffix: module.suffix)
        }
        
        // 时
        if let module = modules.hour {
            
            let isAbbr: Bool = module.isAbbr
            let is12HourClock: Bool = module.is12HourClock
            
            if is12HourClock {
                // 时段
                let component = Component(style: .stage)
                component.rows = stages(of: module.lang, abbr: isAbbr)
                component.widthToFit(font: font, padding: 10.0)
                components.append(component)
            }
            
            let component = Component(style: .hour)
            let begin: Int = is12HourClock ? 1 : 0
            let end: Int = is12HourClock ? 13 : 24
            for hour in begin..<end {
                var string: String = "\(hour)"
                if isAbbr == false, string.count == 1 {
                    string.insert("0", at: string.startIndex)
                }
                component.rows.append(string)
            }
            component.width = ceil(("00" as NSString).size(withAttributes: [.font:font]).width) + max(10.0, spacing - 3.0)
            components.append(component)
            
            append(suffix: module.suffix)
        }
        
        // 分
        if let module = modules.minute {
            
            let isAbbr: Bool = module.isAbbr
            let component = Component(style: .minute)
            for minute in 0..<60 {
                var string: String = "\(minute)"
                if isAbbr == false, string.count == 1 {
                    string.insert("0", at: string.startIndex)
                }
                component.rows.append(string)
            }
            component.width = ceil(("00" as NSString).size(withAttributes: [.font:font]).width) + max(10.0, spacing - 3.0)
            components.append(component)
            
            append(suffix: module.suffix)
        }
        
        // 秒
        if let module = modules.second {
            
            let isAbbr: Bool = module.isAbbr
            let component = Component(style: .second)
            for second in 0..<60 {
                var string: String = "\(second)"
                if isAbbr == false, string.count == 1 {
                    string.insert("0", at: string.startIndex)
                }
                component.rows.append(string)
            }
            component.width = ceil(("00" as NSString).size(withAttributes: [.font:font]).width) + max(10.0, spacing - 3.0)
            components.append(component)
            
            append(suffix: module.suffix)
        }
        
        // 刷新选择器
        picker.reloadAllComponents()
        // 刷新日配件
        reloadDayComponent()
    }
    
    /// 刷新日配件
    private func reloadDayComponent() {
        
        var year: String = time.year
        if let index = components.indexOfYear {
            let component = components[index]
            let row = picker.selectedRow(inComponent: index)
            year = self.year(of: component.rows[row])
        }
        
        var month: String = time.month
        if let index = components.indexOfMonth {
            let row = picker.selectedRow(inComponent: index)
            month = "\(row + 1)"
            if month.count == 1 {
                month.insert("0", at: month.startIndex)
            }
        }
        
        // 日期
        let string = "\(year)-\(month)-01 12:00:00"
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        guard let date = formatter.date(from: string) else { return }
        
        // 天数
        guard let range = calendar.range(of: .day, in: .month, for: date) else { return }
        let numberOfDays = range.count
        
        // 日配件
        guard let index = components.indexOfDay else { return }
        let component = components[index]
        
        // 计算天数是否对应
        if component.rows.count == numberOfDays { return }
        if component.rows.count > numberOfDays {
            component.rows.removeSubrange(numberOfDays..<component.rows.count)
        } else {
            for day in component.rows.count..<numberOfDays {
                component.rows.append("\(day + 1)")
            }
        }
        picker.reloadComponent(index)
    }
    
    /// 追加后缀(间隔)
    /// - Parameter suffix: 后缀内容
    private func append(suffix: String) {
        guard suffix.count > 0 else { return }
        let component = Component(style: .suffix)
        component.rows.append(suffix)
        component.widthToFit(font: font ?? .systemFont(ofSize: 16.0, weight: .medium), padding: 0.0)
        components.append(component)
    }
    
    /// 依据条件获取午段集合
    /// - Parameters:
    ///   - lang: 语言
    ///   - abbr: 使用简写形式
    /// - Returns: 午段集合
    private func stages(of lang: MNDatePicker.Language, abbr: Bool) -> [String] {
        switch lang {
        case .chinese: return ["上午", "下午"]
        default: return abbr ? ["A", "P"] : ["AM", "PM"]
        }
    }
    
    /// 依据条件获取月份集合
    /// - Parameters:
    ///   - lang: 语言
    ///   - abbr: 使用简写形式
    /// - Returns: 月份集合
    private func months(of lang: MNDatePicker.Language, abbr: Bool) -> [String] {
        switch lang {
        case .arabic:
            return abbr ? ["1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11", "12"] : ["01", "02", "03", "04", "05", "06", "07", "08", "09", "10", "11", "12"]
        case .english:
            return abbr ? ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"] : ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]
        case .chinese: return ["一月", "二月", "三月", "四月", "五月", "六月", "七月", "八月", "九月", "十月", "十一月", "十二月"]
        }
    }
    
    /// 获取年份全写
    /// - Parameter string: 年份
    /// - Returns: 年份全写
    private func year(of string: String) -> String {
        let year: Int = (string as NSString).integerValue
        guard year < 100 else { return string }
        let prefix: String = year >= 70 ? "19" : "20"
        return prefix + string
    }
}

// MARK: - UIPickerViewDelegate, UIPickerViewDataSource
extension MNDatePicker: UIPickerViewDelegate, UIPickerViewDataSource {
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int { components.count }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int { components[component].rows.count }
    
    func pickerView(_ pickerView: UIPickerView, widthForComponent component: Int) -> CGFloat { components[component].width }
    
    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat { rowHeight }
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        let label: UILabel = (view as? UILabel) ?? rowLabel
        label.text = components[component].rows[row]
        label.sizeToFit()
        return label
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        switch components[component].style {
        case .year:
            reloadDayComponent()
        case .month:
            reloadDayComponent()
        default: break
        }
    }
}
