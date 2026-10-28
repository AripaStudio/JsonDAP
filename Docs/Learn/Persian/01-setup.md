# ۰۱ — نصب و راه‌اندازی

فهرست: [StartPe.md](../../StartPe.md)

## افزودن وابستگی

JsonDAP یک **بستهٔ منبعی** (source package) برای dub است: نه DLLای وجود دارد، نه کتابخانهٔ
import — dub فایل‌های `.d` را مستقیم داخل build شما کامپایل می‌کند.

یک checkout که کنار پروژهٔ شما نشسته است:

```json
{
  "dependencies": {
    "jsondap": { "path": "../../JsonDAP" }
  }
}
```

هر پروژهٔ دیگری، قفل‌شده روی یک tag:

```json
{
  "dependencies": {
    "jsondap": {
      "repository": "git+https://github.com/AripaStudio/JsonDAP.git",
      "version": "v2.4.1"
    }
  }
}
```

JsonDAP روی registry رسمی dub نیست، پس `~>2.4.1` به هیچ‌چیز resolve نمی‌شود. نام Git tag برابر
`v2.4.1` است؛ پیشوند `v` را نگه دارید.

## نخستین برنامه

همه‌چیز از کلاس `JsonAP` می‌گذرد. این مدل خودِ TextDAP است که کوچکش کرده‌ام:

```d
import std.json;
import std.typecons;      // Nullable که کتابخانه با نام Optional صدا می‌زندش
import JsonDAP;

struct Session
{
    @JsonName("current_file") string currentFile;   // کلید سیم با نام فیلد فرق دارد
    @JsonName("tab_width") int tabWidth;
    @JsonIgnore string lookupKey;                   // فقط در حافظه، هرگز نوشته نمی‌شود
}

void main()
{
    auto session = JsonAP.APdeserializeJsonLenient!Session(
            `{"current_file":"notes.txt"}`);

    if (!session.isNull)
    {
        session.get.currentFile;   // "notes.txt"
        session.get.tabWidth;      // 0 — در حالت مداراگر، فیلد غایب مقدار پیش‌فرضش را نگه می‌دارد
    }
}
```

| خط | چه کاری انجام می‌دهد |
|---|---|
| `import std.typecons;` | خواننده‌ها `Nullable!T` برمی‌گردانند که با نام `Optional!T` صدا زده می‌شود |
| `import JsonDAP;` | یک ماژول، `JsonAP` و استثناها و traitها را در دسترس می‌گذارد |
| `JsonAP.AP…` | هر متد `export static` روی `JsonAP` است — تابع آزادی نیست |
| `@JsonName("…")` | کلید روی سیم را عوض می‌کند؛ بدون صفت، همان نام فیلد D استفاده می‌شود |
| `@JsonIgnore` | فیلد در حافظه می‌ماند و هرگز به فایل نمی‌رسد |
| `APdeserializeJsonLenient!Session` | فیلد غایب به‌جای پرتاب استثنا، مقدار پیش‌فرضش را نگه می‌دارد |

## بیلد، تست و برنامهٔ مرجع

```bash
cd JsonDAPtest
dub build --force   # Output/TextDAP.exe
dub test  --force   # تست‌های خودِ کتابخانه، در JsonDAPtest/test/
```

**TextDAP** (`JsonDAPtest/`) یک ویرایشگر متن کنسولی است که فایل وضعیتش یک سند JSON است —
بزرگ‌ترین تست واقعی این کتابخانه. هر فصل زیر به فایل و خطی اشاره می‌کند که همان کار را انجام
می‌دهد:

| فایل | چرا خواندنش ارزش دارد |
|---|---|
| [TextDAPModel.d:27](../../../JsonDAPtest/TextDAPModel.d#L27) | structها، enum، `@JsonName` و `@JsonIgnore` |
| [TextDAPSession.d:18](../../../JsonDAPtest/TextDAPSession.d#L18) | بارگذاری: گارد، وجود فایل، اعتبارسنجی، خواندن مداراگر، پلهٔ catch |
| [TextDAPSession.d:83](../../../JsonDAPtest/TextDAPSession.d#L83) | ذخیره: serialize، merge، نوشتن، راستی‌آزمایی |
| [TextDAPConvert.d:18](../../../JsonDAPtest/TextDAPConvert.d#L18) | رفت‌وبرگشت یک رکورد، یک مکان‌نما و یک آرایه |
| [TextDAPJsonTools.d:108](../../../JsonDAPtest/TextDAPJsonTools.d#L108) | خواندن یک مقدار در یک مسیر |
| [TextDAPJsonEdit.d:113](../../../JsonDAPtest/TextDAPJsonEdit.d#L113) | انتخاب متد ویرایش درست از روی شکل مسیر |

بعدی: [۰۲ — انواع و رفت‌وبرگشت](02-types-and-the-round-trip.md)