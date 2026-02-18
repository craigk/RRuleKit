//
//  RruleJSInterop.swift
//  RRuleKitRruleJSInterop
//
//  Add-on for interoperability with jkbrzt/rrule (JavaScript).
//  Normalizes between rrule.js content-line format (DTSTART + RRULE:) and RRuleKit's RRULE value only.
//

import Foundation
import RRuleKit

// MARK: - Errors

/// Errors thrown by the rrule.js interop layer.
public enum RruleJSInteropError: Error, Sendable {
  /// The string contains `FREQ=SECONDLY`, which RRuleKit does not support (Foundation has no `.secondly`).
  case secondlyNotSupported
  /// No RRULE value could be extracted from the input (e.g. missing `RRULE:` or invalid structure).
  case noRRuleValue
  /// Underlying parse error from RRuleKit (e.g. invalid RECUR value).
  case parseError(underlying: Error)
}

// MARK: - Extracting RRULE value from rrule.js output

/// Extracts the RRULE property value from an rrule.js–style string.
///
/// rrule.js `toString()` returns:
/// ```text
/// DTSTART:20120201T093000Z
/// RRULE:FREQ=WEEKLY;INTERVAL=5;UNTIL=20130130T230000Z;BYDAY=MO,FR
/// ```
/// This function returns the part after `RRULE:` (the RECUR value only). It also accepts:
/// - A single line starting with `RRULE:` (e.g. `RRULE:FREQ=DAILY`)
/// - A string that is already just the RECUR value (e.g. `FREQ=DAILY;COUNT=5`)
///
/// - Parameter contentLineOrValue: Full content (with optional DTSTART and RRULE: prefix) or bare RECUR value.
/// - Returns: The RECUR value (e.g. `FREQ=WEEKLY;...`) to pass to RRuleKit, or `nil` if no RRULE value could be found.
public func extractRRuleValue(from contentLineOrValue: String) -> String? {
  let trimmed = contentLineOrValue.trimmingCharacters(in: .whitespacesAndNewlines)
  guard !trimmed.isEmpty else { return nil }

  // Already looks like a RECUR value: starts with FREQ= (case-insensitive)
  if trimmed.uppercased().hasPrefix("FREQ=") {
    return trimmed
  }

  // Find "\r\nRRULE:" or "\nRRULE:" (case-insensitive)
  if let rruleRange = trimmed.range(of: "\r\nRRULE:", options: .caseInsensitive) {
    return String(trimmed[rruleRange.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
  }
  if let rruleRange = trimmed.range(of: "\nRRULE:", options: .caseInsensitive) {
    return String(trimmed[rruleRange.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
  }

  // Single line: "RRULE:value"
  if trimmed.uppercased().hasPrefix("RRULE:") {
    let valueStart = trimmed.index(trimmed.startIndex, offsetBy: 6)
    return String(trimmed[valueStart...]).trimmingCharacters(in: .whitespacesAndNewlines)
  }

  return nil
}

/// Returns whether the RECUR value (or a full content string) contains `FREQ=SECONDLY`.
/// Use before parsing to fail fast with a clear error.
public func containsSecondly(_ contentOrValue: String) -> Bool {
  let value: String
  if let extracted = extractRRuleValue(from: contentOrValue) {
    value = extracted
  } else {
    value = contentOrValue
  }
  return value.uppercased().contains("FREQ=SECONDLY")
}

// MARK: - Parse from rrule.js format

/// Parses an rrule.js–style string into a `Calendar.RecurrenceRule`.
///
/// 1. Extracts the RRULE value (strips DTSTART line and `RRULE:` prefix).
/// 2. Rejects `FREQ=SECONDLY` with `RruleJSInteropError.secondlyNotSupported`.
/// 3. Parses the value using RRuleKit's RFC 5545 parser.
///
/// - Parameters:
///   - rruleJsString: Full content from rrule.js `toString()` (e.g. `DTSTART:...\nRRULE:FREQ=...`) or a bare RECUR value.
///   - style: The format style used for parsing (calendar, etc.). Defaults to `.rfc5545(calendar: .current)`.
/// - Returns: A `RecurrenceRule` equivalent to what rrule.js would represent (excluding DTSTART; RRuleKit does not store it).
/// - Throws: `RruleJSInteropError` if SECONDLY, no value found, or parse fails.
public func parse(
  _ rruleJsString: String,
  style: RecurrenceRuleRFC5545FormatStyle = .init(calendar: .current)
) throws -> Calendar.RecurrenceRule {
  guard let value = extractRRuleValue(from: rruleJsString) else {
    throw RruleJSInteropError.noRRuleValue
  }
  if containsSecondly(value) {
    throw RruleJSInteropError.secondlyNotSupported
  }
  do {
    return try style.parse(value)
  } catch {
    throw RruleJSInteropError.parseError(underlying: error)
  }
}

// MARK: - Format for rrule.js

/// Formats a date as a DTSTART content-line value per RFC 5545 (date-time UTC).
/// Example: `20250101T000000Z`
private func formatDTSTARTUTC(_ date: Date, calendar: Calendar) -> String {
  var cal = calendar
  cal.timeZone = .gmt
  let comp = cal.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
  let y = comp.year ?? 0
  let M = comp.month ?? 1
  let d = comp.day ?? 1
  let h = comp.hour ?? 0
  let m = comp.minute ?? 0
  let s = comp.second ?? 0
  return String(format: "DTSTART:%04d%02d%02dT%02d%02d%02dZ", y, M, d, h, m, s)
}

/// Produces an rrule.js–compatible string from a recurrence rule and optional start date.
///
/// rrule.js expects either a full string with DTSTART and RRULE, or just the RRULE value (and uses "now" as start).
/// This function prepends a DTSTART line when you provide a date, so occurrence semantics match your intent.
///
/// - Parameters:
///   - rule: The recurrence rule to format.
///   - dtstart: If non-nil, a DTSTART line is prepended (UTC) so rrule.js uses this as the recurrence start.
///   - style: The format style for the RRULE part. Defaults to `.rfc5545(calendar: .current)`.
/// - Returns: Either `"DTSTART:...\nRRULE:value"` (if `dtstart` provided) or `"RRULE:value"`.
public func formatForRruleJS(
  _ rule: Calendar.RecurrenceRule,
  dtstart: Date? = nil,
  style: RecurrenceRuleRFC5545FormatStyle = .init(calendar: .current)
) -> String {
  let value = style.format(rule)
  if let date = dtstart {
    let dtstartLine = formatDTSTARTUTC(date, calendar: style.calendar)
    return "\(dtstartLine)\nRRULE:\(value)"
  }
  return "RRULE:\(value)"
}
