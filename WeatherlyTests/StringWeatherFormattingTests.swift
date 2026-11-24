import Foundation
import Testing
@testable import Weatherly

struct StringWeatherFormattingTests {
    @Test func `when timestamp contains an ISO time it returns the hour and minute`() {
        #expect("2026-11-20T18:30".hourLabel == "18:30")
    }

    @Test func `when timestamp has no time separator it returns the original string`() {
        #expect("not-a-timestamp".hourLabel == "not-a-timestamp")
    }

    @Test func `when date is today in the requested timezone it returns the localized today label`() throws {
        let timeZone = try #require(TimeZone(identifier: "Pacific/Auckland"))
        let formatter = DateFormatter()
        formatter.locale = .autoupdatingCurrent
        formatter.timeZone = timeZone
        formatter.dateFormat = "yyyy-MM-dd"
        let timestamp = formatter.string(from: .now)

        #expect(timestamp.dateLabel(timezone: timeZone) == String(localized: "Details.today"))
    }

    @Test func `when date is valid and not today it returns the localized weekday`() throws {
        let timeZone = try #require(TimeZone(secondsFromGMT: 0))
        let timestamp = "2020-02-03"

        let dateFormatter = DateFormatter()
        dateFormatter.locale = .autoupdatingCurrent
        dateFormatter.timeZone = timeZone
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let date = try #require(dateFormatter.date(from: timestamp))

        dateFormatter.dateFormat = "EEE"
        let expectedWeekday = dateFormatter.string(from: date)

        #expect(timestamp.dateLabel(timezone: timeZone) == expectedWeekday)
    }

    @Test func `when date is invalid it returns the original string`() throws {
        let timeZone = try #require(TimeZone(secondsFromGMT: 0))
        #expect("not-a-date".dateLabel(timezone: timeZone) == "not-a-date")
    }
}
