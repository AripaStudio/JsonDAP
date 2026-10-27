# 09 — Inspecting text and guarding input

Index: [StartEn.md](../../StartEn.md) · Previous: [08](08-sumtype.md)

Nothing in this chapter writes a file. These are the calls that decide whether a piece of text is
worth handing to the rest of the library.

## What kind of JSON is this?

```d
assert(JsonAP.APisValidJson(`{"a":1}`));
assert(!JsonAP.APisValidJson(`{"a":`));              // no exception, just false

assert(JsonAP.APisJsonObject(`{"a":1}`));
assert(JsonAP.APisJsonArray(`[1,2]`));
assert(JsonAP.APisJsonNumber(`42`));
assert(JsonAP.APisJsonString(`"text"`));
assert(!JsonAP.APisJsonObject(`[1,2]`));              // valid JSON, wrong shape
```

| Method | Asks |
|---|---|
| `APisValidJson(text)` | does it parse at all |
| `APisJsonObject` / `APisJsonArray` / `APisJsonNumber` / `APisJsonString` | what is the **top** node |
| `APgetJsonItemCount(text)` | `Optional!long` — keys of an object, elements of an array, empty for anything else |
| `APprettyPrintJson(text)` | `Optional!string`, four-space indent |
| `APgetJsonValueType(JSONValue)` | the `std.json` `JSONType` of a node you already hold |

```d
assert(JsonAP.APgetJsonItemCount(`{"a":1,"b":2}`).get == 2);   // two keys
assert(JsonAP.APgetJsonItemCount(`[1,2,3]`).get == 3);         // three elements
assert(JsonAP.APgetJsonItemCount(`nope`).isNull);              // not JSON: no answer

Optional!string pretty = JsonAP.APprettyPrintJson(`{"a":1}`);
writeln(pretty.get);
// {
//     "a": 1
// }
```

The app answers "what is this file?" with the four predicates in order
([TextDAPJsonTools.d:232](../../../JsonDAPtest/TextDAPJsonTools.d#L232)) and prints the item count
next to the reason a load failed ([TextDAPSession.d:44](../../../JsonDAPtest/TextDAPSession.d#L44)
— `%s holds %d items but is not a JSON object`).

## The digit family

A text editor gets its numbers typed, in whatever digits the user's keyboard produced.

```d
assert(JsonAP.APisDigitAP('7'));
assert(JsonAP.APisDigitAP('۵'));            // Persian U+06F5
assert(JsonAP.APisDigitAP('٧'));            // Arabic-Indic U+0667
assert(!JsonAP.APisDigitAP('x'));

assert(JsonAP.APisInteger("123"));            // digits only, no sign, no point
assert(!JsonAP.APisInteger("+7"));
assert(!JsonAP.APisInteger("12.5"));

assert(JsonAP.APisSignedInteger("-12"));      // optional ASCII sign, then digits
assert(JsonAP.APisSignedInteger("−7"));        // the U+2212 minus is normalised first

assert(JsonAP.APisDecimal("12.5"));           // sign, digits, one point, digits
assert(JsonAP.APisDecimal("۱۲٫۵"));            // Persian digits and the Persian decimal point
assert(!JsonAP.APisDecimal("1e9"));           // no exponent form
assert(!JsonAP.APisDecimal("12"));            // a whole number is not a decimal

assert(JsonAP.APnormalizeDigitsAP("۱۲٫۵") == "12.5");
assert(JsonAP.APnormalizeDigitsAP("−7") == "-7");
```

| Line | What it does |
|---|---|
| `APisDigitAP(dchar)` | one character, three scripts — the gate for a hand-written scanner |
| `APisInteger` / `APisSignedInteger` / `APisDecimal` | three strictly different questions; pick the one you mean |
| `APnormalizeDigitsAP(string)` | digits → ASCII, `٫`/`٬` → `.`, `−` → `-`; every other byte untouched |

Normalising **then** converting is what lets `rows[۲]` work in the path parser
([04](04-path-syntax.md)). The demo that prints all of this is
[TextDAPConvert.d:224](../../../JsonDAPtest/TextDAPConvert.d#L224), and the console's number prompt
combines `APstrIsNil` with `APisInteger` before any `to!int`
([TextDAPConsole.d:59](../../../JsonDAPtest/TextDAPConsole.d#L59)).

## The blank guards

```d
bool flag;
string reason;

JsonAP.APstrIsNil("notes.txt", "file path", flag, reason);
assert(!flag);                                   // a real value: nothing to report
assert(reason.length == 0);

JsonAP.APstrIsNil("   ", "file path", flag, reason);
assert(flag);                                    // the flag means "this input is unusable"
writeln(reason);                                 // Parameter 'file path' cannot be just whitespace.
```

The name reads like a predicate that returns a bool; it does not — it is `void`, and it writes two
`out` parameters. The flag is `true` when the input is `null`, empty or whitespace only, and the
message names the parameter you passed.

```d
assert(!JsonAP.APCheckStringIsNullArray(["a", "b"]));        // all of them hold text
assertThrown!UnknownErrorExceptionAP(JsonAP.APCheckStringIsNullArray(["a", ""]));
assert(JsonAP.APCheckStringIsNullArray([]));                  // an empty list answers true
```

[PublicCodeOtherCode.d:132](../../../JsonDAP/PublicCodeOtherCode.d#L132): it walks the list, and one
`UnknownErrorExceptionAP` carries every offending index and message together. The three-way answer
of the array version (`false` = clean, `true` = nothing to check, throw = at least one blank) is
why the app calls it once, at the top of a write
([TextDAPSession.d:123](../../../JsonDAPtest/TextDAPSession.d#L123)).

## Deprecated names

`APStrIsNUll` ([JsonDAP.d:160](../../../JsonDAP/JsonDAP.d#L160)) and `StrIsNUll` are still exported,
marked `deprecated`, and forward to the correct spellings. They are kept because the rule of this
library is that nothing disappears on a patch; `2.5.0` removes them. Prefer `APstrIsNil`.

Next: [10 — Exceptions](10-exceptions.md)
