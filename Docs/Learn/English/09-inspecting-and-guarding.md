# 09 — Inspecting text and guarding input

Index: [StartEn.md](../../StartEn.md) · Previous: [08](08-sumtype.md)

Nothing here writes a file. These checks come **before** you trust text from a file, a path box
or the keyboard.

## What kind of JSON is this?

```d
assert(JsonAP.APisValidJson(`{"a":1}`));
assert(!JsonAP.APisValidJson(`{"a":`));              // false, no exception

assert(JsonAP.APisJsonObject(`{"a":1}`));
assert(JsonAP.APisJsonArray(`[1,2]`));
assert(JsonAP.APisJsonNumber(`42`));
assert(JsonAP.APisJsonString(`"text"`));
assert(!JsonAP.APisJsonObject(`[1,2]`));              // valid JSON, other shape
```

TextDAP answers "what is this file?" by asking the four predicates in order, then pairing the
item count with the reason when a load fails:

```d
private static string shapeOf(string jsonContent)
{
    if (JsonAP.APisJsonObject(jsonContent)) { return "object"; }
    if (JsonAP.APisJsonArray(jsonContent))  { return "array"; }
    if (JsonAP.APisJsonNumber(jsonContent)) { return "number"; }
    if (JsonAP.APisJsonString(jsonContent)) { return "string"; }
    return "other";
}

// and when the text is not an object:
if (!JsonAP.APisValidJson(text))
{
    Optional!long count = JsonAP.APgetJsonItemCount(text);
    // "%s holds %d items but is not a JSON object."
}
```

A prettier view, when you want to show what was parsed:

```d
Optional!string pretty = JsonAP.APprettyPrintJson(`{"a":1}`);
// {
//     "a": 1
// }
// an Optional!string: empty when the text is not JSON
```

| Method | Answers |
|---|---|
| `APisValidJson(text)` | does it parse at all |
| `APisJsonObject` / `APisJsonArray` / `APisJsonNumber` / `APisJsonString` | the **top** node's shape |
| `APgetJsonItemCount(text)` | `Optional!long` — keys of an object, elements of an array, empty otherwise |
| `APprettyPrintJson(text)` | `Optional!string`, four-space indent |
| `APgetJsonValueType(JSONValue)` | the `JSONType` of a node you already hold |

## The digit family

Numbers arrive "typed", in whatever digits the keyboard produced.

```d
assert(JsonAP.APisDigitAP('7'));
assert(JsonAP.APisDigitAP('۵'));              // Persian U+06F5
assert(JsonAP.APisDigitAP('٧'));              // Arabic-Indic U+0667
assert(!JsonAP.APisDigitAP('x'));

assert(JsonAP.APisInteger("123"));            // digit run only — no sign, no point
assert(!JsonAP.APisInteger("+7"));
assert(!JsonAP.APisInteger("12.5"));

assert(JsonAP.APisSignedInteger("-12"));      // optional sign, then digits
assert(JsonAP.APisSignedInteger("−7"));        // U+2212 minus, normalised first

assert(JsonAP.APisDecimal("12.5"));           // sign, digits, one point, digits
assert(JsonAP.APisDecimal("۱۲٫۵"));            // Persian digits and decimal point
assert(!JsonAP.APisDecimal("1e9"));           // no exponent form
assert(!JsonAP.APisDecimal("12"));            // whole != decimal

assert(JsonAP.APnormalizeDigitsAP("۱۲٫۵") == "12.5");
assert(JsonAP.APnormalizeDigitsAP("−7") == "-7");
```

| Line | What it does |
|---|---|
| `APisDigitAP(dchar)` | one character, three scripts — the door a hand-written scanner walks through |
| `APisInteger` / `APisSignedInteger` / `APisDecimal` | three different questions; pick the one you mean |
| `APnormalizeDigitsAP(string)` | digits → ASCII, `٫`/`٬` → `.`, `−` → `-`; every other byte untouched |

`digitGateDemo` builds the table above from real probes — one line per sample, then the three
gates:

```d
foreach (sample; ["7", "+7", "−7", "۱۲", "12.5", "۱۲٫۵", "1e9", "x"])
{
    gates ~= CL_TextDap_Frame.fieldText(sample, format!"whole %s, signed %s, decimal %s"
            (CL_TextDap_Console.yesNo(JsonAP.APisInteger(sample)),
            CL_TextDap_Console.yesNo(JsonAP.APisSignedInteger(sample)),
            CL_TextDap_Console.yesNo(JsonAP.APisDecimal(sample))));
}
```

And the number prompt combines the blank guard with `APisInteger` before any `to!int`:

```d
JsonAP.APstrIsNil(raw, "number", blankFlag, blankReason);
if (!blankFlag && JsonAP.APisInteger(raw))
{
    // safe to convert now
}
```

Normalising **before** converting is exactly what lets `items[۲]` work (see
[04](04-path-syntax.md)).

## The blank guards

`APstrIsNil` is not a predicate returning `bool` — it is `void` with two `out` parameters: a flag
and a sentence naming the parameter you passed.

```d
bool flag; string reason;

JsonAP.APstrIsNil("notes.txt", "file path", flag, reason);
assert(!flag);                                   // a real value: nothing to report

JsonAP.APstrIsNil("   ", "file path", flag, reason);
assert(flag);                                    // "this input is unusable"
// reason: Parameter 'file path' cannot be just whitespace.
```

```d
assert(!JsonAP.APCheckStringIsNullArray(["a", "b"]));   // all hold text
assert(JsonAP.APCheckStringIsNullArray([]));            // empty list -> true, nothing to check
// one blank entry -> UnknownErrorExceptionAP carrying every offending index
```

Every TextDAP write opens with the same one call, before any file is touched:

```d
string[] blankInputs = [filePath, jsonPath];
if (JsonAP.APCheckStringIsNullArray(blankInputs))
{
    message = "the session path and the file path must both hold text.";
    return false;
}
```

The two-parameter form does the same job for one input — `load`, `explainPath`, `validateText`
and `readDocument` all start with it.

## Deprecated names

`APStrIsNUll` and `StrIsNUll` are still exported, marked `deprecated`, and forward to the
correct spellings — nothing disappears on a patch. Prefer `APstrIsNil`.

Next: [10 — Exceptions](10-exceptions.md)