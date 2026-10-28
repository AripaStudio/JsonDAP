# ۰۴ — نحوِ مسیر

فهرست: [StartPe.md](../../StartPe.md) · قبلی: [۰۳](03-files-and-arrays.md)

## مسیر چیست

هر خواندن و هر ویرایش، JSON را با یک مسیر نقطه‌چین آدرس می‌زند:

```text
options.autosave          یک کلید
documents[2].file_path    اول یک عضو آرایه، بعد یک کلید
rows[0][1]                آرایه‌ی تودرتو
weird\.key                نقطه‌ای که داخل کلید است (escape شده)
items[۲]                  ایندکسِ فارسی — به ۲ نرمال می‌شود
```

یک مسیر به `PathStep[]` تجزیه می‌شود؛ هر گام یا کلیدِ شیء است یا ایندکسِ آرایه.

## از پارسر پرسیدن چه دیده است

`explainPath` پارسر را صدا می‌زند و هر گامی را که پیدا کرده چاپ می‌کند
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
    sayFail(caught.msg);   // پارسر به‌جای حدس زدن، مسیر بد را رد می‌کند
}
```

به‌دردِ جایی می‌خورد که مسیری دستی تایپ شده و می‌خواهید دقیقاً همان‌چیزی را که فهمیده‌اید
نشان دهید.

خواندنِ دو نوع گام، همان تابع سه‌خطیِ TextDAP است:

```d
private static string stepText(PathStep step)
{
    if (step.type == PathStepType.ObjectKey)
    {
        return format!"object key '%s'"(step.key);   // فقط .key اینجا معنادار است
    }

    return format!"array index %d"(step.index);      // فقط .index اینجا معنادار است
}
```

اول روی `.type` شاخه بزنید — خواندن عضوِ دیگر undefined behaviour است.

## این مسیر به کدام متد ویرایش نیاز دارد؟

کلیدِ شیء یا شکافِ آرایه — از روی **گام آخر** تصمیم بگیرید و `…OBJECT…` یا `…ARRAY…`
متناظرش را صدا بزنید
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

| خط | چه می‌کند |
|---|---|
| اول `APstrIsNil` | مسیرِ خالی هرگز به پارسر نمی‌رسد |
| `steps[$ - 1]` | گام آخر — همان گره‌ای که ویرایش به آن دست می‌زند |
| `… == ArrayIndex` | `documents[2].title` با ایندکس تمام می‌شود، `options.autosave` با کلید |
| `Optional!bool` | سه نتیجه: آرایه، شیء، یا «مسیر قابل استفاده نیست» |

همین پاسخ همه‌چیزی است که `deleteAt` لازم دارد — فراخوان هرگز نمی‌پرسد مسیر چه شکلی بوده است:

```d
Optional!bool shape = itemShape(jsonPath, message);
if (shape.isNull)
{
    return false;
}

bool removed;
if (shape.get)   // true -> مسیر با ایندکس تمام می‌شود
{
    removed = JsonAP.APremoveJsonItemARRAYWithMessage(filePath, jsonPath, message);
}
else
{
    removed = JsonAP.APremoveJsonItemOBJECTWithMessage(filePath, jsonPath, message);
}
```

## رد کردن‌ها

پارسر به‌جای حدس زدن رد می‌کند:

| مسیر بد | رد می‌شود به‌صورت |
|---|---|
| `""` یا فقط فاصله | `InvalidArgumentExceptionAP` — `JSON path is empty.` |
| `a..b` (کلید خالی) | `InvalidArgumentExceptionAP` — `…contains an empty key.` |
| `items[3` (باز نشده) | `InvalidArgumentExceptionAP` — `…missing closing bracket.` |
| `items]` (بازکننده ندارد) | `InvalidArgumentExceptionAP` — `']' without '['.` |
| `items[abc]`، `items[-1]` | `InvalidArgumentExceptionAP` — `…must be a non-negative integer.` |
| `items[2147483648]` | `ConvertExceptionAP` — بیرون از محدودهٔ `int` |

ایندکس منفی هم رد می‌شود — شمارشِ بی‌صدا از انتها در کار نیست. اپی که پیامِ خودش را می‌خواهد،
دقیقاً مثل `explainPath` بالا آن را در `catch (BaseExceptionAP)` می‌پیچد.

## ارقام و escape

- `۲` فارسی و `٢` عربی-هندی هر دو به `2` نرمال می‌شوند؛ کاربر هر دو را می‌تواند تایپ کند.
- `\.` نقطه‌ای را داخل کلید می‌گذارد: `weird\.key.next` یعنی کلید `weird.key`، بعد `next`.
- `[` و `]` داخل یک کلید خاص نیستند، مگر که ایندکس را باز کنند.

پیش از ساختنِ مسیر، ارقام را نرمال کنید ([۰۹](09-inspecting-and-guarding.md)) تا تمیز به پارسر
برسد.

بعدی: [۰۵ — خواندن یک مقدار](05-reading-a-value.md)