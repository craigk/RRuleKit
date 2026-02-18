//
//  RecurrenceRuleRFC5545ParseTests.swift
//  RRuleKit
//
//  Created by kubens.com on 12/01/2025.
//

import Testing
import Foundation
@testable import RRuleKit

@Suite("Recurrence Rule RFC 5545 Parsing Tests")
struct RecurrenceRuleRFC5545ParseTests {

  let calendar: Calendar
  let parser: RecurrenceRuleRFC5545FormatStyle

  init() {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = .gmt

    self.calendar = calendar
    self.parser = RecurrenceRuleRFC5545FormatStyle(calendar: calendar)
  }

  @Suite("Rule Part Test")
  struct RulePartTests {

    let parser: RecurrenceRuleRFC5545FormatStyle

    init() {
      var calendar = Calendar(identifier: .gregorian)
      calendar.timeZone = .gmt

      self.parser = RecurrenceRuleRFC5545FormatStyle(calendar: calendar)
    }

    @Test("Parse FREQ Rule Part", arguments: zip(
      ["MINUTELY", "HOURLY", "DAILY", "WEEKLY", "MONTHLY", "YEARLY"],
      [Calendar.RecurrenceRule.Frequency.minutely, .hourly, .daily, .weekly, .monthly, .yearly]
    ))
    func parseFrequencyRulePart(rfcFrequency: String, expected: Calendar.RecurrenceRule.Frequency) throws {
      let rfcString = "FREQ=\(rfcFrequency)"
      let result = try parser.parse(rfcString)

      #expect(result.frequency == expected)
    }

    @Test("Throws an error for invalid FREQ Rule Part")
    func throwsErrorForInvalidFrequencyRulePart() throws {
      #expect(throws: NSError.self) {
        try parser.parse("FREQ=FOOBAR")
      }
    }

    /// Ensures the public parse error contract: CocoaError with formatting code and NSCocoaErrorDomain.
    @Test("Parse failure throws CocoaError with formatting code and NSCocoaErrorDomain")
    func parseFailureThrowsStableErrorContract() throws {
      do {
        _ = try parser.parse("FREQ=FOOBAR")
        #expect(Bool(false), "Expected parse to throw")
      } catch let error as NSError {
        #expect(error.domain == NSCocoaErrorDomain)
        #expect(error.code == CocoaError.Code.formatting.rawValue)
      }
    }

    @Test("Parse INTERVAL Rule Part", arguments: zip(["INTERVAL=1", "INTERVAL=2", "INTERVAL=10"], [1, 2, 10]))
    func parseIntervalRulePart(rfcInterval: String, expected: Int) throws {
      let rfcString = "FREQ=DAILY;\(rfcInterval)"
      let result = try parser.parse(rfcString)

      #expect(result.interval == expected)
    }

    @Test("Throws an error for invalid INTERVAL Rule Part", arguments: [
      "INTERVAL=", "INTERVAL=-1", "INTERVAL=0", "INTERVAL=foo"
    ])
    func throwsErrorForInvalidIntervalRulePart(invalidInterval: String) throws {
      let rfcString = "FREQ=DAILY;\(invalidInterval)"
      #expect(throws: NSError.self) {
        try parser.parse(rfcString)
      }
    }

    @Test("Parses COUNT as a specific occurrence limit", arguments: zip(["COUNT=1", "COUNT=5"], [1, 5]))
    func parseCountRulePart(rfcCount: String, expectedCount: Int) throws {
      let rfcString = "FREQ=DAILY;\(rfcCount)"
      let expected = Calendar.RecurrenceRule.End.afterOccurrences(expectedCount)
      let result = try parser.parse(rfcString)

      #expect(result.end == expected)
    }

    @Test("Throws an error for invalid COUNT Rule Part", arguments: ["COUNT=", "COUNT=-2", "COUNT=1-", "COUNT=foobar"])
    func throwsErrorForInvalidCountRulePart(invalidCount: String) throws {
      let rfcString = "FREQ=DAILY;\(invalidCount)"

      #expect(throws: NSError.self, performing: {
        try parser.parse(rfcString)
      })
    }

    @Test("Parse UNTIL DATE-TIME with TZID Rule Part")
    func parseUntilDateTimeWithTzidRulePart() throws {
      let rfcString = "FREQ=DAILY;UNTIL=TZID=America/New_York:20250111T235959"
      let timeZone = try #require(TimeZone(identifier: "America/New_York"))

      var calendar = Calendar(identifier: .gregorian)
      calendar.timeZone = timeZone

      let parser = RecurrenceRuleRFC5545FormatStyle(calendar: calendar)
      let expected = Calendar.RecurrenceRule.End.afterDate(Date(timeIntervalSince1970: 1736657999))
      let result = try parser.parse(rfcString)

      #expect(result.end == expected)
    }

    @Test("Parse UNTIL DATE-TIME with UTC Rule Part")
    func parseUntilDateTimeWithUTCRulePart() throws {
      let rfcString = "FREQ=DAILY;UNTIL=20250111T235959Z"
      let expected = Calendar.RecurrenceRule.End.afterDate(Date(timeIntervalSince1970: 1736639999))
      let result = try parser.parse(rfcString)

      #expect(result.end == expected)
    }

    @Test("Parse UNTIL local DATE-TIME Rule Part")
    func parseUntilLocalDateTimeRulePart() throws {
      let rfcString = "FREQ=DAILY;UNTIL=20250111T235959"
      let expected = Calendar.RecurrenceRule.End.afterDate(Date(timeIntervalSince1970: 1736639999))
      let result = try parser.parse(rfcString)

      #expect(result.end == expected)
    }

    @Test("Parse UNTIL DATE Rule Part")
    func parseUntilDateRulePart() throws {
      let rfcString = "FREQ=DAILY;UNTIL=20250111"
      let expected = Calendar.RecurrenceRule.End.afterDate(Date(timeIntervalSince1970: 1736553600))
      let result = try parser.parse(rfcString)

      #expect(result.end == expected)
    }

    @Test("Parse UNTIL DATE-TIME with hour 00 (midnight) per RFC 5545")
    func parseUntilDateTimeWithHourZeroRulePart() throws {
      let rfcString = "FREQ=DAILY;UNTIL=20250111T003000Z"
      let result = try parser.parse(rfcString)
      // 2025-01-11 00:30:00 UTC = midnight + 30 minutes
      let expected = Calendar.RecurrenceRule.End.afterDate(Date(timeIntervalSince1970: 1736555400))
      #expect(result.end == expected)
    }

    @Test("Throws an error for invalid UNTIL Rule Part", arguments: ["UNTIL=20251350", "UNTIL=foobar", "UNTIL=1"])
    func throwsErrorForInvalidUntilRulePart(invalidString: String) throws {
      let rfcString = "FREQ=DAILY;\(invalidString)"

      #expect(throws: NSError.self, performing: {
        try parser.parse(rfcString)
      })
    }

    @Test("Throws an error when both UNTIL and COUNT are specified")
    func throwsErrorWhenUntilAndCountArePresent() throws {
      let rfcString = "FREQ=DAILY;UNTIL=20250111;COUNT=5"

      #expect(throws: NSError.self) {
        try parser.parse(rfcString)
      }
    }

    @Test("Parse BYSECOND Rule Part", arguments: zip(["BYSECOND=1", "BYSECOND=2,3"], [[1], [2, 3]]))
    func parseBySecondRulePart(rfcBySecond: String, expected: [Int]) throws {
      let rfcString = "FREQ=DAILY;\(rfcBySecond)"
      let result = try parser.parse(rfcString)

      #expect(result.seconds == expected)
    }

    @Test("Throws an error for invalid BYSECOND Rule Part", arguments: ["BYSECOND=", "BYSECOND=-1", "BYSECOND=foo"])
    func throwsErrorForInvalidBySecondRulePart(invalidString: String) throws {
      let rfcString = "FREQ=DAILY;\(invalidString)"
      
      #expect(throws: NSError.self, performing: {
        try parser.parse(rfcString)
      })
    }

    @Test("Parse BYMINUTE Rule Part", arguments: zip(["BYMINUTE=0", "BYMINUTE=0,30,59"], [[0], [0, 30, 59]]))
    func parseByMinuteRulePart(rfcByMinute: String, expected: [Int]) throws {
      let rfcString = "FREQ=DAILY;\(rfcByMinute)"
      let result = try parser.parse(rfcString)

      #expect(result.minutes == expected)
    }

    @Test("Throws an error for invalid BYMINUTE Rule Part", arguments: ["BYMINUTE=-1","BYMINUTE=60","BYMINUTE=foobar"])
    func throwsErrorForInvalidByMinuteRulePart(rfcByMinute: String) throws {
      let rfcString = "FREQ=DAILY;\(rfcByMinute)"

      #expect(throws: NSError.self) {
        try parser.parse(rfcString)
      }
    }

    @Test("Parse BYHOUR Rule Part", arguments: zip(["BYHOUR=0", "BYHOUR=0,12,23"], [[0], [0, 12, 23]]))
    func parseByHourRulePart(rfcByHour: String, expected: [Int]) throws {
      let rfcString = "FREQ=DAILY;\(rfcByHour)"
      let result = try parser.parse(rfcString)

      #expect(result.hours == expected)
    }

    @Test("Throws an error for invalid BYHOUR Rule Part", arguments: ["BYHOUR=-1", "BYHOUR=24", "BYHOUR=foobar"])
    func throwsErrorForInvalidByHourRulePart(rfcByHour: String) throws {
      let rfcString = "FREQ=DAILY;\(rfcByHour)"

      #expect(throws: NSError.self) {
        try parser.parse(rfcString)
      }
    }

    @Test("Parse BYDAY every weekday Rule Part", arguments: zip(
        ["BYDAY=MO", "BYDAY=TU", "BYDAY=WE", "BYDAY=TH", "BYDAY=FR", "BYDAY=SA", "BYDAY=SU"],
        [
          Calendar.RecurrenceRule.Weekday.every(.monday),
          .every(.tuesday),
          .every(.wednesday),
          .every(.thursday),
          .every(.friday),
          .every(.saturday),
          .every(.sunday),
        ]
      )
    )
    func parseByDayEveryWeekdayRulePart(rfcByDay: String, expected: Calendar.RecurrenceRule.Weekday) throws {
      let rfcString = "FREQ=DAILY;\(rfcByDay)"
      let result = try parser.parse(rfcString)

      #expect(result.weekdays == [expected])
    }

    @Test("Parse BYDAY Rule Part", arguments: zip(
        ["BYDAY=MO,1WE", "BYDAY=-1FR,MO"],
        [
          [Calendar.RecurrenceRule.Weekday.every(.monday), .nth(1, .wednesday)],
          [.nth(-1, .friday), .every(.monday)]
        ]
      )
    )
    func parseByDayRulePart(rfcByDay: String, expected: [Calendar.RecurrenceRule.Weekday]) throws {
      let rfcString = "FREQ=WEEKLY;\(rfcByDay)"
      let result = try parser.parse(rfcString)

      #expect(result.weekdays == expected)
    }

    @Test("Throws an error for invalid BYDAY Rule Part", arguments: ["BYDAY=BAR,1WE", "BYDAY=MO,1BAR"])
    func throwsErrorForInvalidByDayRulePart(invalidString: String) throws {
      let rfcString = "FREQ=WEEKLY;\(invalidString)"

      #expect(throws: NSError.self) {
        try parser.parse(rfcString)
      }
    }

    @Test("Parse BYMONTHDAY Rule Part", arguments: zip(
      ["BYMONTHDAY=1", "BYMONTHDAY=-31", "BYMONTHDAY=1,15,31"],
      [[1], [-31], [1, 15, 31]]
    ))
    func parseByMonthDayRulePart(rfcByMonthDay: String, expected: [Int]) throws {
      let rfcString = "FREQ=MONTHLY;\(rfcByMonthDay)"
      let result = try parser.parse(rfcString)

      #expect(result.daysOfTheMonth == expected)
    }

    @Test("Throws an error for invalid BYMONTHDAY Rule Part", arguments: [
      "BYMONTHDAY=", "BYMONTHDAY=-32", "BYMONTHDAY=32", "BYMONTHDAY=foobar"
    ])
    func throwsErrorForInvalidByMonthDayRulePart(invalidString: String) throws {
      let rfcString = "FREQ=MONTHLY;\(invalidString)"

      #expect(throws: NSError.self) {
        try parser.parse(rfcString)
      }
    }

    @Test("Parse BYYEARDAY Rule Part", arguments: zip(
      ["BYYEARDAY=1", "BYYEARDAY=-366", "BYYEARDAY=1,100,366"],
      [[1], [-366], [1, 100, 366]]
    ))
    func parseByYearDayRulePart(rfcByYearDay: String, expected: [Int]) throws {
      let rfcString = "FREQ=YEARLY;\(rfcByYearDay)"
      let result = try parser.parse(rfcString)

      #expect(result.daysOfTheYear == expected)
    }

    @Test("Throws an error for invalid BYYEARDAY Rule Part", arguments: [
      "BYYEARDAY=", "BYYEARDAY=-367", "BYYEARDAY=367", "BYYEARDAY=foobar"
    ])
    func throwsErrorForInvalidByYearDayRulePart(invalidString: String) throws {
      let rfcString = "FREQ=YEARLY;\(invalidString)"

      #expect(throws: NSError.self) {
        try parser.parse(rfcString)
      }
    }

    @Test("Parse BYWEEKNO Rule Part", arguments: zip(
      ["BYWEEKNO=1", "BYWEEKNO=-53", "BYWEEKNO=1,10,53"],
      [[1], [-53], [1, 10, 53]]
    ))
    func parseByWeekNoRulePart(rfcByWeekNo: String, expected: [Int]) throws {
      let rfcString = "FREQ=YEARLY;\(rfcByWeekNo)"
      let result = try parser.parse(rfcString)

      #expect(result.weeks == expected)
    }

    @Test("Throws an error for invalid BYWEEKNO values", arguments: [
      "BYWEEKNO=", "BYWEEKNO=-54", "BYWEEKNO=54", "BYWEEKNO=foobar"
    ])
    func throwsErrorForInvalidByWeekNoRulePart(invalidString: String) throws {
      let rfcString = "FREQ=YEARLY;\(invalidString)"

      #expect(throws: NSError.self) {
        try parser.parse(rfcString)
      }
    }

    @Test("Parses BYMONTH Rule Part", arguments: zip(
      ["BYMONTH=1", "BYMONTH=1,6,12"],
      [[Calendar.RecurrenceRule.Month(1)], [Calendar.RecurrenceRule.Month(1), .init(6), .init(12)]]
    ))
    func parseByMonthRulePart(rfcByMonth: String, expected: [Calendar.RecurrenceRule.Month]) throws {
      let rfcString = "FREQ=YEARLY;\(rfcByMonth)"
      let result = try parser.parse(rfcString)

      #expect(result.months == expected)
    }

    @Test("Throws an error for invalid BYMONTH Rule Part", arguments: [
      "BYMONTH=", "BYMONTH=0", "BYMONTH=13", "BYMONTH=foobar"
    ])
    func throwsErrorForInvalidByMonthRulePart(invalidString: String) throws {
      let rfcString = "FREQ=YEARLY;\(invalidString)"

      #expect(throws: NSError.self) {
        try parser.parse(rfcString)
      }
    }

    @Test("Parses BYSETPOS Rule Part", arguments: zip(
      ["BYSETPOS=1", "BYSETPOS=-5", "BYSETPOS=1,2,-1"],
      [[1], [-5], [1, 2, -1]]
    ))
    func parseBySetPosRulePart(rfcBySetPos: String, expected: [Int]) throws {
      let rfcString = "FREQ=MONTHLY;\(rfcBySetPos)"
      let result = try parser.parse(rfcString)

      #expect(result.setPositions == expected)
    }

    @Test("Throws an error for invalid BYSETPOS values", arguments: [
      "BYSETPOS=", "BYSETPOS=-367", "BYSETPOS=367", "BYSETPOS=foobar"
    ])
    func throwsErrorForInvalidBySetPosRulePart(invalidString: String) throws {
      let rfcString = "FREQ=MONTHLY;\(invalidString)"
      #expect(throws: NSError.self) {
        try parser.parse(rfcString)
      }
    }
  }

  /// RFC 5545: compliant applications MUST accept rule parts in any order.
  @Test("Parses rule when FREQ is not the first key (any order)")
  func parsesWhenFreqIsNotFirst() throws {
    let result = try parser.parse("COUNT=5;FREQ=DAILY")
    #expect(result.frequency == .daily)
    #expect(result.end == .afterOccurrences(5))
  }

  /// Exact key "FREQ" is required; "FREQUENCY" is not accepted.
  @Test("Throws an error when first key is FREQUENCY instead of FREQ")
  func throwsErrorWhenKeyIsFrequencyNotFreq() throws {
    #expect(throws: NSError.self) {
      try parser.parse("FREQUENCY=DAILY")
    }
  }

  @Test("Throws an error for FREQ=SECONDLY (unsupported)")
  func throwsErrorForSecondlyFrequency() throws {
    #expect(throws: NSError.self) {
      try parser.parse("FREQ=SECONDLY;INTERVAL=1")
    }
  }

  @Test("Throws an error for invalid RFC 5545 string format", arguments: [
    "", "FOO=BAR", "COUNT=1", "FREQ=MONTHLY:COUNT=2", "FREQ=MONTHLY;BYDAY=MO;WE"
  ])
  func throwErrorForInvalidRFC5545Format(rfcString: String) throws {
    #expect(throws: NSError.self) {
      try parser.parse(rfcString)
    }
  }

  @Test("Parse RFC 5545 format with multiple rule parts")
  func parseRFC5545FormatMultipleRuleParts() throws {
    let rfcString = "FREQ=MONTHLY;BYDAY=MO,TU;BYMONTH=1,6;BYSETPOS=1,-1;COUNT=5"

    let result = try parser.parse(rfcString)
    let expected = Calendar.RecurrenceRule(
      calendar: calendar,
      frequency: .monthly,
      end: .afterOccurrences(5),
      months: [1, 6],
      weekdays: [.every(.monday), .every(.tuesday)],
      setPositions: [1, -1]
    )

    #expect(result == expected)
  }

  @Test("Throws an error for duplicated keys in the RFC 5545 format",  arguments: [
    "FREQ=DAILY;FREQ=WEEKLY;COUNT=5", "FREQ=DAILY;COUNT=4;COUNT=5"
  ])
  func throwsErrorForDuplicatedKeysInRFC5545Format(rfcString: String) throws {
    #expect(throws: NSError.self) {
      try parser.parse(rfcString)
    }
  }

  /// RFC 5545 errata: BYDAY with numeric modifiers + BYWEEKNO in YEARLY can be invalid.
  /// The library does not reject this combination; parsing succeeds and semantics are left to Foundation.
  @Test("Parses YEARLY with BYWEEKNO and BYDAY ordinal (errata combination; library does not reject)")
  func parsesYearlyByWeekNoAndByDayOrdinal() throws {
    let rfcString = "FREQ=YEARLY;BYWEEKNO=1;BYDAY=1MO"
    let result = try parser.parse(rfcString)
    #expect(result.frequency == .yearly)
    #expect(result.weeks == [1])
    #expect(result.weekdays == [.nth(1, .monday)])
  }

  // MARK: - RFC 5545 case-insensitivity (Section 2, 3.1)

  @Test("Parse FREQ with lowercase value (case-insensitive)")
  func parseFreqLowerCase() throws {
    let result = try parser.parse("freq=daily")
    #expect(result.frequency == .daily)
  }

  @Test("Parse mixed-case key and value")
  func parseMixedCase() throws {
    let result = try parser.parse("FREQ=Weekly;ByDay=mo,we,fr")
    #expect(result.frequency == .weekly)
    #expect(result.weekdays == [.every(.monday), .every(.wednesday), .every(.friday)])
  }

  // MARK: - WKST (RFC 5545 Section 3.3.10)

  @Test("Parses rule with WKST (accepted and ignored; Foundation has no week-start API)")
  func parsesWithWkst() throws {
    let result = try parser.parse("FREQ=WEEKLY;WKST=SU;BYDAY=MO")
    #expect(result.frequency == .weekly)
    #expect(result.weekdays == [.every(.monday)])
  }

  // MARK: - Content-line unfolding (RFC 5545 Section 3.1)

  @Test("Parses folded content line (CRLF + SPACE removed)")
  func parsesFoldedContentLine() throws {
    let folded = "FREQ=DAILY;BYDAY=MO,\r\n TU,WE"
    let result = try parser.parse(folded)
    #expect(result.frequency == .daily)
    #expect(result.weekdays == [.every(.monday), .every(.tuesday), .every(.wednesday)])
  }

  @Test("Parses folded content line (LF + SPACE)")
  func parsesFoldedContentLineLF() throws {
    let folded = "FREQ=WEEKLY;COUNT=3\n ;BYDAY=MO"
    let result = try parser.parse(folded)
    #expect(result.frequency == .weekly)
    #expect(result.end == .afterOccurrences(3))
    #expect(result.weekdays == [.every(.monday)])
  }

  // MARK: - BYSECOND=60 (leap second, RFC 5545)

  @Test("Parses BYSECOND=60 (leap second per RFC 5545)")
  func parsesBySecond60() throws {
    let result = try parser.parse("FREQ=DAILY;BYSECOND=0,60")
    #expect(result.seconds == [0, 60])
  }

  // MARK: - ParseableFormatStyle API (RecurrenceRule+FormatStyle)

  @Test("Parse via RecurrenceRule init with strategy (ParseStrategy API)")
  func parseViaRecurrenceRuleInitWithStrategy() throws {
    let rfcString = "FREQ=WEEKLY;BYDAY=MO,FR;COUNT=5"
    let rule = try Calendar.RecurrenceRule(rfcString, strategy: parser)
    #expect(rule.frequency == .weekly)
    #expect(rule.weekdays == [.every(.monday), .every(.friday)])
    #expect(rule.end == .afterOccurrences(5))
  }
}
