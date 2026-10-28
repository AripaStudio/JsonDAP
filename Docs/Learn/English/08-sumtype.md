# 08 — SumType

Index: [StartEn.md](../../StartEn.md) · Previous: [07](07-merge-and-copy.md)

A `SumType` holds **one** of its members, and JSON has to say which one. The envelope is

```json
{"tag":"line","value":42}
```

## The two calls you will actually use

```d
alias CursorTarget = SumType!(int, string);

// write — the tag is the member's type name by default
JSONValue wire = JsonAP.APserializeSumType!CursorTarget(CursorTarget(42));
// {"tag":"int","value":42}

// read
auto back = JsonAP.APdeserializeSumType!CursorTarget(wire, false);
assert(back.get.get!int == 42);
```

An unknown tag in the envelope is refused with the list of tags that do exist — no silent
default, no empty value:

```d
catch (BaseExceptionAP caught)
{
    caught.msg;   // Unknown tag in SumType envelope.  (known tags are listed)
}
```

## Naming the tags yourself

The default tags are D type names (`"int"`, `"string"`). Give both directions the **same**
function and your file gets stable names instead. `cursorTagName` maps member ↔ tag
([TextDAPModel.d:163](../../../JsonDAPtest/TextDAPModel.d#L163)):

```d
string cursorTagName(string memberName)
{
    if (memberName == "int")    return CursorTag.line;    // "line"
    if (memberName == "string") return CursorTag.search;  // "search"
    return memberName;
}

JSONValue wire = JsonAP.APserializeSumType!CursorTarget(target,
        (string memberName) => cursorTagName(memberName));

auto back = JsonAP.APdeserializeSumType!CursorTarget(wire, false,
        (string memberName) => cursorTagName(memberName));
```

Now the file says `{"tag":"line","value":42}`, not `{"tag":"int",…}`.

| Line | What it does |
|---|---|
| the delegate on write | member name → tag, before the payload is written |
| `false` on read | `lenient` — same flag as every reader |
| the delegate on read | tag → member name, so the reader knows which member to build |
| same function both times | the only way the two directions stay in agreement |

TextDAP's `cursorRoundTrip` runs exactly that pair on every round trip:

```d
JSONValue envelope = JsonAP.APserializeSumType!CursorTarget(target,
        (string memberName) => cursorTagName(memberName));

Optional!CursorTarget readBack = JsonAP.APdeserializeSumType!CursorTarget(envelope,
        false, (string memberName) => cursorTagName(memberName));
```

## When the value itself decides the tag

`…WithHandlers` gives you the **whole value** instead of a member name; save writes the cursor
that way ([TextDAPSession.d:147](../../../JsonDAPtest/TextDAPSession.d#L147)):

```d
JSONValue envelope = JsonAP.APserializeSumTypeWithHandlers!CursorTarget(target,
        (CursorTarget held) => cursorTagOf(held),       // the value -> "line" | "search"
        (CursorTarget held) => cursorPayloadOf(held));  // the value -> JSONValue payload
```

and `readCursor` resolves it back through one function of your own
([TextDAPSession.d:172](../../../JsonDAPtest/TextDAPSession.d#L172),
[TextDAPModel.d:192](../../../JsonDAPtest/TextDAPModel.d#L192)):

```d
return JsonAP.APdeserializeSumTypeWithHandlers!CursorTarget(*stored,
        (string tag, JSONValue payload) => resolveCursor(tag, payload));
```

Inside `resolveCursor`, the payload must match its tag before it is trusted — a string payload
under a `"line"` tag raises `JSONConvertExceptionAP` instead of being coerced. That check is the
difference between *encoding* and *guessing*:

```d
if (tag == CursorTag.line)
{
    requireNodeType(tag, payload, JSONType.INTEGER);    // throws unless the payload is an integer
    return CursorTarget(cast(int) payload.integer);
}
```

| Line | What it does |
|---|---|
| `tagOf` delegate | takes the **whole value**, so two `int` members can carry different tags |
| `payloadOf` delegate | returns the `JSONValue` to write — any shape you want |
| `resolver` | `T delegate(string tag, JSONValue payload)` — the only place that decides which member to build |
| `held.match!` | Phobos' exhaustive visit; the lambda is where the "switch" lives |

## The five in one table

| Method | In | Out |
|---|---|---|
| `APserializeSumType!T(value, tagOf = null)` | a value | `JSONValue` |
| `APdeserializeSumType!T(json, lenient = false, tagOf = null)` | an envelope | `Optional!T` |
| `APdeserializeSumTypeFromString!T(text, lenient = false, tagOf = null)` | JSON text | `Optional!T` |
| `APserializeSumTypeWithHandlers!T(value, tagOf, payloadOf)` | value + two delegates | `JSONValue` |
| `APdeserializeSumTypeWithHandlers!T(json, resolver)` | envelope + resolver | `Optional!T` |

The `…WithHandlers` pair is the one you will prefer in real code: the tag lives next to the
value it describes, and the reader refuses payloads that contradict their tag.

Next: [09 — Inspecting and guarding](09-inspecting-and-guarding.md)