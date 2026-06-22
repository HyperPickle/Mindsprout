import Foundation

enum TripDateFormat {
    private static let month: DateFormatter = formatter("MMM d")
    private static let fullDate: DateFormatter = formatter("d MMM yyyy")
    private static let day: DateFormatter = formatter("d")
    private static let year: DateFormatter = formatter("yyyy")

    static func range(_ start: Date, _ end: Date, includeYear: Bool, calendar: Calendar = .current) -> String {
        let sameMonth = calendar.isDate(start, equalTo: end, toGranularity: .month)
        let endText = sameMonth ? day.string(from: end) : month.string(from: end)
        var result = "\(month.string(from: start)) – \(endText)"
        if includeYear { result += " \(year.string(from: end))" }
        return result
    }

    static func dayDetail(_ date: Date) -> String {
        fullDate.string(from: date)
    }

    private static func formatter(_ format: String) -> DateFormatter {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US")
        f.dateFormat = format
        return f
    }
}
