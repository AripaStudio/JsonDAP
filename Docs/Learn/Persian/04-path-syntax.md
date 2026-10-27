# ۰۴ — نحوِ مسیر

فهرست: [StartPe.md](../../StartPe.md) · قبلی: [۰۳](03-files-and-arrays.md)

یک دستور (grammar) واحد که `APgetJsonValue`، `APJsonPathParser` و هر متد ویرایش فایل از آن
استفاده می‌کنند. از 2.4.0 دیگر هیچ پارسر دومی نیست که بشود با آن اختلاف‌نظر داشت
([PublicCodeOtherCode.d:165](../../../JsonDAP/PublicCodeOtherCode.d#L165)).

## یک مسیر به چه تبدیل می‌شود

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

`PathStep` و `PathStepType` با `import JsonDAP;` می‌رسند. خواندن `steps[0].index` رفتار
تعریف‌نشده (undefined behaviour) است — نخست روی `.type` شاخه بزنید.

## شکل‌ها

| شکل | معنا |
|---|---|
| `a.b` | کلید `b` از نوع object داخل object به نام `a` |
| `items[2]` | سومین عضو آرایهٔ `items` |
| `rows[0][1]` | ایندکس‌های زنجیره‌ای — دو گام، دو بار `ArrayIndex` |
| `weird\.key.next` | `\` کاراکتر بعدی را escape می‌کند، پس یک کلید می‌تواند `.` `[` `]` را در خود نگه دارد |
| `rows[۲]` | ارقام فارسی و عربی پیش از خواندن ایندکس یکسان‌سازی می‌شوند |

```d
PathStep[] escaped = JsonAP.APJsonPathParser(`weird\.key.next`);
assert(escaped.length == 2);
assert(escaped[0].key == "weird.key");        // the dot is part of the name, not a separator

PathStep[] persian = JsonAP.APJsonPathParser("rows[۲]");
assert(persian[1].index == 2);                // U+06F2 became ASCII before to!int
```

`APnormalizeDigitsAP` ([PublicCodeOtherCode.d:38](../../../JsonDAP/PublicCodeOtherCode.d#L38)) همان
تابعی است که این کار را می‌کند؛ public است تا آن را روی ورودی خودتان به‌کار ببرید — ر.ک
[۰۹](09-inspecting-and-guarding.md).

## مسیر خراب رد می‌شود، هرگز حدس زده نمی‌شود

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

| مسیر | پیام |
|---|---|
| `""`, `"   "` | `JSON path is empty.` |
| `a..b` | `JSON path contains an empty key.` |
| `items[3` | `JSON path has a missing closing bracket.` |
| `items]` | `JSON path has a ']' without '['.` |
| `items[0]x` | `Unexpected character after ']'.` |
| `items[abc]` | `array index must be a non-negative integer.` |
| `items[-1]` | `array index must be a non-negative integer.` — ایندکس منفی مثل Python نیست |

## کدام دوقلو را صدا بزنید: گام آخر را بخوانید

API ویرایش فایل به دو دسته تقسیم شده (`…OBJECT`، `…ARRAY`) و انتخاب با فراخوان است. پارسر از
قبل جواب را می‌داند، پس از خودش بپرسید
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

| خط | چه کاری انجام می‌دهد |
|---|---|
| `steps[$ - 1]` | گام آخر — همان گره‌ای که ویرایش به آن دست می‌زند |
| `== PathStepType.ArrayIndex` | `items[2]` با یک ایندکس تمام می‌شود، `settings.retry` با یک کلید |
| `Optional!bool` | سه نتیجه: یک array، یک object، یا «مسیر قابل استفاده نیست» |

اپ آن پاسخ را در [TextDAPJsonEdit.d:54](../../../JsonDAPtest/TextDAPJsonEdit.d#L54) به‌کار می‌برد تا
میان `APremoveJsonItemARRAYWithMessage` و `APremoveJsonItemOBJECTWithMessage` یکی را انتخاب کند.
[TextDAPJsonTools.d:70](../../../JsonDAPtest/TextDAPJsonTools.d#L70) همان گام‌ها را برای مسیری که
کاربر تایپ کرده چاپ می‌کند.

بعدی: [۰۵ — خواندن یک مقدار](05-reading-a-value.md)
