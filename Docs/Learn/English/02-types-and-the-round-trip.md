# 02 — Types and the round trip

Index: [StartEn.md](../../StartEn.md) · Previous: [01](01-setup.md)

## The type under test

```d
struct Note
{
    @JsonName("text") string body;          // the wire key is "text", not "body"
    @JsonName("tags") string[] labels;      // arrays of strings are arrays on the wire
    @JsonIgnore string cacheKey;            // never written, never read
}
```

`@JsonName` and `@JsonIgnore` are the only two attributes the library reads
([CoreAP.d:19](../../../JsonDAP/CoreAP.d#L19), [CoreAP.d:24](../../../JsonDAP/CoreAP.d#L24)).
Fields without an attribute keep their D name.

## Out, then back in

```d
import std.json : JSONValue, JSONType;
import JsonDAP;

Note note = Note("first post", ["d", "json"], "never-serialised");

JSONValue wire = JsonAP.APserializeToJson!Note(note);   // Note  -> JSONValue
auto back      = JsonAP.APdeserializeJson!Note(wire.toString());   // text -> Optional!Note

assert(back.get.body == "first post");
assert(back.get.labels == ["d", "json"]);
assert(back.get.cacheKey is null);                      // the ignored field stayed at its default
```

`wire.toString()` is `{"tags":["d","json"],"text":"first post"}` — key order follows
`std.json`'s associative array, so never compare produced text with expected text.

| Line | What it does |
|---|---|
| `APserializeToJson!Note` | the high-level writer; `APserializeTToJsonValue!Note` is the low-level one, same output |
| `APdeserializeJson!Note` | **strict**: every field must be present, otherwise it throws |
| `back.get` | the reader answers `Optional!Note`; `.get` is only legal after checking `.isNull` |

App reference: [TextDAPConvert.d:18](../../../JsonDAPtest/TextDAPConvert.d#L18)
(`APserializeTToJsonValue` → `APgetJsonValueType` → `APconvertJsonValueToT`, then a field-by-field
comparison) and [TextDAPModel.d:27](../../../JsonDAPtest/TextDAPModel.d#L27) for a model that uses
every mapping in the table below.

## The contract

| D type | On the wire |
|---|---|
| `struct` / `class` | object |
| `T[]` | array |
| `enum` | integer, and only a **valid member** |
| `Optional!T` (= `Nullable!T`) | `null` when empty |
| `null` class reference | `null` |
| `SumType` | `{"tag":"<member>","value":<payload>}` — see [08](08-sumtype.md)

## Enum and Nullable, both directions

```d
enum Priority { low = 0, high = 1 }

struct Task
{
    @JsonName("title") string title;
    @JsonName("priority") Priority priority;
    @JsonName("done") Optional!bool done;
}

JSONValue written = JsonAP.APserializeToJson!Task(Task("ship it", Priority.high, Optional!bool.init));
// {"done":null,"priority":1,"title":"ship it"}

assert(written.object["done"].type == JSONType.NULL);        // an empty Nullable is JSON null
assertThrown!JSONConvertExceptionAP(JsonAP.APdeserializeJson!Task(`{"title":"x","priority":9}`));
```

`9` is not a `Priority`, so the reader refuses it instead of casting. This is the guard the app
demonstrates in [TextDAPConvert.d:132](../../../JsonDAPtest/TextDAPConvert.d#L132), where the
whole rejected value is printed from the exception's own fields.

## Strict against lenient

```d
struct Options
{
    @JsonName("autosave") bool autosave;
    @JsonName("tab_width") int tabWidth;
}

auto lenient = JsonAP.APdeserializeJsonLenient!Options(`{"autosave":true}`);
assert(lenient.get.tabWidth == 0);                  // the missing field keeps its type default

assertThrown!JSONConvertExceptionAP(JsonAP.APdeserializeJson!Options(`{"autosave":true}`));
```

| Situation | strict | lenient |
|---|---|---|
| field missing | `JSONConvertExceptionAP`, `MissingField` | keeps the default |
| `Optional` / `class` field missing | `JSONConvertExceptionAP` | stays empty / `null` |
| unknown `enum` value | error | error — never cast |
| unknown `SumType` tag | error listing the tags | error listing the tags |

App reference: [TextDAPConvert.d:258](../../../JsonDAPtest/TextDAPConvert.d#L258) reads the same
text both ways and prints the difference;
[TextDAPSession.d:53](../../../JsonDAPtest/TextDAPSession.d#L53) loads a session leniently on
purpose, because a hand-edited file may be missing keys.

## One `JSONValue` in, one `T` out

```d
JSONValue node = parseJSON(`{"autosave":true,"tab_width":8}`);
auto viaLowLevel = JsonAP.APconvertJsonValueToT!Options(node, false);   // false = strict
assert(viaLowLevel.get.tabWidth == 8);
```

`APconvertJsonValueToT!T(JSONValue, bool lenient = false)` is what every reader calls last; use
it when you already hold a parsed tree and only want to convert one node.

Next: [03 — Files and arrays](03-files-and-arrays.md)
