# Formatting to RFC 5545 Strings

This document details how to format `Calendar.RecurrenceRule` objects into RFC 5545-compliant strings.

## Overview

Formatting functionality allows conversion of recurrence rule objects like:

```swift
let rrule = Calendar.RecurrenceRule(
  calendar: .current,
  frequency: .monthly,
  interval: 1,
  end: .afterOccurrences(5),
  weekdays: [.every(.monday), .every(.wednesday)]
)
```

into strings like:

```plaintext
FREQ=MONTHLY;INTERVAL=1;COUNT=5;BYDAY=MO,WE
```

## Example

```swift
import Foundation
import RRuleKit

let formatter = RecurrenceRuleRFC5545FormatStyle(calendar: .current)

let rrule = Calendar.RecurrenceRule(
  calendar: .current,
  frequency: .weekly,
  interval: 1,
  weekdays: [.every(.monday), .every(.friday)]
)

let rfcString = formatter.format(rrule)
print(rfcString)
// Output: "FREQ=WEEKLY;BYDAY=MO,FR"
```

## Format Options

- **foldLongLines**: When `true`, the formatted string is folded so no line exceeds 75 octets (RFC 5545 Section 3.1). Continuation lines are introduced with CRLF + SPACE. Default is `false`.
- **emitWKST**: When `true`, the formatter appends `;WKST=MO` for RECUR compliance (default week start). WKST is not stored in `RecurrenceRule`. Default is `false`.

Example:

```swift
let formatter = RecurrenceRuleRFC5545FormatStyle(calendar: .current, foldLongLines: true, emitWKST: true)
let rfcString = formatter.format(rrule)
```

## Notes

- Output order follows RFC 5545: FREQ first, then COUNT or UNTIL (if present), INTERVAL, then BY* parts in a fixed order, optionally WKST.
- Date and date-time values in UNTIL are formatted per RFC 5545 (UTC with Z, or TZID for local time).
- Time components default to midnight when omitted.
