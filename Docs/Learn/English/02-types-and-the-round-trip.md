# 02 — Types and the round trip

Index: [StartEn.md](../../StartEn.md) · Previous: [01](01-setup.md)

## The type a session saves

The whole state of a session is one struct. Read `DocumentRecord` first — every rule below is
visible there
([TextDAPModel.d:35](../../../JsonDAPtest/TextDAPModel.d#L35)):

```d
public struct DocumentRecord
{
    @JsonName("file_path") string filePath;
    @JsonName("title") string title;
    @JsonName("open_count") int openCount;
    @JsonName("state") DocumentState state;      // enum -> integer on the wire
    @JsonName("note") Optional!string note;      // empty Optional -> null
    @JsonIgnore string lookupKey;                // computed in memory, never written
}
```

`@JsonName` and `@JsonIgnore` are the only two attributes the library reads. A field with no
attribute keeps its D name.

## Out, then back in

The round trip runs on every save ([TextDAPSession.d:91](../../../JsonDAPtest/TextDAPSession.d#L91)):

```d
JSONValue wire = JsonAP.APserializeToJson!SessionFile(session);      // struct -> JSONValue
auto back = JsonAP.APdeserializeJson!SessionFile(wire.toString());   // text -> Optional!SessionFile

assert(back.get.schema == session.schema);
assert(back.get.documents.length == session.documents.length);
```

`wire.toString()` order follows `std.json`'s associative array, so never compare produced text
with expected text — compare parsed values.

| Line | What it does |
|---|---|
| `APserializeToJson!T` | the high-level writer; `APserializeTToJsonValue!T` is the low-level twin, same output |
| `APdeserializeJson!T` | **strict**: every field must be present, otherwise it throws |
| `back.get` | the reader answers `Optional!T`; `.get` is only legal after checking `.isNull` |

## The contract

| D type | On the wire |
|---|---|
| `struct` / `class` | object |
| `T[]` | array |
| `enum` | integer, and only a **valid member** |
| `Optional!T` (= `Nullable!T`) | `null` when empty |
| `null` class reference | `null` |
| `SumType` | `{"tag":"<member>","value":<payload>}` — see [08](08-sumtype.md) |

## Strict against lenient

Reading a file a user may have hand-edited fails under strict mode; lenient fills the blanks:

```d
string partial = `{"schema":"textdap.session.1"}`;

auto strict  = JsonAP.APdeserializeJson!SessionFile(partial);       // throws MissingField
auto lenient = JsonAP.APdeserializeJsonLenient!SessionFile(partial); // documents == []
```

| Situation | strict | lenient |
|---|---|---|
| field missing | `JSONConvertExceptionAP`, `MissingField` | keeps the default |
| `Optional` / class field missing | exception | stays empty / `null` |
| unknown `enum` value | error | error — never cast |
| unknown `SumType` tag | error listing the tags | error listing the tags |

TextDAP's `load` reads the state file that way on purpose:

```d
auto parsed = JsonAP.APdeserializeJsonLenient!SessionFile(text);
if (parsed.isNull)
{
    CL_TextDap_Console.sayFail("the session document read back as empty.");
    return Optional!SessionFile.init;
}
```

## What a rejected enum looks like

`DocumentState` holds `saved=0`, `edited=1`, `missing=2`. Feed the reader `"state":9` and it
refuses instead of casting — which is what `enumGuardDemo` shows by catching the failure and
printing every field it carries:

```d
catch (JSONConvertExceptionAP caught)
{
    // field   caught.parameterName      // "state"
    // value   caught.invalidValue      // "9"
    // code    caught.jsonSpecificError // InvalidEnumMember
    // wanted  caught.reasonForFailure  // a valid DocumentState member
    return true;
}
```

```text
rejected enum
  field   state
  value   9
  code    InvalidEnumMember
  wanted  a valid DocumentState member
```

Next: [03 — Files and arrays](03-files-and-arrays.md)