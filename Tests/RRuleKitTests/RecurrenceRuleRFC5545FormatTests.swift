//
//  RecurrenceRuleRFC5545FormatTests.swift
//  RRuleKit
//
//  Created by kubens.com on 13/01/2025.
//

import Testing
import Foundation
@testable import RRuleKit

@Suite("Recurrence Rule RFC 5545 Format Tests")
struct RecurrenceRuleRFC5545FormatTests {

  let calendar: Calendar
  let formatStyle: any FormatStyle

  init() {
    var calendar = Calendar(identifier: .iso8601)
    calendar.timeZone = .gmt

    self.calendar = calendar
    self.formatStyle = RecurrenceRuleRFC5545FormatStyle(calendar: calendar)
  }

  @Suite("Rule Part Tests")
  struct RulePartTests {

    let calendar: Calendar
    let formatStyle: RecurrenceRuleRFC5545FormatStyle

    init() {
      var calendar = Calendar(identifier: .iso8601)
      calendar.timeZone = .gmt

      self.calendar = calendar
      self.formatStyle = RecurrenceRuleRFC5545FormatStyle(calendar: calendar)
    }

    @Test("Format FREQ Rule Part", arguments: zip(
      [Calendar.RecurrenceRule.Frequency.minutely, .hourly, .daily, .weekly, .monthly, .yearly],
      ["FREQ=MINUTELY", "FREQ=HOURLY", "FREQ=DAILY", "FREQ=WEEKLY", "FREQ=MONTHLY", "FREQ=YEARLY"]
    ))
    func formatFrequencyRulePart(frequency: Calendar.RecurrenceRule.Frequency, expected: String) {
      let rrule = Calendar.RecurrenceRule(calendar: calendar, frequency: frequency)
      let result = formatStyle.format(rrule)

      #expect(result == expected)
    }

    @Test("Format INTERVAL Rule Part", arguments: zip([1, 2, 10], ["", "INTERVAL=2", "INTERVAL=10"]))
    func formatIntervalRulePart(_ interval: Int, intervalExpected: String) {
      let rrule = Calendar.RecurrenceRule(calendar: calendar, frequency: .daily, interval: interval)
      let expected = "FREQ=DAILY\(interval == 1 ? "" : ";INTERVAL=\(interval)")"
      let result = formatStyle.format(rrule)

      #expect(result == expected)
    }

    @Test("Format COUNT Rule Part", arguments: zip([1, 22, 100], ["COUNT=1", "COUNT=22", "COUNT=100"]))
    func formatCountRulePart(_ count: Int, expectedCount: String) {
      let rrule = Calendar.RecurrenceRule(calendar: calendar, frequency: .daily, end: .afterOccurrences(count))
      let expected = "FREQ=DAILY;\(expectedCount)"
      let result = formatStyle.format(rrule)

      #expect(result == expected)
    }

    @Test("Format UNTIL DATE-TIME with TZID Rule Part")
    func formatUntilDateTimeWithTzidRulePart() throws {
      let tz = try #require(TimeZone(identifier: "America/New_York"))
      var localCalendar = Calendar(identifier: .gregorian)
      localCalendar.timeZone = tz

      let formatter = RecurrenceRuleRFC5545FormatStyle(calendar: localCalendar)
      let components = DateComponents(calendar: localCalendar, year: 2025, month: 1, day: 18, hour: 10, minute: 22)

      let endDate = try #require(components.date)
      let rrule = Calendar.RecurrenceRule(calendar: localCalendar, frequency: .daily, end: .afterDate(endDate))
      let expected = "FREQ=DAILY;UNTIL=TZID=America/New_York:20250118T102200"
      let result = formatter.format(rrule)

      #expect(result == expected)
    }

    @Test("Format UNTIL DATE-TIME with UTC Rule Part")
    func formatUntilDateTimeWithUTCRulePart() throws {
      let formatter = RecurrenceRuleRFC5545FormatStyle(calendar: calendar)
      let components = DateComponents(calendar: calendar, year: 2025, month: 1, day: 18, hour: 10, minute: 26)

      let endDate = try #require(components.date)
      let rrule = Calendar.RecurrenceRule(calendar: calendar, frequency: .daily, end: .afterDate(endDate))
      let expected = "FREQ=DAILY;UNTIL=20250118T102600Z"
      let result = formatter.format(rrule)

      #expect(result == expected)
    }

    @Test("Format UNTIL DATE Rule Part")
    func formatUntilDateRulePart() throws {
      let formatter = RecurrenceRuleRFC5545FormatStyle(calendar: calendar)
      let components = DateComponents(calendar: calendar, year: 2025, month: 1, day: 18)

      let endDate = try #require(components.date)
      let rrule = Calendar.RecurrenceRule(calendar: calendar, frequency: .daily, end: .afterDate(endDate))
      let expected = "FREQ=DAILY;UNTIL=20250118"
      let result = formatter.format(rrule)

      #expect(result == expected)
    }

    @Test("Format BYSECOND Rule Part", arguments: zip([[], [1], [2, 3]], ["", "BYSECOND=1", "BYSECOND=2,3"]))
    func formatBySecondRulePart(bySeconds: [Int], bySecondExpected: String) {
      let formatter = RecurrenceRuleRFC5545FormatStyle(calendar: calendar)
      let rrule = Calendar.RecurrenceRule(calendar: calendar, frequency: .daily, seconds: bySeconds)
      let expected = "FREQ=DAILY\(bySeconds.isEmpty ? "" : ";\(bySecondExpected)")"
      let result = formatter.format(rrule)

      #expect(result == expected)
    }

    @Test("Format BYMINUTE Rule Part", arguments: zip([[], [1], [2, 3]], ["", "BYMINUTE=1", "BYMINUTE=2,3"]))
    func formatByMinuteRulePart(byMinutes: [Int], byMinuteExpected: String) {
      let formatter = RecurrenceRuleRFC5545FormatStyle(calendar: calendar)
      let rrule = Calendar.RecurrenceRule(calendar: calendar, frequency: .daily, minutes: byMinutes)
      let expected = "FREQ=DAILY\(byMinutes.isEmpty ? "" : ";\(byMinuteExpected)")"
      let result = formatter.format(rrule)

      #expect(result == expected)
    }

    @Test("Format BYHOUR Rule Part", arguments: zip([[], [1], [2, 3]], ["", "BYHOUR=1", "BYHOUR=2,3"]))
    func formatByHourRulePart(byMinutes: [Int], byHourExpected: String) {
      let formatter = RecurrenceRuleRFC5545FormatStyle(calendar: calendar)
      let rrule = Calendar.RecurrenceRule(calendar: calendar, frequency: .daily, hours: byMinutes)
      let expected = "FREQ=DAILY\(byMinutes.isEmpty ? "" : ";\(byHourExpected)")"
      let result = formatter.format(rrule)

      #expect(result == expected)
    }

    @Test("Format BYDAY every weekday Rule Part", arguments: zip(
      [
        Calendar.RecurrenceRule.Weekday.every(.monday),
        .every(.tuesday),
        .every(.wednesday),
        .every(.thursday),
        .every(.friday),
        .every(.saturday),
        .every(.sunday),
      ],
      ["BYDAY=MO", "BYDAY=TU", "BYDAY=WE", "BYDAY=TH", "BYDAY=FR", "BYDAY=SA", "BYDAY=SU"]
    ))
    func formatByDayEveryWeekdayRulePart(weekday: Calendar.RecurrenceRule.Weekday, byDayExpected: String) {
      let formatter = RecurrenceRuleRFC5545FormatStyle(calendar: calendar)
      let rrule = Calendar.RecurrenceRule(calendar: calendar, frequency: .daily, weekdays: [weekday])
      let expected = "FREQ=DAILY;\(byDayExpected)"
      let result = formatter.format(rrule)

      #expect(result == expected)
    }

    @Test("Format BYDAY Rule Part", arguments: zip(
      [
        [],
        [Calendar.RecurrenceRule.Weekday.every(.monday), .nth(1, .wednesday)],
        [.nth(-1, .friday), .every(.monday)],
      ],
      ["", "BYDAY=MO,1WE", "BYDAY=-1FR,MO"]
    ))
    func formatByDayRulePart(byDays: [Calendar.RecurrenceRule.Weekday], byDayExpected: String) {
      let formatter = RecurrenceRuleRFC5545FormatStyle(calendar: calendar)
      let rrule = Calendar.RecurrenceRule(calendar: calendar, frequency: .weekly, weekdays: byDays)
      let expected = "FREQ=WEEKLY\(byDays.isEmpty ? "" : ";\(byDayExpected)")"
      let result = formatter.format(rrule)

      #expect(result == expected)
    }

    @Test("Format BYMONTHDAY Rule Part", arguments: zip(
      [[], [1], [2, -3]],
      ["", "BYMONTHDAY=1", "BYMONTHDAY=2,-3"]
    ))
    func formatByMonthDayRulePart(byMonthDay: [Int], byMonthDayExpected: String) {
      let formatter = RecurrenceRuleRFC5545FormatStyle(calendar: calendar)
      let rrule = Calendar.RecurrenceRule(calendar: calendar, frequency: .monthly, daysOfTheMonth: byMonthDay)
      let expected = "FREQ=MONTHLY\(byMonthDay.isEmpty ? "" : ";\(byMonthDayExpected)")"
      let result = formatter.format(rrule)

      #expect(result == expected)
    }

    @Test("Format BYYEARDAY Rule Part", arguments: zip([[], [1], [2, 3]], ["", "BYYEARDAY=1", "BYYEARDAY=2,3"]))
    func formatByYearDayRulePart(byYearDay: [Int], byYearDayExpected: String) {
      let formatter = RecurrenceRuleRFC5545FormatStyle(calendar: calendar)
      let rrule = Calendar.RecurrenceRule(calendar: calendar, frequency: .yearly, daysOfTheYear: byYearDay)
      let expected = "FREQ=YEARLY\(byYearDay.isEmpty ? "" : ";\(byYearDayExpected)")"
      let result = formatter.format(rrule)

      #expect(result == expected)
    }

    @Test("Format BYWEEKNO", arguments: zip(
      [[], [1], [2, 3]],
      ["", "BYWEEKNO=1", "BYWEEKNO=2,3"]
    ))
    func formatByWeekNoRulePart(byWeekNo: [Int], byWeekNoExpected: String) {
      let formatter = RecurrenceRuleRFC5545FormatStyle(calendar: calendar)
      let rrule = Calendar.RecurrenceRule(calendar: calendar, frequency: .yearly, weeks: byWeekNo)
      let expected = "FREQ=YEARLY\(byWeekNo.isEmpty ? "" : ";\(byWeekNoExpected)")"
      let result = formatter.format(rrule)

      #expect(result == expected)
    }

    @Test("Format BYMONTH Rule Part", arguments: zip(
      [[], [Calendar.RecurrenceRule.Month(1)], [.init(2), .init(3)]],
      ["", "BYMONTH=1", "BYMONTH=2,3"]
    ))
    func formatByMonthRulePart(byMonth: [Calendar.RecurrenceRule.Month], byMontExpected: String) {
      let formatter = RecurrenceRuleRFC5545FormatStyle(calendar: calendar)
      let rrule = Calendar.RecurrenceRule(calendar: calendar, frequency: .yearly, months: byMonth)
      let expected = "FREQ=YEARLY\(byMonth.isEmpty ? "" : ";\(byMontExpected)")"
      let result = formatter.format(rrule)

      #expect(result == expected)
    }

    @Test("Format BYSETPOS Rule Part", arguments: zip(
      [[], [1], [2, 3]],
      ["", "BYSETPOS=1", "BYSETPOS=2,3"]
    ))
    func formatBySetPosRulePart(bySetPos: [Int], bySetPosExpected: String) {
      let formatter = RecurrenceRuleRFC5545FormatStyle(calendar: calendar)
      let rrule = Calendar.RecurrenceRule(calendar: calendar, frequency: .yearly, setPositions: bySetPos)
      let expected = "FREQ=YEARLY\(bySetPos.isEmpty ? "" : ";\(bySetPosExpected)")"
      let result = formatter.format(rrule)

      #expect(result == expected)
    }
  }

  @Test("Format large Recurrence Rule")
  func formatLargeRRule() {
    let formatter = RecurrenceRuleRFC5545FormatStyle(calendar: calendar)
    let rrule = Calendar.RecurrenceRule(
      calendar: calendar,
      frequency: .daily,
      interval: 2,
      end: .afterOccurrences(20),
      months: [1, 3, 6, 9, 12],
      daysOfTheYear: [1, 50, 100, 150, 200, 250, 300],
      daysOfTheMonth: [1, 10, 15, 20, 25, 31],
      weeks: [1, 10, 20, 30, 40, 50],
      weekdays: [
        .every(.monday),
        .every(.tuesday),
        .every(.wednesday),
        .every(.thursday),
        .every(.friday),
        .every(.saturday),
        .every(.sunday),
        .nth(1, .sunday)
      ],
      hours: [0, 6, 12, 18, 23],
      minutes: [0, 15, 30, 45, 59],
      seconds: [0, 10, 20, 30, 40, 50],
      setPositions: [1, -1, 5, 2, 4]
    )

    let result = formatter.format(rrule)
    // Semantic checks: key parts must be present (order and formatting may vary slightly)
    #expect(result.contains("FREQ=DAILY"))
    #expect(result.contains("INTERVAL=2"))
    #expect(result.contains("COUNT=20"))
    #expect(result.contains("BYMONTH=1,3,6,9,12"))
    #expect(result.contains("BYDAY=MO,TU,WE,TH,FR,SA,SU,1SU"))
    #expect(result.contains("BYSETPOS=1,-1,5,2,4"))
    #expect(result.utf8.count > 200)
  }

  // MARK: - RFC 5545 format options (folding, WKST)

  @Test("Format with foldLongLines keeps no line over 75 octets")
  func formatWithFolding() {
    let formatter = RecurrenceRuleRFC5545FormatStyle(calendar: calendar, foldLongLines: true)
    let rrule = Calendar.RecurrenceRule(
      calendar: calendar,
      frequency: .daily,
      interval: 2,
      end: .afterOccurrences(20),
      months: [1, 3, 6, 9, 12],
      daysOfTheMonth: [1, 10, 15, 20, 25, 31],
      weekdays: [.every(.monday), .every(.wednesday), .every(.friday)],
      hours: [8, 12, 18],
      minutes: [0, 30]
    )
    let result = formatter.format(rrule)
    // RFC 5545: folded lines are separated by CRLF + SPACE; each logical line is at most 75 octets
    let logicalLines = result.components(separatedBy: "\r\n ")
    if logicalLines.count == 1 {
      let alt = result.components(separatedBy: "\n ")
      for segment in alt {
        #expect(segment.utf8.count <= 75, "Segment exceeds 75 octets: \(segment.utf8.count)")
      }
    } else {
      for segment in logicalLines {
        #expect(segment.utf8.count <= 75, "Segment exceeds 75 octets: \(segment.utf8.count)")
      }
    }
    let unfolded = result.replacingOccurrences(of: "\r\n ", with: "").replacingOccurrences(of: "\n ", with: "")
    let oneLine = unfolded.replacingOccurrences(of: "\r\n", with: "").replacingOccurrences(of: "\n", with: "")
    #expect(oneLine.contains("FREQ=DAILY"))
    #expect(oneLine.contains("BYDAY=MO,WE,FR"))
  }

  @Test("Format with emitWKST appends WKST=MO")
  func formatWithEmitWKST() {
    let formatter = RecurrenceRuleRFC5545FormatStyle(calendar: calendar, emitWKST: true)
    let rrule = Calendar.RecurrenceRule(calendar: calendar, frequency: .weekly, weekdays: [.every(.monday)])
    let result = formatter.format(rrule)
    #expect(result.hasSuffix(";WKST=MO"))
    #expect(result.contains("FREQ=WEEKLY"))
  }

  @Test("Format default does not emit WKST")
  func formatDefaultNoWKST() {
    let formatter = RecurrenceRuleRFC5545FormatStyle(calendar: calendar)
    let rrule = Calendar.RecurrenceRule(calendar: calendar, frequency: .weekly)
    let result = formatter.format(rrule)
    #expect(!result.contains("WKST="))
  }

  // MARK: - FormatStyle API (RecurrenceRule+FormatStyle)

  @Test("Format via rule.formatted(style) (FormatStyle API)")
  func formatViaFormattedStyle() {
    let formatter = RecurrenceRuleRFC5545FormatStyle(calendar: calendar)
    let rrule = Calendar.RecurrenceRule(calendar: calendar, frequency: .daily, interval: 2, end: .afterOccurrences(10))
    let result = rrule.formatted(formatter)
    #expect(result.contains("FREQ=DAILY"))
    #expect(result.contains("INTERVAL=2"))
    #expect(result.contains("COUNT=10"))
  }
}
