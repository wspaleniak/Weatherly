//
//  String+WeatherFormatting.swift
//  Weatherly
//
//  Created by Wojciech Spaleniak on 23/11/2026.
//

import Foundation

extension String {
    /// Returns the hour and minute portion of an ISO 8601 weather timestamp.
    var hourLabel: String {
        guard let separator = firstIndex(of: "T") else {
            return self
        }
        return String(self[index(after: separator)...].prefix(5))
    }

    /// Returns a localized weekday label for an ISO 8601 date, or a localized label for today.
    ///
    /// - Parameter timezone: The time zone used to interpret the date. If `nil`, the current time zone is used.
    func dateLabel(timezone: TimeZone?) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = .autoupdatingCurrent
        dateFormatter.timeZone = timezone ?? .current
        dateFormatter.dateFormat = "yyyy-MM-dd"
        guard let date = dateFormatter.date(from: self) else {
            return self
        }
        if dateFormatter.string(from: .now) == self {
            return String(localized: "Details.today")
        }

        dateFormatter.dateFormat = "EEE"
        return dateFormatter.string(from: date)
    }
}
