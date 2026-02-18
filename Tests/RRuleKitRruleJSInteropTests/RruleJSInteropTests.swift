//
//  RruleJSInteropTests.swift
//  RRuleKitRruleJSInteropTests
//

import Testing
import Foundation
import RRuleKit
import RRuleKitRruleJSInterop

@Suite("RruleJS Interop")
struct RruleJSInteropTests {

  var calendar: Calendar {
    var cal = Calendar(identifier: .gregorian)
    cal.timeZone = .gmt
    return cal
  }

  var style: RecurrenceRuleRFC5545FormatStyle {
    RecurrenceRuleRFC5545FormatStyle(calendar: calendar)
  }

  // MARK: - extractRRuleValue

  @Test("Extract RRULE value from rrule.js full string (LF)")
  func extractFromFullStringLF() {
    let input = "DTSTART:20120201T093000Z\nRRULE:FREQ=WEEKLY;INTERVAL=5;BYDAY=MO,FR"
    let value = extractRRuleValue(from: input)
    #expect(value == "FREQ=WEEKLY;INTERVAL=5;BYDAY=MO,FR")
  }

  @Test("Extract RRULE value from rrule.js full string (CRLF)")
  func extractFromFullStringCRLF() {
    let input = "DTSTART:20120201T093000Z\r\nRRULE:FREQ=DAILY;COUNT=5"
    let value = extractRRuleValue(from: input)
    #expect(value == "FREQ=DAILY;COUNT=5")
  }

  @Test("Extract RRULE value from single line RRULE: prefix")
  func extractFromRRulePrefixOnly() {
    #expect(extractRRuleValue(from: "RRULE:FREQ=MONTHLY") == "FREQ=MONTHLY")
    #expect(extractRRuleValue(from: "rrule:FREQ=YEARLY") == "FREQ=YEARLY")
  }

  @Test("Extract RRULE value from bare RECUR value (unchanged)")
  func extractFromBareValue() {
    let input = "FREQ=WEEKLY;BYDAY=MO"
    #expect(extractRRuleValue(from: input) == input)
  }

  @Test("Extract returns nil for empty or no RRULE")
  func extractReturnsNilWhenNoRRule() {
    #expect(extractRRuleValue(from: "") == nil)
    #expect(extractRRuleValue(from: "DTSTART:20120201T093000Z") == nil)
    #expect(extractRRuleValue(from: "FOO=BAR") == nil)
  }

  // MARK: - containsSecondly

  @Test("Contains SECONDLY in value or full string")
  func containsSecondlyDetects() {
    #expect(containsSecondly("FREQ=SECONDLY;INTERVAL=1") == true)
    #expect(containsSecondly("FREQ=SECONDLY") == true)
    #expect(containsSecondly("DTSTART:20250101T000000Z\nRRULE:FREQ=SECONDLY;COUNT=10") == true)
    #expect(containsSecondly("FREQ=DAILY;COUNT=5") == false)
    #expect(containsSecondly("FREQ=MINUTELY") == false)
  }

  @Test("Contains SECONDLY when no RRULE value can be extracted (uses raw string)")
  func containsSecondlyWhenNoExtractableValue() {
    // extractRRuleValue returns nil (no FREQ= prefix, no RRULE:); containsSecondly falls back to contentOrValue
    #expect(containsSecondly("DTSTART:20250101T000000Z\nNOT_RRULE:FREQ=SECONDLY") == true)
    #expect(containsSecondly("PREFIX_FREQ=SECONDLY_SUFFIX") == true)
    #expect(containsSecondly("DTSTART:20250101T000000Z") == false)
  }

  // MARK: - parse (from rrule.js format)

  @Test("Parse full rrule.js string succeeds")
  func parseFullRruleJsString() throws {
    let input = "DTSTART:20120201T093000Z\nRRULE:FREQ=WEEKLY;INTERVAL=2;BYDAY=MO,FR"
    let rule = try parse(input, style: style)
    #expect(rule.frequency == .weekly)
    #expect(rule.interval == 2)
    #expect(rule.weekdays == [.every(.monday), .every(.friday)])
  }

  @Test("Parse bare RECUR value succeeds")
  func parseBareValue() throws {
    let rule = try parse("FREQ=DAILY;COUNT=5", style: style)
    #expect(rule.frequency == .daily)
    #expect(rule.end == .afterOccurrences(5))
  }

  @Test("Parse throws noRRuleValue when no RRULE value can be extracted")
  func parseThrowsNoRRuleValue() throws {
    do {
      _ = try parse("DTSTART:20120201T093000Z", style: RecurrenceRuleRFC5545FormatStyle(calendar: calendar))
      #expect(Bool(false), "Expected noRRuleValue")
    } catch RruleJSInteropError.noRRuleValue { }
    do {
      _ = try parse("", style: RecurrenceRuleRFC5545FormatStyle(calendar: calendar))
      #expect(Bool(false), "Expected noRRuleValue")
    } catch RruleJSInteropError.noRRuleValue { }
  }

  @Test("Parse throws secondlyNotSupported for FREQ=SECONDLY")
  func parseThrowsSecondly() throws {
    do {
      _ = try parse("FREQ=SECONDLY;INTERVAL=1", style: RecurrenceRuleRFC5545FormatStyle(calendar: calendar))
      #expect(Bool(false), "Expected secondlyNotSupported")
    } catch RruleJSInteropError.secondlyNotSupported { }
    do {
      _ = try parse("DTSTART:20250101T000000Z\nRRULE:FREQ=SECONDLY;COUNT=5", style: RecurrenceRuleRFC5545FormatStyle(calendar: calendar))
      #expect(Bool(false), "Expected secondlyNotSupported")
    } catch RruleJSInteropError.secondlyNotSupported { }
  }

  @Test("Parse throws parseError for invalid RECUR value")
  func parseThrowsParseError() throws {
    do {
      _ = try parse("FREQ=INVALID", style: RecurrenceRuleRFC5545FormatStyle(calendar: calendar))
      #expect(Bool(false), "Expected parseError")
    } catch RruleJSInteropError.parseError { }
  }

  // MARK: - formatForRruleJS

  @Test("Format for rrule.js with dtstart includes DTSTART and RRULE:")
  func formatWithDtstart() throws {
    let rule = Calendar.RecurrenceRule(calendar: calendar, frequency: .weekly, weekdays: [.every(.monday)])
    let date = try #require(DateComponents(calendar: calendar, year: 2025, month: 1, day: 6, hour: 10, minute: 30, second: 0).date)
    let result = formatForRruleJS(rule, dtstart: date, style: style)
    #expect(result.hasPrefix("DTSTART:20250106T103000Z"))
    #expect(result.contains("\nRRULE:FREQ=WEEKLY"))
    #expect(result.contains("BYDAY=MO"))
  }

  @Test("Format for rrule.js without dtstart is RRULE: value only")
  func formatWithoutDtstart() {
    let rule = Calendar.RecurrenceRule(calendar: calendar, frequency: .daily, interval: 2)
    let result = formatForRruleJS(rule, dtstart: nil, style: style)
    #expect(result.hasPrefix("RRULE:"))
    #expect(!result.contains("DTSTART"))
    #expect(result.contains("FREQ=DAILY"))
    #expect(result.contains("INTERVAL=2"))
  }

  @Test("Round-trip: parse rrule.js string then format then parse again (semantics preserved)")
  func roundTripSemanticsPreserved() throws {
    let full = "DTSTART:20250101T090000Z\nRRULE:FREQ=WEEKLY;INTERVAL=2;BYDAY=MO,WE;COUNT=10"
    let rule = try parse(full, style: style)
    let formatted = formatForRruleJS(rule, dtstart: nil, style: style)
    let extracted = extractRRuleValue(from: formatted)
    let reparsed = try parse(extracted ?? formatted, style: style)
    #expect(rule.frequency == reparsed.frequency)
    #expect(rule.interval == reparsed.interval)
    #expect(rule.weekdays == reparsed.weekdays)
    #expect(rule.end == reparsed.end)
  }
}
