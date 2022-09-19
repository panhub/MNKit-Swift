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
        default: return false
        }
    }
    
    /// 后缀
    var suffix: String {
        switch self {
        case .spacing(let suffix): return suffix
        case .year(abbr: _, suffix: let suffix): return suffix
        case .month(abbr: _, lang: _, suffix: let suffix): return suffix
        case .day(abbr: _, suffix: let suffix): return suffix
        case .hour(abbr: _, lang: _, clock12: _, suffix: let suffix): return suffix
        case .minute(abbr: _, suffix: let suffix): return suffix
        case .second(abbr: _, suffix: let suffix): return suffix
        default: return ""
        }
    }
    
    /// 语言
    var language: MNDatePicker.Language {
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
            switch element.module {
            case .stage: return index
            default: break
            }
        }
        return nil
    }
    
    /// 获取年的配件索引
    var indexOfYear: Int? {
        for (index, element) in self.enumerated() {
            switch element.module {
            case .year(abbr: _, suffix: _): return index
            default: break
            }
        }
        return nil
    }
    
    /// 获取月的配件索引
    var indexOfMonth: Int? {
        for (index, element) in self.enumerated() {
            switch element.module {
            case .month(abbr: _, lang: _, suffix: _): return index
            default: break
            }
        }
        return nil
    }
    
    /// 获取日的配件索引
    var indexOfDay: Int? {
        for (index, element) in self.enumerated() {
            switch element.module {
            case .day(abbr: _, suffix: _): return index
            default: break
            }
        }
        return nil
    }
    
    /// 获取时的配件索引
    var indexOfHour: Int? {
        for (index, element) in self.enumerated() {
            switch element.module {
            case .hour(abbr: _, lang: _, clock12: _, suffix: _): return index
            default: break
            }
        }
        return nil
    }
    
    /// 获取分的配件索引
    var indexOfMinute: Int? {
        for (index, element) in self.enumerated() {
            switch element.module {
            case .minute(abbr: _, suffix: _): return index
            default: break
            }
        }
        return nil
    }
    
    /// 获取秒的配件索引
    var indexOfSecond: Int? {
        for (index, element) in self.enumerated() {
            switch element.module {
            case .second(abbr: _, suffix: _): return index
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
    
    /// 日期组件(午段 间隔 年 月 日 时 分 秒)
    enum Module {
        case stage
        case spacing(String)
        case year(abbr: Bool, suffix: String)
        case month(abbr: Bool, lang: MNDatePicker.Language, suffix: String)
        case day(abbr: Bool, suffix: String)
        case hour(abbr: Bool, lang: MNDatePicker.Language, clock12: Bool, suffix: String)
        case minute(abbr: Bool, suffix: String)
        case second(abbr: Bool, suffix: String)
    }
    
    /// 日期配件模型
    fileprivate class Component {
        /// 配件类型
        let module: MNDatePicker.Module
        /// 行数
        var rows: [String] = [String]()
        /// 行对应的时间(仅对年/月有效)
        var times: [String] = [String]()
        /// 配件宽度
        var width: CGFloat = 0.0
        
        init(module: MNDatePicker.Module) {
            self.module = module
        }
    }
    
    /// 字体
    var font: UIFont = .systemFont(ofSize: 16.0, weight: .medium)
    /// 字体颜色
    var textColor: UIColor = .black
    /// 组件集合
    var modules: [Module] = [.year(abbr: true, suffix: "-"), .month(abbr: true, lang: .english, suffix: "-"), .day(abbr: false, suffix: ""), .hour(abbr: false, lang: .arabic, clock12: true, suffix: ":"), .minute(abbr: false, suffix: ":"), .second(abbr: false, suffix: "")]
    /// 最早的时间
    var minimumDate: Date = Date(timeIntervalSince1970: 0.0)
    /// 最晚的时间
    var maximumDate: Date = Date()
    /// 行高
    var rowHeight: CGFloat = 40.0
    /// 记录当前时间
    private var time: Time = Time()
    /// 使用的选择器控件
    private let picker = UIPickerView()
    /// 组件集合
    private var components: [Component] = [Component]()
    /// 格式化器
    private let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone.current
        return formatter
    }()
    /// 日历
    private let calendar: Calendar = {
        var calendar = Calendar.current
        calendar.timeZone = TimeZone.current
        return calendar
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        picker.frame = bounds
        picker.delegate = self
        picker.dataSource = self
        picker.tintColor = UIColor(red: 220.0/255.0, green: 220.0/255.0, blue: 220.0/255.0, alpha: 1.0)
        addSubview(picker)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func willMove(toSuperview newSuperview: UIView?) {
        reloadComponents()
        layoutPicker()
        select(date: maximumDate, animated: false)
        reloadDayComponent()
        super.willMove(toSuperview: newSuperview)
    }
    
    private func layoutPicker() {
        var rect: CGRect = .zero
        rect.size.width = components.reduce(0.0, { $0 + $1.width })
        rect.size.width += (min(frame.width - rect.width, 100.0))
        rect.size.height = frame.height
        rect.origin.x = (frame.width - rect.width)/2.0
        picker.frame = rect
    }
}

extension MNDatePicker {
    
    /// 当前选择的时间
    var date: Date? {
        // 年
        var year: String = time.year
        if let index = components.indexOfYear {
            let component = components[index]
            let row = picker.selectedRow(inComponent: index)
            year = component.times[row]
        }
        // 月
        var month: String = time.month
        if let index = components.indexOfMonth {
            let component = components[index]
            let row = picker.selectedRow(inComponent: index)
            month = component.times[row]
        }
        // 日
        var day: String = time.day
        if let index = components.indexOfDay {
            let component = components[index]
            let row = picker.selectedRow(inComponent: index)
            day = component.rows[row]
            if day.count == 1 {
                day.insert("0", at: day.startIndex)
            }
        }
        // 时
        var hour: String = time.hour
        if let index = components.indexOfHour {
            let component = components[index]
            let row = picker.selectedRow(inComponent: index)
            var value: Int = NSDecimalNumber(string: component.rows[row]).intValue
            if component.module.is12HourClock {
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
        return formatter.date(from: string)
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
        
        // 年
        components.removeAll()
        if let module = modules.year {
            
            formatter.dateFormat = "yyyy"
            
            let minYear: Int = NSDecimalNumber(string: formatter.string(from: minimumDate)).intValue
            let maxYear: Int = NSDecimalNumber(string: formatter.string(from: maximumDate)).intValue
            
            let isAbbr: Bool = module.isAbbr
            let component = Component(module: module)
            component.width = ceil(((isAbbr ? "00" : "0000") as NSString).size(withAttributes: [.font:font]).width) + 15.0
            for year in minYear...maxYear {
                var string: String = "\(year)"
                component.times.append(string)
                if isAbbr {
                    let begin = string.startIndex
                    let end = string.index(string.startIndex, offsetBy: 1)
                    string.removeSubrange(begin...end)
                }
                component.rows.append(string)
            }
            components.append(component)
            
            append(spacing: module.suffix)
        }
        
        // 月
        if let module = modules.month {
            let component = Component(module: module)
            component.rows = months(of: module.language, abbr: module.isAbbr)
            component.times.append(contentsOf: ["01", "02", "03", "04", "05", "06", "07", "08", "09", "10", "11", "12"])
            let width = component.rows.reduce(0.0, { partialResult, string in
                let w = (string as NSString).size(withAttributes: [.font:font]).width
                return max(w, partialResult)
            })
            component.width = ceil(width) + 10.0
            components.append(component)
            
            append(spacing: module.suffix)
        }
        
        // 日
        if let module = modules.day {
            
            let isAbbr: Bool = module.isAbbr
            let component = Component(module: module)
            component.width = ceil(("00" as NSString).size(withAttributes: [.font:font]).width) + 15.0
            for day in 1..<32 {
                var string: String = "\(day)"
                if isAbbr == false, string.count == 1 {
                    string.insert("0", at: string.startIndex)
                }
                component.rows.append(string)
            }
            components.append(component)
            
            append(spacing: module.suffix)
        }
        
        // 时
        if let module = modules.hour {
            
            let isAbbr: Bool = module.isAbbr
            let is12HourClock: Bool = module.is12HourClock
            
            if is12HourClock {
                // 时段
                let component = Component(module: .stage)
                component.rows = stages(of: module.language, abbr: isAbbr)
                let width = component.rows.reduce(0.0, { partialResult, string in
                    let w = (string as NSString).size(withAttributes: [.font:font]).width
                    return max(w, partialResult)
                })
                component.width = ceil(width) + 10.0
                components.append(component)
            }
            
            let component = Component(module: module)
            component.width = ceil(("00" as NSString).size(withAttributes: [.font:font]).width) + 8.0
            let begin: Int = is12HourClock ? 1 : 0
            let end: Int = is12HourClock ? 13 : 24
            for hour in begin..<end {
                var string: String = "\(hour)"
                if isAbbr == false, string.count == 1 {
                    string.insert("0", at: string.startIndex)
                }
                component.rows.append(string)
            }
            components.append(component)
            
            append(spacing: module.suffix)
        }
        
        // 分
        if let module = modules.minute {
            
            let isAbbr: Bool = module.isAbbr
            let component = Component(module: module)
            component.width = ceil(("00" as NSString).size(withAttributes: [.font:font]).width) + 8.0
            for minute in 0..<60 {
                var string: String = "\(minute)"
                if isAbbr == false, string.count == 1 {
                    string.insert("0", at: string.startIndex)
                }
                component.rows.append(string)
            }
            components.append(component)
            
            append(spacing: module.suffix)
        }
        
        // 秒
        if let module = modules.second {
            
            let isAbbr: Bool = module.isAbbr
            let component = Component(module: module)
            component.width = ceil(("00" as NSString).size(withAttributes: [.font:font]).width) + 8.0
            for second in 0..<60 {
                var string: String = "\(second)"
                if isAbbr == false, string.count == 1 {
                    string.insert("0", at: string.startIndex)
                }
                component.rows.append(string)
            }
            components.append(component)
            
            append(spacing: module.suffix)
        }
    }
    
    /// 追加后缀(间隔)
    /// - Parameter suffix: 后缀内容
    func append(spacing suffix: String) {
        guard suffix.count > 0 else { return }
        let component = Component(module: .spacing(suffix))
        component.width = ceil((suffix as NSString).size(withAttributes: [.font:font]).width)
        component.rows.append(suffix)
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
    
    /// 指定选择日期
    /// - Parameters:
    ///   - date: 日期
    ///   - animated: 是否使用动画
    func select(date: Date, animated: Bool) {
        
        formatter.dateFormat = "yyyy M d H m s"
        let selectDate: Date = min(max(minimumDate, date), maximumDate)
        let times: [String] = formatter.string(from: selectDate).components(separatedBy: " ")
        let time: Time = Time(year: times[0], month: times[1], day: times[2], hour: times[3], minute: times[4], second: times[5])
        
        picker.reloadAllComponents()
        
        for (index, component) in components.enumerated() {
            switch component.module {
            case .year(abbr: let isAbbr, suffix: _):
                // 年
                var string: String = time.year
                if isAbbr {
                    let begin = string.startIndex
                    let end = string.index(string.startIndex, offsetBy: 1)
                    string.removeSubrange(begin...end)
                }
                if let idx = component.rows.firstIndex(of: string) {
                    picker.selectRow(idx, inComponent: index, animated: animated)
                }
            case .month(abbr: let isAbbr, lang: let lang, suffix: _):
                // 月
                let month: Int = NSDecimalNumber(string: time.month).intValue
                let months: [String] = months(of: lang, abbr: isAbbr)
                let string: String = months[month]
                if let idx = component.rows.firstIndex(of: string) {
                    picker.selectRow(idx, inComponent: index, animated: animated)
                }
            case .day(abbr: let isAbbr, suffix: _):
                // 天
                var string: String = time.day
                if isAbbr == false, string.count == 1 {
                    string.insert("0", at: string.startIndex)
                }
                if let idx = component.rows.firstIndex(of: string) {
                    picker.selectRow(idx, inComponent: index, animated: animated)
                }
            case .hour(abbr: let isAbbr, lang: _, clock12: let is12HourClock, suffix: _):
                // 时段
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
                if isAbbr == false, string.count == 1 {
                    string.insert("0", at: string.startIndex)
                }
                if let idx = component.rows.firstIndex(of: string) {
                    picker.selectRow(idx, inComponent: index, animated: animated)
                }
            case .minute(abbr: let isAbbr, suffix: _):
                // 分
                var string: String = time.minute
                if isAbbr == false, string.count == 1 {
                    string.insert("0", at: string.startIndex)
                }
                if let idx = component.rows.firstIndex(of: string) {
                    picker.selectRow(idx, inComponent: index, animated: animated)
                }
            case .second(abbr: let isAbbr, suffix: _):
                // 秒
                var string: String = time.second
                if isAbbr == false, string.count == 1 {
                    string.insert("0", at: string.startIndex)
                }
                if let idx = component.rows.firstIndex(of: string) {
                    picker.selectRow(idx, inComponent: index, animated: animated)
                }
            default: break
            }
        }
    }
    
    /// 刷新日配件
    private func reloadDayComponent() {
        
        var year: String = time.year
        if let index = components.indexOfYear {
            let component = components[index]
            let row = picker.selectedRow(inComponent: index)
            year = component.times[row]
        }
        
        var month: String = time.month
        if let index = components.indexOfMonth {
            let component = components[index]
            let row = picker.selectedRow(inComponent: index)
            month = component.times[row]
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
        //let row = picker.selectedRow(inComponent: index)
        if component.rows.count > numberOfDays {
            component.rows.removeSubrange(numberOfDays..<component.rows.count)
        } else {
            for day in component.rows.count..<numberOfDays {
                component.rows.append("\(day + 1)")
            }
        }
        picker.reloadComponent(index)
    }
}

// MARK: - UIPickerViewDelegate, UIPickerViewDataSource
extension MNDatePicker: UIPickerViewDelegate, UIPickerViewDataSource {
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int { components.count }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int { components[component].rows.count }
    
    func pickerView(_ pickerView: UIPickerView, widthForComponent component: Int) -> CGFloat { components[component].width }
    
    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat { rowHeight }
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        let label: UILabel = (view as? UILabel) ?? UILabel()
        label.font = font
        label.numberOfLines = 1
        label.textColor = textColor
        label.textAlignment = .center
        label.text = components[component].rows[row]
        label.sizeToFit()
        return label
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        switch components[component].module {
        case .year(abbr: _, suffix: _):
            reloadDayComponent()
        case .month(abbr: _, lang: _, suffix: _):
            reloadDayComponent()
        default: break
        }
    }
}
