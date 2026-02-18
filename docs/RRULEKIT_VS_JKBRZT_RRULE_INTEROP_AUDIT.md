# RRuleKit ↔ jkbrzt/rrule Interoperability Audit

**Date:** 2026-02-17  
**Purpose:** Identify issues, gaps, and variances when RRuleKit and [jkbrzt/rrule](https://github.com/jkbrzt/rrule) (JavaScript) communicate (e.g. parse/format RRULE strings produced by the other).

**Interop add-on (implemented):** The optional product **RRuleKitRruleJSInterop** implements the recommended layer: it strips DTSTART/RRULE: when parsing from rrule.js, rejects SECONDLY with a clear error, and can prepend a DTSTART line when formatting for rrule.js. See `Sources/RRuleKitRruleJSInterop/` and the main README “Add-ons” section.

**References:**
- [jkbrzt/rrule README](https://github.com/jkbrzt/rrule) (API, toString/fromString, optionsToString)
- [RFC 5545 – Recurrence Rule (RECUR)](https://datatracker.ietf.org/doc/html/rfc5545#section-3.3.10)
- RRuleKit: `Sources/RRuleKit/RecurrenceRuleRFC5545FormatStyle.swift`
- **RRuleKitRruleJSInterop:** `Sources/RRuleKitRruleJSInterop/RruleJSInterop.swift`, `Sources/RRuleKitRruleJSInterop/README.md`

---

## 1. Executive Summary

| Severity | Count | Summary | Add-on |
|----------|--------|---------|--------|
| **High** | 2 | String format mismatch (DTSTART/RRULE: prefix); SECONDLY unsupported in RRuleKit | ✅ Add-on strips prefix and rejects SECONDLY |
| **Medium** | 4 | DTSTART not modeled; default BY* emission; WKST value format; optional content-line handling | ✅ Add-on formats with optional DTSTART; WKST/doc only |
| **Low** | 3 | Semantic differences (first instance); keyword validity; unknown parts | Document only |

**Recommendation (implemented):** The **RRuleKitRruleJSInterop** add-on normalizes between rrule.js full iCalendar-style strings and RRuleKit’s RRULE-value-only format, rejects SECONDLY with `RruleJSInteropError.secondlyNotSupported`, and supports optional DTSTART when formatting for rrule.js. Depend on `RRuleKitRruleJSInterop` when interoperating with jkbrzt/rrule.

---

## 2. String Format & Parsing Boundaries

### 2.1 ✅ [HIGH] rrule.js outputs full content lines; RRuleKit expects RRULE value only

**rrule.js `toString()` returns:**
```text
DTSTART:20120201T093000Z
RRULE:FREQ=WEEKLY;INTERVAL=5;UNTIL=20130130T230000Z;BYDAY=MO,FR
```

**RRuleKit `parse(_:)` expects** only the RECUR value, e.g.:
```text
FREQ=WEEKLY;INTERVAL=5;UNTIL=20130130T230000Z;BYDAY=MO,FR
```

- If you pass the full rrule.js string (including `DTSTART:...\nRRULE:`), the first “key” becomes `DTSTART` with a value containing a newline and `RRULE:FREQ=...`. RRuleKit does not recognize `DTSTART` and returns `nil` → parse fails.
- RRuleKit also does **not** accept a single line starting with `RRULE:` (e.g. `RRULE:FREQ=DAILY`). The first key would be `RRULE` with value `FREQ=DAILY`, and `RRULE` is not in the known-keys list → parse fails.

**Gap:** RRuleKit core has no built-in support for “content line” input (strip `RRULE:` and optional `DTSTART` line).

**Add-on:** **RRuleKitRruleJSInterop** provides `extractRRuleValue(from:)` (strips `\nRRULE:` / `\r\nRRULE:` or leading `RRULE:`) and `parse(_:style:)`, which extracts the value then parses with RRuleKit. Use the add-on when consuming rrule.js `toString()` output.

---

### 2.2 ✅ [MEDIUM] RRuleKit outputs RRULE value only; rrule.js `fromString()` can accept RRULE-only

**RRuleKit `format(_:)` returns** only the RECUR value, e.g.:
```text
FREQ=WEEKLY;INTERVAL=5;UNTIL=20130130T230000Z;BYDAY=MO,FR
```

**rrule.js `RRule.fromString(rfcString)`:**
- Prefers a full string with `DTSTART` and `RRULE:` (e.g. from `toString()`).
- If `DTSTART` is missing, the library uses **current time** as the start ([README](https://github.com/jkbrzt/rrule)).

So if you send RRuleKit’s output to rrule.js as-is:
- Parsing works, but **dtstart** will be “now”, not the intended start. Occurrence generation may differ from RRuleKit/calendar if the start date matters.

**Gap:** RRuleKit core has no concept of DTSTART; it cannot emit or persist it.

**Add-on:** **RRuleKitRruleJSInterop** provides `formatForRruleJS(_:dtstart:style:)`. Pass a `Date` as `dtstart` to prepend a UTC DTSTART line (`DTSTART:YYYYMMDDTHHMMSSZ\nRRULE:` + value). Without `dtstart`, output is `RRULE:value` only. Document that DTSTART is supplied by the caller (e.g. event start).

---

## 3. FREQ and Frequencies

### 3.1 ✅ [HIGH] SECONDLY supported by rrule.js, rejected by RRuleKit

- **rrule.js:** Supports `FREQ=SECONDLY` (and HOURLY, MINUTELY, etc.).
- **RRuleKit:** Uses `Calendar.RecurrenceRule`, which has no `.secondly`; SECONDLY is explicitly unsupported and parse fails.

**Impact:** Any rule created in rrule.js with `FREQ=SECONDLY` cannot be parsed or round-tripped by RRuleKit.

**Add-on:** **RRuleKitRruleJSInterop** `parse(_:style:)` rejects SECONDLY before calling RRuleKit and throws `RruleJSInteropError.secondlyNotSupported`. Use `containsSecondly(_:)` to check before parsing if needed.

---

### 3.2 ✅ [LOW] “Every keyword valid on every frequency”

- **rrule.js:** “Unlike documented in the RFC, every keyword is valid on every frequency.”
- **RRuleKit:** Does not enforce RFC restrictions (e.g. BYWEEKNO only on YEARLY); invalid combinations are left to Foundation.

So both libraries are permissive; no interop conflict, but behavior for odd combinations may differ from strict RFC.

---

## 4. UNTIL and COUNT ✅

### 4.1 Format compatibility

- **rrule.js** typically emits UNTIL as date-time UTC, e.g. `UNTIL=20130130T230000Z`.
- **RRuleKit** accepts and emits:
  - Date-only: `UNTIL=20250111`
  - Date-time UTC: `UNTIL=20250111T235959Z`
  - Date-time with TZID: `TZID=America/New_York:19970714T133000`

So RRuleKit can parse rrule.js UNTIL strings. RRuleKit also normalizes hour 24 in UNTIL to midnight next day (RFC 5545). No change needed for basic interop.

### 4.2 COUNT

Both support COUNT; mutually exclusive with UNTIL. Compatible.

---

## 5. BY* Parts ✅

### 5.1 BYDAY

- Both use RFC-style BYDAY: `MO`, `1WE`, `-1FR`, etc.
- RRuleKit accepts case-insensitive weekdays; rrule.js uses MO, FR, etc. Compatible.

### 5.2 BYHOUR / BYMINUTE / BYSECOND

- **RRuleKit:** BYHOUR parsed with `min: 0, max: 23` (rejects `BYHOUR=24`). RFC 5545 allows hour 24 only for date-time (e.g. UNTIL), not for BYHOUR; RRuleKit behavior is correct.
- **rrule.js** `optionsToString(rule.options)` can emit **default** time parts from dtstart, e.g. `BYHOUR=10;BYMINUTE=30;BYSECOND=0`. RRuleKit does not infer BY* from a start date; it only emits BY* when the rule has them set.

**Variance:** If rrule.js sends a rule with BYHOUR/BYMINUTE/BYSECOND derived only from dtstart, RRuleKit will parse and persist them. If RRuleKit then formats a rule that has no explicit BY* (all default), it may omit them. rrule.js parsing RRuleKit output without those parts will use its own defaults (or dtstart). So semantics can match as long as both sides agree on “default” time (e.g. 00:00:00 when omitted).

### 5.3 Other BY* (BYMONTH, BYMONTHDAY, BYYEARDAY, BYWEEKNO, BYSETPOS)

Ranges and list formats align with RFC and with each other. No known interop issues.

---

## 6. WKST ✅

### 6.1 ✅ [MEDIUM] Value format

- **RFC 5545:** WKST uses weekday abbreviation: `WKST=MO`, `WKST=SU`, etc.
- **RRuleKit:** Parses and accepts WKST (any value); does not persist it (Foundation has no week-start API). Optionally emits `WKST=MO` when `emitWKST: true`.
- **rrule.js:** Internally uses numeric weekdays (e.g. `RRule.MO` = 0). README shows `optionsToString` output with `WKST=0` in the full options example.

If rrule.js ever emits **numeric** WKST (e.g. `WKST=0`) in an RRULE string:
- RRuleKit’s parser accepts the key `WKST` and skips the value (`case "wkst": break`). So `WKST=0` would not cause a parse error.
- RRuleKit does not validate that the value is MO/TU/... So interop is safe; only if RRuleKit ever started emitting WKST with a numeric value would that be non-RFC (currently it emits `WKST=MO` when `emitWKST` is true).

No change required; document that RRuleKit accepts but does not persist WKST.

---

## 7. Content-Line Folding (RFC 5545 Section 3.1) ✅

- **RRuleKit:** Unfolds on parse (CRLF + SPACE/HTAB removed). Optional folding when formatting (`foldLongLines: true`) so no line exceeds 75 octets.
- **rrule.js:** README mentions “unfold” option for parsing; folding behavior not detailed in the snippet.

If rrule.js sends folded content (e.g. long RRULE with `\r\n ` in the middle), RRuleKit’s unfold will handle it. If RRuleKit formats with `foldLongLines: true`, rrule.js must unfold before parsing (or accept folded lines). Document that RRuleKit can consume folded input; when sending to rrule.js, either send one line or ensure the receiver unfolds.

---

## 8. Semantic Difference: First Recurrence Instance ✅

- **rrule.js:** “Unlike documented in the RFC, the starting datetime, dtstart, is **not** the first recurrence instance, unless it does fit in the specified rules.”
- **RFC 5545:** DTSTART is the first recurrence instance when it matches the rule.
- **RRuleKit:** No DTSTART; occurrence generation is delegated to Foundation’s `Calendar.RecurrenceRule`. Behavior depends on how the rule is used (e.g. with a reference start date in the app).

**Gap:** When converting from rrule.js to RRuleKit, the “first instance” semantics may differ if the app or calendar assumes DTSTART as first instance. Document that DTSTART is not represented in RRuleKit; the caller must supply start when generating occurrences if needed.

---

## 9. Summary Table: Issues, Gaps, Variances

| # | Area | Issue / Gap / Variance | Severity | Add-on / action |
|---|------|-------------------------|----------|------------------|
| 1 | ✅ String format | rrule.js outputs `DTSTART:...\nRRULE:...`; RRuleKit expects value only. Full string fails to parse. | **High** | **Add-on:** `extractRRuleValue(from:)` + `parse(_:style:)` strip prefix and parse. |
| 2 | ✅ FREQ=SECONDLY | rrule.js supports; RRuleKit rejects (Foundation). | **High** | **Add-on:** `parse(_:style:)` throws `.secondlyNotSupported`; `containsSecondly(_:)` available. |
| 3 | ✅ DTSTART | RRuleKit does not model or emit DTSTART. rrule.js uses it for start and defaults. | **Medium** | **Add-on:** `formatForRruleJS(_:dtstart:style:)` accepts optional `dtstart` and prepends DTSTART line. |
| 4 | ✅ Default BY* emission | rrule.js may emit BYHOUR/BYMINUTE/BYSECOND from dtstart; RRuleKit only emits when set. | **Medium** | Document; ensure default-time semantics agreed (e.g. 00:00 when omitted). |
| 5 | ✅ WKST | rrule.js may use numeric (0); RRuleKit accepts any value, emits MO. | **Medium** | No code change; document. RRuleKit accepts WKST; add-on does not alter. |
| 6 | ✅ RRULE: prefix | RRuleKit core does not accept leading `RRULE:` on the same line. | **Medium** | **Add-on:** Same as (1); `extractRRuleValue` handles `RRULE:value` single line. |
| 7 | ✅ First instance | rrule.js dtstart not necessarily first instance; RRuleKit has no DTSTART. | **Low** | Document semantics for occurrence generation; caller supplies start when needed. |
| 8 | ✅ Keyword validity | Both permissive across frequencies. | **Low** | None. |
| 9 | ✅ Unknown rule parts | RRuleKit rejects unknown keys; rrule may have extensions. | **Low** | Document; if needed, consider ignoring unknown parts for forward compatibility. |

---

## 10. Implemented Interop Layer: RRuleKitRruleJSInterop

The optional product **RRuleKitRruleJSInterop** implements the recommended layer. Add it as a dependency when interoperating with jkbrzt/rrule.

**Parse from rrule.js** (full content or `RRULE:value` or bare value):

```swift
import RRuleKitRruleJSInterop

let rruleJsString = "DTSTART:20120201T093000Z\nRRULE:FREQ=WEEKLY;INTERVAL=5;BYDAY=MO,FR"
let rule = try parse(rruleJsString, style: .init(calendar: .current))
// SECONDLY throws RruleJSInteropError.secondlyNotSupported
// No RRULE value throws RruleJSInteropError.noRRuleValue
```

**Format for rrule.js** (optional DTSTART so rrule.js uses your start date):

```swift
let stringForJS = formatForRruleJS(rule, dtstart: eventStartDate, style: .init(calendar: .current))
// "DTSTART:20250106T103000Z\nRRULE:FREQ=WEEKLY;..."
// Without dtstart: "RRULE:FREQ=WEEKLY;..."
```

**Helpers:** `extractRRuleValue(from:)` returns the RECUR value only, or `nil` if no RRULE value is found. `containsSecondly(_:)` returns whether the string contains `FREQ=SECONDLY`; when no RRULE value can be extracted it checks the raw string, so you can detect SECONDLY even in malformed content. See `Sources/RRuleKitRruleJSInterop/README.md` and the main README “Add-ons” section.

---

## 11. References

- [jkbrzt/rrule](https://github.com/jkbrzt/rrule) – JavaScript library, README and API.
- [RFC 5545 Section 3.3.10 – Recurrence Rule](https://datatracker.ietf.org/doc/html/rfc5545#section-3.3.10).
- RRuleKit: `Sources/RRuleKit/RecurrenceRuleRFC5545FormatStyle.swift`.
- **RRuleKitRruleJSInterop:** `Sources/RRuleKitRruleJSInterop/RruleJSInterop.swift`, `Sources/RRuleKitRruleJSInterop/README.md`; main README “Add-ons” section.
