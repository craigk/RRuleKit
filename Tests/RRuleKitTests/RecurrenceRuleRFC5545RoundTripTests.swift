//
//  RecurrenceRuleRFC5545RoundTripTests.swift
//  RRuleKit
//

import Testing
import Foundation
@testable import RRuleKit

@Suite("Recurrence Rule RFC 5545 Round-Trip Tests")
struct RecurrenceRuleRFC5545RoundTripTests {

  var calendar: Calendar {
    var cal = Calendar(identifier: .gregorian)
    cal.timeZone = .gmt
    return cal
  }

  var style: RecurrenceRuleRFC5545FormatStyle {
    RecurrenceRuleRFC5545FormatStyle(calendar: calendar)
  }

  @Test("Parse then format then parse matches original (simple rule)")
  func roundTripParseFormatParseSimple() throws {
    let rfcString = "FREQ=DAILY;INTERVAL=2;COUNT=5"
    let parsed = try style.parse(rfcString)
    let formatted = style.format(parsed)
    let reparsed = try style.parse(formatted)
    #expect(parsed == reparsed)
  }

  @Test("Parse then format then parse matches original (UNTIL date-only)")
  func roundTripParseFormatParseUntilDate() throws {
    let rfcString = "FREQ=DAILY;UNTIL=20250111"
    let parsed = try style.parse(rfcString)
    let formatted = style.format(parsed)
    let reparsed = try style.parse(formatted)
    #expect(parsed.end == reparsed.end)
    #expect(parsed.frequency == reparsed.frequency)
  }

  @Test("Parse then format then parse matches original (UNTIL date-time UTC)")
  func roundTripParseFormatParseUntilDateTimeUTC() throws {
    let rfcString = "FREQ=DAILY;UNTIL=20250111T235959Z"
    let parsed = try style.parse(rfcString)
    let formatted = style.format(parsed)
    let reparsed = try style.parse(formatted)
    #expect(parsed.end == reparsed.end)
  }

  /// Audit Phase 3.1: round-trip must cover UNTIL with TZID.
  @Test("Parse then format then parse matches original (UNTIL date-time with TZID)")
  func roundTripParseFormatParseUntilWithTzid() throws {
    let tz = try #require(TimeZone(identifier: "America/New_York"))
    var cal = Calendar(identifier: .gregorian)
    cal.timeZone = tz
    let styleWithTz = RecurrenceRuleRFC5545FormatStyle(calendar: cal)
    let rfcString = "FREQ=DAILY;UNTIL=TZID=America/New_York:20250111T235959"
    let parsed = try styleWithTz.parse(rfcString)
    let formatted = styleWithTz.format(parsed)
    let reparsed = try styleWithTz.parse(formatted)
    #expect(parsed.end == reparsed.end)
    #expect(parsed.frequency == reparsed.frequency)
  }

  @Test("Parse then format then parse matches original (rule with several BY* parts)")
  func roundTripParseFormatParseWithByParts() throws {
    let rfcString = "FREQ=MONTHLY;BYDAY=MO,TU;BYMONTH=1,6;BYSETPOS=1,-1;COUNT=5"
    let parsed = try style.parse(rfcString)
    let formatted = style.format(parsed)
    let reparsed = try style.parse(formatted)
    #expect(parsed == reparsed)
  }

  @Test("Format then parse then format matches original (simple rule)")
  func roundTripFormatParseFormatSimple() throws {
    let rrule = Calendar.RecurrenceRule(
      calendar: calendar,
      frequency: .weekly,
      interval: 1,
      weekdays: [.every(.monday), .every(.friday)]
    )
    let formatted = style.format(rrule)
    let parsed = try style.parse(formatted)
    let reformatted = style.format(parsed)
    #expect(formatted == reformatted)
  }

  @Test("Format then parse then format matches original (rule with UNTIL and BYDAY)")
  func roundTripFormatParseFormatWithUntilAndByDay() throws {
    let components = DateComponents(calendar: calendar, year: 2025, month: 6, day: 15)
    let endDate = try #require(components.date)
    let rrule = Calendar.RecurrenceRule(
      calendar: calendar,
      frequency: .weekly,
      end: .afterDate(endDate),
      weekdays: [.every(.monday), .nth(1, .wednesday)]
    )
    let formatted = style.format(rrule)
    let parsed = try style.parse(formatted)
    let reformatted = style.format(parsed)
    #expect(formatted == reformatted)
  }
}
