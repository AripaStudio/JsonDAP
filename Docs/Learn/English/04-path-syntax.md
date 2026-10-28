# 04 — Path syntax

Index: [StartEn.md](../../StartEn.md) · Previous: [03](03-files-and-arrays.md)

## What a path is

Every read and every edit addresses JSON with a dotted path:

```text
options.autosave          a member
documents[2].file_path    an array item, then a member
rows[0][1]                a nested array
weird\.key                a literal dot inside a key (escaped)
items[۲]                  a Persian digit index — normalized to 2
```

A path parses into `PathStep[]`; each step is either an object key or an array index.

## Asking the parser what it saw

`explainPath` calls the parser and prints each step it found
([TextDAPJsonTools.d:74](../../../JsonDAPtest/TextDAPJsonTools.d#L74)):

```d
try
{
    PathStep[] steps = JsonAP.APJsonPathParser(jsonPath);

    if (steps.length == 0)
    {
        sayFail(format!"'%s' resolved to no steps."(jsonPath));
        return false;
    }

    foreach (index, step; steps)
    {
        // step.type == PathStepType.ObjectKey   -> "1. object key 'options'"
        // step.type == PathStepType.ArrayIndex  -> "2. array index 2"
    }
    return true;
}
catch (BaseExceptionAP caught)
{
    sayFail(caught.msg);   // the parser refuses bad paths instead of guessing
}
```

Useful when a path is typed by hand and you want to show exactly what was understood.

TextDAP renders one line per step with a three-line function:

```d
private static string stepText(PathStep step)
{
    if (step.type == PathStepType.ObjectKey)
    {
        return format!"object key '%s'"(step.key);   // only .key is meaningful here
    }

    return format!"array index %d"(step.index);      // only .index is meaningful here
}
```

Branch on `.type` first — reading the other member is undefined behaviour.

## Which edit method does this path need?

Object member or array slot — decide from the **last step** and call the matching
`…OBJECT…` or `…ARRAY…` method
([TextDAPJsonEdit.d:136](../../../JsonDAPtest/TextDAPJsonEdit.d#L136)):

```d
private static Optional!bool itemShape(string jsonPath, out string message)
{
    message = "";

    string blankReason;
    bool blankFlag;
    JsonAP.APstrIsNil(jsonPath, "json path", blankFlag, blankReason);

    if (blankFlag)
    {
        message = blankReason;
        return Optional!bool.init;
    }

    PathStep[] steps;

    try
    {
        steps = JsonAP.APJsonPathParser(jsonPath);
    }
    catch (BaseExceptionAP caught)
    {
        message = caught.msg;
        return Optional!bool.init;
    }

    if (steps.length == 0)
    {
        message = format!"'%s' names no member or item."(jsonPath);
        return Optional!bool.init;
    }

    return Optional!bool(steps[$ - 1].type == PathStepType.ArrayIndex);
}
```

| Line | What it does |
|---|---|
| `APstrIsNil` first | a blank path never reaches the parser |
| `steps[$ - 1]` | the last step — the node the edit will touch |
| `… == ArrayIndex` | `documents[2].title` ends in an index, `options.autosave` in a key |
| `Optional!bool` | three outcomes: an array, an object, or "the path is unusable" |

That answer is all `deleteAt` needs — the caller never says which shape the path had:

```d
Optional!bool shape = itemShape(jsonPath, message);
if (shape.isNull)
{
    return false;
}

bool removed;
if (shape.get)   // true -> the path ends in an index
{
    removed = JsonAP.APremoveJsonItemARRAYWithMessage(filePath, jsonPath, message);
}
else
{
    removed = JsonAP.APremoveJsonItemOBJECTWithMessage(filePath, jsonPath, message);
}
```

## The refusals

The parser refuses instead of guessing:

| Bad path | Refused as |
|---|---|
| `""` or whitespace only | `InvalidArgumentExceptionAP` — `JSON path is empty.` |
| `a..b` (empty key) | `InvalidArgumentExceptionAP` — `…contains an empty key.` |
| `items[3` (unclosed) | `InvalidArgumentExceptionAP` — `…missing closing bracket.` |
| `items]` (no opener) | `InvalidArgumentExceptionAP` — `']' without '['.` |
| `items[abc]`, `items[-1]` | `InvalidArgumentExceptionAP` — `…must be a non-negative integer.` |
| `items[2147483648]` | `ConvertExceptionAP` — out of `int` |

Negative indexes are refused too — no silent counting from the end. An app that wants its own
message wraps the call in `catch (BaseExceptionAP)` exactly like `explainPath` above.

## Digits and escapes

- Persian `۲` and Arabic-Indic `٢` both normalize to `2`, so users can type either.
- `\.` puts a literal dot inside a key: `weird\.key.next` is the key `weird.key`, then `next`.
- `[` and `]` inside a key are not special unless they open an index.

Normalise digits before composing a path ([09](09-inspecting-and-guarding.md)) and it reaches
the parser already clean.

Next: [05 — Reading one value](05-reading-a-value.md)