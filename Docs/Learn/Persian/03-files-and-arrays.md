# ۰۳ — فایل‌ها و آرایه‌ها

فهرست: [StartPe.md](../../StartPe.md) · قبلی: [۰۲](02-types-and-the-round-trip.md)

## یک ذخیره، یک بارگذاری

این یک `save` تا حد زیادی عین خودش
([TextDAPSession.d:83](../../../JsonDAPtest/TextDAPSession.d#L83)) — serialize، ادغام در فایلِ
موجود، و بعد خواندن دوبارهٔ نتیجه:

```d
JSONValue wire = JsonAP.APserializeToJson!SessionFile(session);

if (JsonAP.APexistsFile(filePath))
{
    if (JsonAP.APmergeJsonWithMessage(filePath, wire, true, false, message))
    {
        return verify(filePath, message);
    }
}

if (!JsonAP.APwriteJsonFile!JSONValue(filePath, wire))
{
    message = format!"nothing was written to %s."(filePath);
    return false;
}
```

چرا ادغام و نه بازنویسی؟ کلیدهایی که برنامه نمی‌شناسد — مثل یک `cursor` که قابلیت دیگری
نوشته — بعد از ذخیره سرِ جایشان می‌مانند. بعد `verify` دوباره فایل را می‌خواند: هست، خواندنی
است، و هنوز JSON معتبر است.

| خط | چه کاری انجام می‌دهد |
|---|---|
| `APexistsFile(path)` | فایل نبود `false`؛ هرگز استثنا نمی‌دهد |
| `APwriteJsonFile!T` | `bool`؛ آن `!T` نوعِ آرگومان دوم است |
| `APmergeJsonWithMessage` | `wire` را در فایلِ روی دیسک ادغام می‌کند؛ پاسخ `bool` + `message` |
| `verify` | موفقیتِ خام ممنوع: آنچه نوشته شد باید دوباره خوانده شود |

`APreadJsonFile!T` وقتی فایل نباشد `FileOperationExceptionAP` پرتاب می‌کند:

```d
catch (FileOperationExceptionAP caught)
{
    caught.filePath;      // کدام فایل
    caught.operationType; // "read"
}
```

## پوشه‌های والد برایتان ساخته می‌شوند

```d
// فایلِ وضعیت در یک مسیر تو در تو، در اولین اجرا:
JsonAP.APwriteJsonFile!JSONValue("state/session/textdap_session.json", wire);
// state/ و state/session/ در همین مسیر ساخته می‌شوند
```

نیازی به `mkdirRecurse` دستی نیست: نویسنده پوشه‌های نبوده را خودش می‌سازد.

## یک آرایه از رکوردها

خروجی تاریخچه یک `JSONValue[]` می‌سازد و آن را به‌صورت یک سند می‌نویسد
([TextDAPConvert.d:102](../../../JsonDAPtest/TextDAPConvert.d#L102)):

```d
JSONValue[] wire;
foreach (record; records)
{
    wire ~= JsonAP.APserializeToJsonArray!DocumentRecord(record);  // یک رکورد -> یک آرایه
}

JsonAP.APwriteJsonFile!JSONValue(outPath, JSONValue(wire));

Optional!(DocumentRecord[]) imported = JsonAP.APreadJsonArray!DocumentRecord(outPath);
```

`APserializeToJsonArray!T` همیشه یک آرایهٔ **تک‌عضوی** پیرامون همان رکورد برمی‌گرداند؛ برای همین
الحاق با `~=` کار درست را می‌کند. `APreadJsonArray!T` نوع عضو `T` را می‌خواهد، نه `T[]`، و فایلی
که ریشه‌اش object است را رد می‌کند.

همان تبدیل از متن (نه فایل) با `APdeserializeJsonArray!T` است
([TextDAPConvert.d:186](../../../JsonDAPtest/TextDAPConvert.d#L186)):

```d
auto many = JsonAP.APdeserializeJsonArray!DocumentRecord(pack);
assert(many.get.length == 2);
assertThrown!JSONConvertExceptionAP(JsonAP.APdeserializeJsonArray!DocumentRecord(`{"x":5}`));
```

## API فایل در یک جدول

| متد | چه برمی‌گرداند | حالت شکست |
|---|---|---|
| `APwriteJsonFile!T(path, data)` | `bool` | `false`، یا یک استثنای کتابخانه از لایهٔ OS |
| `APreadJsonFile!T(path)` | `Optional!T` | وقتی فایل یا JSONِ آن قابل استفاده نباشد پرتاب می‌کند |
| `APreadJsonArray!T(path)` | `Optional!(T[])` | وقتی ریشه array نباشد پرتاب می‌کند |
| `APgetJsonFileSize(path)` | `Optional!long` | اندازه ناشدنی → `Optional` خالی |
| `APexistsFile(path)` | `bool` | `false`، هرگز استثنا نمی‌دهد |
| `APexists(path)` | `bool` | همان پاسخ، با نام قدیمی‌تر |

بعدی: [۰۴ — نحوِ مسیر](04-path-syntax.md)