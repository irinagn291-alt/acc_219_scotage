import Foundation

/// Role: Face. Day keys are Int YYYYMMDD from Calendar.startOfDay in the user's zone.
enum FaceDay {
    static func key(for date: Date, calendar: Calendar = .current) -> Int {
        let start = calendar.startOfDay(for: date)
        let year = calendar.component(.year, from: start)
        let month = calendar.component(.month, from: start)
        let day = calendar.component(.day, from: start)
        return year * 10_000 + month * 100 + day
    }

    static func monthKey(for date: Date, calendar: Calendar = .current) -> Int {
        monthKey(dayKey: key(for: date, calendar: calendar))
    }

    static func monthKey(dayKey: Int) -> Int {
        dayKey / 100
    }
}
