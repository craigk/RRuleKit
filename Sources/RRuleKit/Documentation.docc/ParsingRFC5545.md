# Parsing RFC 5545 Strings

This document details how to parse RFC 5545-compliant recurrence rule strings using `RecurrenceRuleRFC5545FormatStyle`.

## Overview

Parsing functionality allows conversion of strings like:

```plaintext
FREQ=WEEKLY;BYDAY=MO,WE,FR;INTERVAL=2;COUNT=10
```

into structured `Calendar.RecurrenceRule` objects.

## Example

```swift
import Foundation
import RRuleKit

let parser = RecurrenceRuleRFC5545FormatStyle(calendar: .current)

do {
  let rfcString = "FREQ=WEEKLY;BYDAY=MO,WE,FR;INTERVAL=2;COUNT=10"
  let recurrenceRule = try parser.parse(rfcString)
  print(recurrenceRule)
} catch {
  print("Parsing error: \(error)")
}
```

## Key RFC 5545 Parsing Rules

- **FREQ** is mandatory and must appear exactly once. Rule parts may appear in **any order** (e.g. `COUNT=5;FREQ=DAILY` is valid). The key must be exactly `FREQ` (case-insensitive); `FREQUENCY=DAILY` is rejected.
- **Case-insensitivity**: Property names and enumerated values are case-insensitive (e.g. `freq=daily`, `BYDAY=mo,we`).
- **Content-line folding**: Input is unfolded before parsing: CRLF or LF followed by a single SPACE or HTAB is removed, so folded content lines (e.g. from .ics files) parse correctly.
- **WKST**: The `WKST` rule part is accepted and ignored (Foundation has no week-start API).
- **COUNT** and **UNTIL** cannot coexist; only one may be specified.
- **Duplicate keys** cause parsing to fail.
- **FREQ=SECONDLY** is not supported and will cause parsing to fail.
- Invalid or unsupported keys will cause parsing to fail.

## Limitations

RFC 5545 errata (e.g. BYDAY with numeric modifiers in combination with BYWEEKNO for YEARLY rules) are not validated by the parser.
