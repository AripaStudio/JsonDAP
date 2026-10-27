# 08 — SumType

Index: [StartEn.md](../../StartEn.md) · Previous: [07](07-merge-and-copy.md)

`std.sumtype.SumType` carries no reflection — a library cannot ask it what its members are called.
So the support is an explicit pair: **write an envelope**, **read an envelope**.

```
{"tag":"<which member>","value":<the payload>}
```

## The default tags

```d
import std.sumtype;

alias Payload = SumType!(int, string);

JSONValue envelope = JsonAP.APserializeSumType!Payload(Payload(42));
// {"tag":"int","value":42}

auto back = JsonAP.APdeserializeSumType!Payload(envelope, false);
assert(back.get == Payload(42));
```

With no delegate, the tag is the D member type name — `"int"`, `"string"`. It works, but it
freezes your wire format to Phobos' type names.

## Your own names

```d
JSONValue named = JsonAP.APserializeSumType!Payload(Payload("search"),
        (string memberName) => memberName == "int" ? "line" : "term");
// {"tag":"term","value":"search"}

auto namedBack = JsonAP.APdeserializeSumType!Payload(named, false,
        (string memberName) => memberName == "int" ? "line" : "term");
assert(namedBack.get == Payload("search"));
```

| Line | What it does |
|---|---|
| the delegate | `string delegate(string memberName) tagOf` — receives `int` / `string`, returns the tag to write |
| the same delegate on the read | it is used **in reverse**, mapping the tag back to the member name to select |
| `false` | `lenient` — the second parameter of the reader |

The delegate has to be the same on both sides or the tags will not match. The app keeps one
function for it ([TextDAPModel.d:163](../../../JsonDAPtest/TextDAPModel.d#L163)
`cursorTagName`) and passes it to both calls
([TextDAPConvert.d:61](../../../JsonDAPtest/TextDAPConvert.d#L61)).

## From text, and unknown tags

```d
auto fromText = JsonAP.APdeserializeSumTypeFromString!Payload(`{"tag":"string","value":"later"}`);
assert(fromText.get == Payload("later"));
```

An unknown tag is refused, and the message lists the tags that do exist — there is no default
member, no silently empty value:

```d
try
{
    JsonAP.APdeserializeSumType!Payload(parseJSON(`{"tag":"bool","value":1}`));
}
catch (BaseExceptionAP caught)
{
    caught.msg;    // Unknown tag in SumType envelope.
}
```

## When the payload needs more than the member's own conversion

`APserializeSumType` writes the payload with the normal serializer. When a member needs a shape of
its own, or the tag depends on the value rather than the type, use the handler pair:

```d
JSONValue written = JsonAP.APserializeSumTypeWithHandlers!Payload(Payload(7),
        (Payload held) => held.match!((int n) => "number", (string s) => "text"),
        (Payload held) => held.match!((int n) => JSONValue(n), (string s) => JSONValue(s)));
// {"tag":"number","value":7}

auto resolved = JsonAP.APdeserializeSumTypeWithHandlers!Payload(written,
        (string tag, JSONValue value) => tag == "number"
                ? Payload(cast(int) value.integer)
                : Payload(value.str));
assert(resolved.get == Payload(7));
```

| Line | What it does |
|---|---|
| `tagOf` | takes the **whole** `Payload`, not a member name — so two `int` members can have different tags |
| `payloadOf` | returns the `JSONValue` to write, whatever shape you want |
| `resolver` | `T delegate(string tag, JSONValue payload)` — the only place that decides which member to build |
| `held.match!(…)` | Phobos' `SumType` exhaustive visit; the delegate is where the switch lives |

The app's cursor is the real case: a line number or a search term, one field in the session file
([TextDAPSession.d:145](../../../JsonDAPtest/TextDAPSession.d#L145) writes with handlers,
[:153](../../../JsonDAPtest/TextDAPSession.d#L153) reads back through
`resolveCursor` at [TextDAPModel.d:192](../../../JsonDAPtest/TextDAPModel.d#L192), which raises
`JsonOperationExceptionAP` for a tag it does not know).

## The five

| Method | In | Out |
|---|---|---|
| `APserializeSumType!T(T value, string delegate(string) tagOf = null)` | a value | `JSONValue` |
| `APdeserializeSumType!T(JSONValue, bool lenient = false, string delegate(string) tagOf = null)` | an envelope | `Optional!T` |
| `APdeserializeSumTypeFromString!T(string jsonContent, bool lenient = false, string delegate(string) tagOf = null)` | JSON text | `Optional!T` |
| `APserializeSumTypeWithHandlers!T(T value, string delegate(T) tagOf, JSONValue delegate(T) payloadOf)` | a value and two delegates | `JSONValue` |
| `APdeserializeSumTypeWithHandlers!T(JSONValue, T delegate(string tag, JSONValue payload) resolver)` | an envelope and a resolver | `Optional!T` |

Next: [09 — Inspecting text and guarding input](09-inspecting-and-guarding.md)
