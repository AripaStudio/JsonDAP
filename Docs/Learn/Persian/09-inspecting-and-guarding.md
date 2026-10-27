# ۰۹ — بررسی و نگهبان‌ها

فهرست: [StartPe.md](../../StartPe.md) · قبلی: [۰۸](08-sumtype.md)

هیچ‌چیز در این فصل فایل نمی‌نویسد. این‌ها آن تابع‌هایی هستند که تصمیم می‌گیرند یک تکه‌متن
ارزش این را دارد که به بقیه‌ی کتابخانه سپرده شود یا نه.

## این JSON از چه نوعی است؟

```d
assert(JsonAP.APisValidJson(`{"a":1}`));
assert(!JsonAP.APisValidJson(`{"a":`));              // no exception, just false

assert(JsonAP.APisJsonObject(`{"a":1}`));
assert(JsonAP.APisJsonArray(`[1,2]`));
assert(JsonAP.APisJsonNumber(`42`));
assert(JsonAP.APisJsonString(`"text"`));
assert(!JsonAP.APisJsonObject(`[1,2]`));              // valid JSON, wrong shape
```

| متد | چه چیزی می‌پرسد |
|---|---|
| `APisValidJson(text)` | آیا اصلاً parse می‌شود |
| `APisJsonObject` / `APisJsonArray` / `APisJsonNumber` / `APisJsonString` | گره‌ی **بالایی** (top) چیست |
| `APgetJsonItemCount(text)` | `Optional!long` — تعداد کلیدهای یک شیء یا عنصرهای یک آرایه، برای بقیه خالی |
| `APprettyPrintJson(text)` | `Optional!string`، با تورفتگیِ چهار فاصله |
| `APgetJsonValueType(JSONValue)` | نوع گره را از `std.json` به شکل `JSONType` برمی‌گرداند — برای گره‌ای که همین حالا در دست دارید |

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

اپ به سؤال «این فایل چیست؟» با همان چهار predicate و به ترتیب جواب می‌دهد
([TextDAPJsonTools.d:232](../../../JsonDAPtest/TextDAPJsonTools.d#L232)) و تعداد آیتم‌ها را کنار
دلیلِ شکستِ یک بارگذاری چاپ می‌کند
([TextDAPSession.d:44](../../../JsonDAPtest/TextDAPSession.d#L44) — `%s holds %d items but is not a JSON object`).

## خانواده‌ی رقم‌ها

در ویرایشگر متن، عددها تایپ می‌شوند، با هر رقمی که کیبوردِ کاربر تولید کرده باشد.

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

| خط | چه کاری انجام می‌دهد |
|---|---|
| `APisDigitAP(dchar)` | یک نویسه، سه نوشتار (script) — دروازه‌ی ورودیِ یک اسکنرِ دست‌نویس |
| `APisInteger` / `APisSignedInteger` / `APisDecimal` | سه سؤالِ کاملاً متفاوت؛ همانی را بردارید که منظورتان است |
| `APnormalizeDigitsAP(string)` | رقم‌ها را به ASCII، `٫`/`٬` را به `.` و `−` را به `-` تبدیل می‌کند؛ هر بایتِ دیگر دست‌نخورده می‌ماند |

اول نرمال‌سازی **و بعد** تبدیل، همان چیزی است که در پارسرِ مسیر اجازه می‌دهد `rows[۲]` کار کند
([۰۴](04-path-syntax.md)). demoای که همه‌ی این‌ها را چاپ می‌کند
[TextDAPConvert.d:224](../../../JsonDAPtest/TextDAPConvert.d#L224) است، و promptِ عددیِ کنسول قبل از
هر `to!int`، `APstrIsNil` را با `APisInteger` ترکیب می‌کند
([TextDAPConsole.d:59](../../../JsonDAPtest/TextDAPConsole.d#L59)).

## نگهبان‌های فضای خالی

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

نامش شبیه یک predicate است که bool برمی‌گرداند؛ ولی نیست — `void` است و دو پارامتر `out` می‌نویسد.
وقتی ورودی `null` است یا خالی یا فقط فاصله‌ی سفید، flag برابر `true` می‌شود و پیام همان پارامتری را
نام می‌برد که داده‌اید.

```d
assert(!JsonAP.APCheckStringIsNullArray(["a", "b"]));        // all of them hold text
assertThrown!UnknownErrorExceptionAP(JsonAP.APCheckStringIsNullArray(["a", ""]));
assert(JsonAP.APCheckStringIsNullArray([]));                  // an empty list answers true
```

[PublicCodeOtherCode.d:132](../../../JsonDAP/PublicCodeOtherCode.d#L132): فهرست را طی می‌کند، و یک
`UnknownErrorExceptionAP` همه‌ی indexهای خاطی و پیامشان را با هم با خودش می‌آورد. پاسخِ سه‌حالتیِ
نسخه‌ی آرایه‌ای (`false` = تمیز، `true` = چیزی برای بررسی نیست، throw = دست‌کم یک فضای خالی) دلیلش
است که اپ همان را یک بار و در ابتدای هر نوشتن صدا می‌کند
([TextDAPSession.d:123](../../../JsonDAPtest/TextDAPSession.d#L123)).

## نام‌های منسوخ (Deprecated)

`APStrIsNUll` ([JsonDAP.d:160](../../../JsonDAP/JsonDAP.d#L160)) و `StrIsNUll` هنوز export می‌شوند،
با برچسب `deprecated`، و کار را به املای درستِ همان نام‌ها می‌سپارند. دلیلِ نگه‌داشتنشان این قاعده‌ی
کتابخانه است که در یک patch هیچ‌چیز حذف نمی‌شود؛ در `2.5.0` برداشته می‌شوند. از `APstrIsNil` استفاده
کنید.

بعدی: [۱۰ — استثناها](10-exceptions.md)
