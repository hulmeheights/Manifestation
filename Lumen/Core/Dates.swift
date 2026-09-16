//
//  Dates.swift
//  Lumen
//
//  Small formatting helpers. Lifted out of the old Theme file when that was
//  deleted, because these are the only bits of it anything still used.
//

import Foundation

extension Date {
    var shortDay: String {
        formatted(.dateTime.day().month(.abbreviated))
    }

    var longDay: String {
        formatted(.dateTime.weekday(.wide).day().month(.wide))
    }

    var timeOnly: String {
        formatted(date: .omitted, time: .shortened)
    }

    /// "Today" / "Yesterday" / "3 Mar"
    var relativeDayLabel: String {
        let calendar = Calendar.current
        if calendar.isDateInToday(self) { return "Today" }
        if calendar.isDateInYesterday(self) { return "Yesterday" }
        if calendar.isDateInTomorrow(self) { return "Tomorrow" }
        return shortDay
    }
}

extension Int {
    var repsLabel: String { self == 1 ? "1 rep" : "\(self) reps" }
    var daysLabel: String { self == 1 ? "1 day" : "\(self) days" }
}
