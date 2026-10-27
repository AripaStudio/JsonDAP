# 04 — Path syntax

Index: [StartEn.md](../../StartEn.md) · Previous: [03](03-files-and-arrays.md)

One grammar, used by `APgetJsonValue`, by `APJsonPathParser` and by every file-edit method. Since
2.4.0 there is no second parser to disagree with
([PublicCodeOtherCode.d:165](../../../JsonDAP/PublicCodeOtherCode.d#L165)).

## What a path becomes

```d
PathStep[] steps = JsonAP.APJsonPathParser("MainData.items[2].name");

assert(steps.length == 4);                        // one step per key AND one per index
assert(steps[0].type == PathStepType.ObjectKey);
assert(steps[0].key == "MainData");
assert(steps[1].key == "items");
assert(steps[2].type == PathStepType.ArrayIndex);
assert(steps[2].index == 2);
assert(steps[3].key == "name");
```

```d
public struct PathStep
{
    PathStepType type;
    union { string key; int index; }      // only one of the two is meaningful
}

public enum PathStepType { ObjectKey, ArrayIndex }
```

`PathStep` and `PathStepType` arrive with `import JsonDAP;`. Reading `steps[0].index` is undefined
behaviour waiting to happen — branch on `.type` first.

## The forms

| Form | Meaning |
|---|---|
| `a.b` | object key `b` inside object `a` |
| `items[2]` | the third element of the array `items` |
| `rows[0][1]` | chained indexes — two steps, `ArrayIndex` twice |
| `weird\.key.next` | `\` escapes the next character, so a key may hold `.` `[` `]` |
| `rows[۲]` | Persian and Arabic-Indic digits are normalised before the index is read |

```d
PathStep[] escaped = JsonAP.APJsonPathParser(`weird\.key.next`);
assert(escaped.length == 2);
assert(escaped[0].key == "weird.key");        // the dot is part of the name, not a separator

PathStep[] persian = JsonAP.APJsonPathParser("rows[۲]");
assert(persian[1].index == 2);                // U+06F2 became ASCII before to!int
```

`APnormalizeDigitsAP` ([PublicCodeOtherCode.d:38](../../../JsonDAP/PublicCodeOtherCode.d#L38)) is
the function doing that work; it is public so you can use it on your own input — see
[09](09-inspecting-and-guarding.md).

## A broken path is refused, never guessed

```d
foreach (bad; ["", "   ", "a..b", "items[3", "items]", "items[0]x", "items[abc]", "items[-1]"])
{
    try
    {
        JsonAP.APJsonPathParser(bad);
        assert(false, "must refuse: " ~ bad);
    }
    catch (InvalidArgumentExceptionAP caught)
    {
        writeln(caught.msg);
    }
}
```

| Path | The message |
|---|---|
| `""`, `"   "` | `JSON path is empty.` |
| `a..b` | `JSON path contains an empty key.` |
| `items[3` | `JSON path has a missing closing bracket.` |
| `items]` | `JSON path has a ']' without '['.` |
| `items[0]x` | `Unexpected character after ']'.` |
| `items[abc]` | `array index must be a non-negative integer.` |
| `items[-1]` | `array index must be a non-negative integer.` — negative indexes are not Python |

## Which twin to call: read the last step

The file-edit API is split in two (`…OBJECT`, `…ARRAY`), and the caller has to pick. The parser
already knows the answer, so ask it
([TextDAPJsonEdit.d:113](../../../JsonDAPtest/TextDAPJsonEdit.d#L113)):

```d
Optional!bool itemShape(string jsonPath, out string message)
{
    PathStep[] steps;

    try
    {
        steps = JsonAP.APJsonPathParser(jsonPath);        // the parser throws on a broken path
    }
    catch (BaseExceptionAP caught)
    {
        message = caught.msg;                             // report the reason instead of crashing
        return Optional!bool.init;                        // an empty answer
    }

    if (steps.length == 0)
    {
        message = format!"'%s' names no member or item."(jsonPath);
        return Optional!bool.init;
    }

    return Optional!bool(steps[$ - 1].type == PathStepType.ArrayIndex);   // true = an array item
}
```

| Line | What it does |
|---|---|
| `steps[$ - 1]` | the last step — the node the edit will touch |
| `== PathStepType.ArrayIndex` | `items[2]` ends in an index, `settings.retry` ends in a key |
| `Optional!bool` | three outcomes: an array, an object, or "the path is unusable" |

The app uses that answer in [TextDAPJsonEdit.d:54](../../../JsonDAPtest/TextDAPJsonEdit.d#L54) to
choose between `APremoveJsonItemARRAYWithMessage` and `APremoveJsonItemOBJECTWithMessage`.
[TextDAPJsonTools.d:70](../../../JsonDAPtest/TextDAPJsonTools.d#L70) prints the same steps for a
path the user typed.

Next: [05 — Reading one value](05-reading-a-value.md)
