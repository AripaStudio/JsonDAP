# ۰۹ — بررسی و نگهبان‌ها

فهرست: [StartPe.md](../../StartPe.md) · قبلی: [۰۸](08-sumtype.md)

اینجا فایلی نوشته نمی‌شود. این‌ها بررسی‌هایی‌اند که **پیش از** اعتماد به متنِ یک فایل، جعبهٔ مسیر
یا کیبورد انجام می‌شوند.

## این JSON از چه نوعی است؟

```d
assert(JsonAP.APisValidJson(`{"a":1}`));
assert(!JsonAP.APisValidJson(`{"a":`));              // false، بدون استثنا

assert(JsonAP.APisJsonObject(`{"a":1}`));
assert(JsonAP.APisJsonArray(`[1,2]`));
assert(JsonAP.APisJsonNumber(`42`));
assert(JsonAP.APisJsonString(`"text"`));
assert(!JsonAP.APisJsonObject(`[1,2]`));              // JSON معتبر، شکلِ دیگر
```

TextDAP جوابِ «این فایل چیست؟» را با پرسیدنِ به ترتیبِ هر چهار predicate می‌دهد، و وقتی
بارگذاری شکست می‌خورد، تعداد را کنارِ دلیل می‌گذارد:

```d
private static string shapeOf(string jsonContent)
{
    if (JsonAP.APisJsonObject(jsonContent)) { return "object"; }
    if (JsonAP.APisJsonArray(jsonContent))  { return "array"; }
    if (JsonAP.APisJsonNumber(jsonContent)) { return "number"; }
    if (JsonAP.APisJsonString(jsonContent)) { return "string"; }
    return "other";
}

// و وقتی متن object نیست:
if (!JsonAP.APisValidJson(text))
{
    Optional!long count = JsonAP.APgetJsonItemCount(text);
    // "%s holds %d items but is not a JSON object."
}
```

```d
if (!JsonAP.APisValidJson(text))
{
    Optional!long count = JsonAP.APgetJsonItemCount(text);
    // "%s holds %d items but is not a JSON object."
}
```

نمایِ مرتب‌تر، وقتی می‌خواهید پارسه‌شده را نشان دهید:

```d
Optional!string pretty = JsonAP.APprettyPrintJson(`{"a":1}`);
// {
//     "a": 1
// }
// یک Optional!string: وقتی متن JSON نیست خالی است
```

| متد | چه می‌گوید |
|---|---|
| `APisValidJson(text)` | اصلاً parse می‌شود یا نه |
| `APisJsonObject` / `APisJsonArray` / `APisJsonNumber` / `APisJsonString` | شکلِ گرهِ **بالایی** |
| `APgetJsonItemCount(text)` | `Optional!long` — کلیدهای شیء یا عنصرهای آرایه، بقیه خالی |
| `APprettyPrintJson(text)` | `Optional!string` با تورفتگیِ چهار فاصله‌ای |
| `APgetJsonValueType(JSONValue)` | نوعِ گرهی که همین حالا در دست دارید |

## خانوادهٔ رقم‌ها

اعداد «تایپ» می‌شوند، با هر رقمی که کیبورد تولید کرده باشد.

```d
assert(JsonAP.APisDigitAP('7'));
assert(JsonAP.APisDigitAP('۵'));              // فارسی U+06F5
assert(JsonAP.APisDigitAP('٧'));              // عربی-هندی U+0667
assert(!JsonAP.APisDigitAP('x'));

assert(JsonAP.APisInteger("123"));            // فقط دنبالهٔ رقم — بدون علامت، بدون نقطه
assert(!JsonAP.APisInteger("+7"));
assert(!JsonAP.APisInteger("12.5"));

assert(JsonAP.APisSignedInteger("-12"));      // علامتِ اختیاری، بعد ارقام
assert(JsonAP.APisSignedInteger("−7"));        // منهای U+2212، اول نرمال می‌شود

assert(JsonAP.APisDecimal("12.5"));           // علامت، ارقام، یک نقطه، ارقام
assert(JsonAP.APisDecimal("۱۲٫۵"));            // ارقام و نقطهٔ فارسی
assert(!JsonAP.APisDecimal("1e9"));           // شکلِ توان ندارد
assert(!JsonAP.APisDecimal("12"));            // صحیح ≠ اعشاری

assert(JsonAP.APnormalizeDigitsAP("۱۲٫۵") == "12.5");
assert(JsonAP.APnormalizeDigitsAP("−7") == "-7");
```

| خط | چه کاری انجام می‌دهد |
|---|---|
| `APisDigitAP(dchar)` | یک نویسه، سه نوشتار — دروازه‌ای که اسکنرِ دست‌نویس از آن رد می‌شود |
| `APisInteger` / `APisSignedInteger` / `APisDecimal` | سه سؤال متفاوت؛ همانی را بردارید که منظورتان است |
| `APnormalizeDigitsAP(string)` | رقم‌ها → ASCII، `٫`/`٬` → `.`، `−` → `-`؛ بقیهٔ بایت‌ها دست‌نخورده |

`digitGateDemo` همین جدول را از کاوشِ واقعی می‌سازد — یک خط برای هر نمونه، بعد سه گارد:

```d
foreach (sample; ["7", "+7", "−7", "۱۲", "12.5", "۱۲٫۵", "1e9", "x"])
{
    gates ~= CL_TextDap_Frame.fieldText(sample, format!"whole %s, signed %s, decimal %s"
            (CL_TextDap_Console.yesNo(JsonAP.APisInteger(sample)),
            CL_TextDap_Console.yesNo(JsonAP.APisSignedInteger(sample)),
            CL_TextDap_Console.yesNo(JsonAP.APisDecimal(sample))));
}
```

و promptِ عددی، پیش از هر `to!int`، گاردِ خالی را با `APisInteger` ترکیب می‌کند:

```d
JsonAP.APstrIsNil(raw, "number", blankFlag, blankReason);
if (!blankFlag && JsonAP.APisInteger(raw))
{
    // حالا می‌شود تبدیل کرد
}
```

اول نرمال‌سازی و **بعد** تبدیل، همان چیزی است که به `items[۲]` اجازهٔ کار می‌دهد (ر.ک
[۰۴](04-path-syntax.md)).

## نگهبان‌های فضای خالی

`APstrIsNil` یک predicate با خروجی `bool` نیست — `void` است با دو پارامتر `out`: یک flag و یک
جمله که نامِ همان پارامتری را می‌برد که داده‌اید.

```d
bool flag; string reason;

JsonAP.APstrIsNil("notes.txt", "file path", flag, reason);
assert(!flag);                                   // مقدار واقعی: چیزی برای گفتن نیست

JsonAP.APstrIsNil("   ", "file path", flag, reason);
assert(flag);                                    // «این ورودی قابل استفاده نیست»
// reason: Parameter 'file path' cannot be just whitespace.
```

```d
assert(!JsonAP.APCheckStringIsNullArray(["a", "b"]));   // همه متن دارند
assert(JsonAP.APCheckStringIsNullArray([]));            // فهرست خالی -> true، چیزی برای بررسی نیست
// یک ورودیِ خالی -> UnknownErrorExceptionAP با فهرست همهٔ indexهای خاطی
```

هر نوشتنِ TextDAP با همین یک فراخوانی شروع می‌شود، پیش از هر دست‌زدنی به فایل:

```d
string[] blankInputs = [filePath, jsonPath];
if (JsonAP.APCheckStringIsNullArray(blankInputs))
{
    message = "the session path and the file path must both hold text.";
    return false;
}
```

فرمِ دوپارامتری همان کار را برای یک ورودی می‌کند — `load`، `explainPath`، `validateText` و
`readDocument` همه با همین شروع می‌شوند.

## نام‌های منسوخ (Deprecated)

`APStrIsNUll` و `StrIsNUll` هنوز export می‌شوند، با برچسب `deprecated`، و کار را به املای درستِ
همان نام‌ها می‌سپارند — در یک patch هیچ‌چیز حذف نمی‌شود. از `APstrIsNil` استفاده کنید.

بعدی: [۱۰ — استثناها](10-exceptions.md)