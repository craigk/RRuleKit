# RRuleKitRruleJSInterop

Optional add-on for [RRuleKit](https://github.com/kubens/RRuleKit) that aligns string format and behavior with [jkbrzt/rrule](https://github.com/jkbrzt/rrule) (JavaScript).

## What it does

- **Parse from rrule.js**: Accepts full content from `rule.toString()` (`DTSTART:...\nRRULE:FREQ=...`), strips DTSTART and the `RRULE:` prefix, rejects `FREQ=SECONDLY` with a clear error, and returns a `Calendar.RecurrenceRule`.
- **Format for rrule.js**: Formats a `RecurrenceRule` and optionally prepends a DTSTART line (so rrule.js uses your start date instead of “now”).

## Usage

```swift
import RRuleKitRruleJSInterop

// Parse string from rrule.js toString()
let rruleJsString = """
DTSTART:20120201T093000Z
RRULE:FREQ=WEEKLY;INTERVAL=5;UNTIL=20130130T230000Z;BYDAY=MO,FR
"""
let rule = try parse(rruleJsString, style: .init(calendar: .gregorian))

// Format for rrule.js (with DTSTART so JS uses this start)
let startDate = Date()
let forJS = formatForRruleJS(rule, dtstart: startDate)
// "DTSTART:2025..."
```

## Adding the product

In your `Package.swift`:

```swift
dependencies: [
  .package(url: "https://github.com/kubens/RRuleKit.git", from: "1.0.0"),
],
targets: [
  .target(
    name: "MyApp",
    dependencies: [
      "RRuleKit",
      "RRuleKitRruleJSInterop",  // add-on
    ]
  ),
]
```

If you only need RRULE value parsing/formatting (no rrule.js strings), depend on `RRuleKit` alone.
