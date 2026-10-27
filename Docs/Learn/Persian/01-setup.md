# ۰۱ — نصب و راه‌اندازی

فهرست: [StartPe.md](../../StartPe.md)

## دو راه برای وابسته شدن به JsonDAP

JsonDAP یک **بستهٔ منبعی** (source package) برای dub است (`"targetType": "sourceLibrary"`). نه DLLای وجود دارد، نه کتابخانهٔ import و نه هیچ چیز دیگری که باید هم‌گام با سورس‌ها نگه داشته شود — dub فایل‌های `.d` را داخل build خود شما کامپایل می‌کند.

یک checkout که کنار پروژهٔ شما نشسته است:

```json
{
  "dependencies": {
    "jsondap": { "path": "../JsonDAP" }   // the folder holding JsonDAP/dub.json
  }
}
```

هر پروژهٔ دیگری، قفل‌شده روی یک tag:

```json
{
  "dependencies": {
    "jsondap": {
      "repository": "git+https://github.com/AripaStudio/JsonDAP.git",
      "version": "v2.4.1"                 // نام دقیق Git tag
    }
  }
}
```

JsonDAP روی registry رسمی dub نیست، پس `"jsondap": "~>2.4.1"` به هیچ چیز resolve نمی‌شود. نام Git tag برابر `v2.4.1` است؛ پیشوند `v` را در وابستگی نگه دارید.

## اولین خط‌های یک برنامه

```d
import std.json;          // JSONValue / JSONType / parseJSON stay Phobos' own types
import std.typecons;      // Nullable, which the library calls Optional
import JsonDAP;           // one module brings the whole API

struct Greeting
{
    @JsonName("text") string body;          // the wire key is "text"
}

void main()
{
    auto parsed = JsonAP.APdeserializeJson!Greeting(`{"text":"hello"}`);   // always qualified, always AP…
    if (!parsed.isNull)
    {
        parsed.get.body;                     // "hello"
    }
}
```

| خط | چه کاری انجام می‌دهد |
|---|---|
| `import std.json;` | `JsonDAP` آن نوع `JSONValue` را دوباره export نمی‌کند؛ خودتان import کنید |
| `import std.typecons;` | نوع بازگشتی خواننده‌ها `Nullable!T` است که با نام مستعار `Optional!T` صدا زده می‌شود |
| `import JsonDAP;` | `JsonAP`، `PathStep`، استثناها و traitها را در دسترس می‌گذارد |
| `JsonAP.AP…` | هر متد روی کلاس `JsonAP` به‌صورت `export static` است — تابع آزاد وجود ندارد |
| `APdeserializeJson!Greeting` | **متن JSONی** را می‌گیرد که گرهٔ بالاترین سطحش یک object است؛ یک `"text"` به‌تنهایی یا `[1,2]` رد می‌شود |

## build، test و برنامهٔ مرجع

```bash
dub build          # in your own package
dub test           # compiles the library and runs every unittest in it
```

مخزن یک مصرف‌کنندهٔ کامل به نام **TextDAP** را در `JsonDAPtest/` همراه دارد — ویرایشگر متن کنسولی که فایل وضعیتش یک سند JSON است. این بزرگ‌ترین تست واقعی این کتابخانه است، و هر باب از این آموزش به خطی اشاره می‌کند که همان کار را آنجا انجام می‌دهد.

```bash
cd JsonDAPtest
dub build --force  # Output/TextDAP.exe
dub test  --force  # the library's own test suite, living in JsonDAPtest/test/
```

| فایل | چرا خواندنش ارزش دارد |
|---|---|
| [TextDAPModel.d:27](../../../JsonDAPtest/TextDAPModel.d#L27) | structها، enum و به‌کارگیری `@JsonName` / `@JsonIgnore` |
| [TextDAPSession.d:18](../../../JsonDAPtest/TextDAPSession.d#L18) | بارگذاری: guard، بررسی exists، اعتبارسنجی، خواندن مداراگر و پلهٔ catch |
| [TextDAPSession.d:83](../../../JsonDAPtest/TextDAPSession.d#L83) | ذخیره: serialize، merge، نوشتن و راستی‌آزمایی |
| [TextDAPConvert.d:18](../../../JsonDAPtest/TextDAPConvert.d#L18) | رفت‌وبرگشت‌های یک رکورد، یک مکان‌نما (cursor) و یک آرایه |
| [TextDAPJsonTools.d:108](../../../JsonDAPtest/TextDAPJsonTools.d#L108) | خواندن یک مقدار در یک مسیر |
| [TextDAPJsonEdit.d:113](../../../JsonDAPtest/TextDAPJsonEdit.d#L113) | از روی شکل مسیر انتخاب می‌کند که کدام متد ویرایش درست است |

بعدی: [۰۲ — انواع و رفت‌وبرگشت](02-types-and-the-round-trip.md)
