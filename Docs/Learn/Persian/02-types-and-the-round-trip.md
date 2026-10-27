# ۰۲ — انواع و رفت‌وبرگشت

فهرست: [StartPe.md](../../StartPe.md) · قبلی: [۰۱](01-setup.md)

## نوعی که زیر آزمایش است

```d
struct Note
{
    @JsonName("text") string body;          // the wire key is "text", not "body"
    @JsonName("tags") string[] labels;      // arrays of strings are arrays on the wire
    @JsonIgnore string cacheKey;            // never written, never read
}
```

`@JsonName` و `@JsonIgnore` تنها دو صفتی هستند که کتابخانه آن‌ها را می‌خواند
([CoreAP.d:19](../../../JsonDAP/CoreAP.d#L19)، [CoreAP.d:24](../../../JsonDAP/CoreAP.d#L24)).
فیلدهایی که هیچ صفتی ندارند نام D خودشان را نگه می‌دارند.

## بیرون، و بعد دوباره درون

```d
import std.json : JSONValue, JSONType;
import JsonDAP;

Note note = Note("first post", ["d", "json"], "never-serialised");

JSONValue wire = JsonAP.APserializeToJson!Note(note);   // Note  -> JSONValue
auto back      = JsonAP.APdeserializeJson!Note(wire.toString());   // text -> Optional!Note

assert(back.get.body == "first post");
assert(back.get.labels == ["d", "json"]);
assert(back.get.cacheKey is null);                      // the ignored field stayed at its default
```

خروجی `wire.toString()` برابر است با `{"tags":["d","json"],"text":"first post"}` — ترتیب
کلیدها از آرایهٔ انجمنی (associative array) `std.json` پیروی می‌کند، پس هرگز متن تولیدشده را با
متن انتظار مقایسه نکنید.

| خط | چه کاری انجام می‌دهد |
|---|---|
| `APserializeToJson!Note` | نویسندهٔ سطح‌بالا؛ `APserializeTToJsonValue!Note` نسخهٔ سطح‌پایین است، با همان خروجی |
| `APdeserializeJson!Note` | **سخت‌گیر**: هر فیلد باید حاضر باشد، وگرنه استثنا پرتاب می‌کند |
| `back.get` | خواننده پاسخ `Optional!Note` می‌دهد؛ `.get` فقط بعد از بررسی `.isNull` قانونی است |

مرجع اپ: [TextDAPConvert.d:18](../../../JsonDAPtest/TextDAPConvert.d#L18)
(`APserializeTToJsonValue` → `APgetJsonValueType` → `APconvertJsonValueToT`، و بعد یک مقایسهٔ
فیلد‌به‌فیلد) و [TextDAPModel.d:27](../../../JsonDAPtest/TextDAPModel.d#L27) برای مدلی که از هر
نگاشتِ جدول پایین استفاده می‌کند.

## قرارداد

| نوع D | روی سیم |
|---|---|
| `struct` / `class` | object |
| `T[]` | array |
| `enum` | عدد صحیح، و تنها یک **عضو معتبر** |
| `Optional!T` (= `Nullable!T`) | وقتی خالی است `null` |
| مرجع کلاسِ `null` | `null` |
| `SumType` | `{"tag":"<member>","value":<payload>}` — ر.ک [۰۸](08-sumtype.md)

## enum و Nullable، در هر دو جهت

```d
enum Priority { low = 0, high = 1 }

struct Task
{
    @JsonName("title") string title;
    @JsonName("priority") Priority priority;
    @JsonName("done") Optional!bool done;
}

JSONValue written = JsonAP.APserializeToJson!Task(Task("ship it", Priority.high, Optional!bool.init));
// {"done":null,"priority":1,"title":"ship it"}

assert(written.object["done"].type == JSONType.NULL);        // an empty Nullable is JSON null
assertThrown!JSONConvertExceptionAP(JsonAP.APdeserializeJson!Task(`{"title":"x","priority":9}`));
```

`9` یک `Priority` نیست، پس خواننده به‌جای تبدیل (cast) آن را رد می‌کند. این همان نگهبانی است که اپ
در [TextDAPConvert.d:132](../../../JsonDAPtest/TextDAPConvert.d#L132) نشان می‌دهد، جایی که کل
مقدار ردشده از فیلدهای خودِ استثنا چاپ می‌شود.

## سخت‌گیر در برابر مداراگر

```d
struct Options
{
    @JsonName("autosave") bool autosave;
    @JsonName("tab_width") int tabWidth;
}

auto lenient = JsonAP.APdeserializeJsonLenient!Options(`{"autosave":true}`);
assert(lenient.get.tabWidth == 0);                  // the missing field keeps its type default

assertThrown!JSONConvertExceptionAP(JsonAP.APdeserializeJson!Options(`{"autosave":true}`));
```

| موقعیت | سخت‌گیر | مداراگر |
|---|---|---|
| فیلد غایب | `JSONConvertExceptionAP` با `MissingField` | مقدار پیش‌فرض نوع را نگه می‌دارد |
| فیلد `Optional` / `class` غایب | `JSONConvertExceptionAP` | خالی / `null` می‌ماند |
| مقدار `enum` ناشناخته | خطا | خطا — هرگز cast نمی‌شود |
| tag ناشناختهٔ `SumType` | خطا با فهرست کردن tagها | خطا با فهرست کردن tagها |

مرجع اپ: [TextDAPConvert.d:258](../../../JsonDAPtest/TextDAPConvert.d#L258) همان متن را به هر دو
روش می‌خواند و اختلاف را چاپ می‌کند؛
[TextDAPSession.d:53](../../../JsonDAPtest/TextDAPSession.d#L53) یک session را عمداً به‌صورت
مداراگر بارگذاری می‌کند، چون فایلی که دستی ویرایش شده ممکن است کلیدهایی را نداشته باشد.

## یک `JSONValue` وارد، یک `T` خارج

```d
JSONValue node = parseJSON(`{"autosave":true,"tab_width":8}`);
auto viaLowLevel = JsonAP.APconvertJsonValueToT!Options(node, false);   // false = strict
assert(viaLowLevel.get.tabWidth == 8);
```

`APconvertJsonValueToT!T(JSONValue, bool lenient = false)` همان چیزی است که هر خواننده‌ای در
آخرین مرحله به آن زنگ می‌زند؛ وقتی به‌کارش ببرید که درخت پارسه‌شده را از قبل در دست دارید و فقط
می‌خواهید یک گره را تبدیل کنید.

بعدی: [۰۳ — فایل‌ها و آرایه‌ها](03-files-and-arrays.md)
