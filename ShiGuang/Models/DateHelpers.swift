import Foundation

enum DateHelpers {
    static let dayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy年M月d日"
        return f
    }()

    static let shortFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "M月d日"
        return f
    }()

    static let weekdayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEEE"
        f.locale = Locale(identifier: "zh_CN")
        return f
    }()

    static func daysSince(_ date: Date) -> Int {
        let cal = Calendar.current
        let start = cal.startOfDay(for: date)
        let end = cal.startOfDay(for: Date())
        let comps = cal.dateComponents([.day], from: start, to: end)
        return comps.day ?? 0
    }

    static func relativeLabel(for date: Date) -> String {
        let days = daysSince(date)
        if days == 0 { return "今天" }
        if days == 1 { return "昨天" }
        if days == 2 { return "前天" }
        if days > 0 && days < 30 { return "\(days) 天前" }
        if days >= 30 && days < 365 { return "\(days / 30) 个月前" }
        if days >= 365 { return "\(days / 365) 年前" }
        // future
        let future = -days
        if future == 1 { return "明天" }
        if future == 2 { return "后天" }
        return "\(future) 天后"
    }
}
