# JsonDAP

**کتابخانه‌ی JSON برای زبان D — سریالایز/دیسریالایز، کار با فایل، ویرایش مسیری و یک درخت استثنای یکپارچه.**
ساخته‌ی [Aripa Pars Studio](https://github.com/AripaStudio) · مجوز MIT · آخرین نسخه **2.3.0** است.

**[English](README.md) · فارسی**

[![license](https://img.shields.io/badge/license-MIT-green)](LICENSE)

---

## فهرست

- [چرا JsonDAP](#چرا-jsondap)
- [نصب](#نصب)
- [شروع سریع](#شروع-سریع)
- [قرارداد JSON](#قرارداد-json)
- [مرجع API](#مرجع-api)
- [استثناها](#استثناها)

---

## چرا JsonDAP

`std.json` درخت تجزیه می‌دهد و `toJSON`/`fromJSON` نگاشت خودکار، ولی هیچ‌کدام کنترل دقیق
روی شکل داده‌ی روی سیم (wire format) نمی‌دهند. JsonDAP دقیقاً همین فاصله را پر می‌کند:

- **رفت‌وبرگشت با نوع‌های خودتان** — `struct`، `class`، `enum`، آرایه و فیلد `Nullable`
  در هر دو جهت تبدیل می‌شوند، با یک نگاشت صریح و مستند.
- **کنترل نام فیلد روی سیم** — `@JsonName("msg_id")` و `@JsonIgnore` در هر دو جهت
  (نوشتن و خواندن) رعایت می‌شوند.
- **دو سطح سخت‌گیری** — حالت strict (همه‌ی فیلدها اجباری، پیش‌فرض) یا حالت lenient
  (`APdeserializeJsonLenient`، فیلد غایب مقدار پیش‌فرض خودش را نگه می‌دارد).
- **ویرایش فایل JSON با مسیر** — مثل `"MainData.items[2].name"` — بدون این‌که کل سند را
  به کد خودتان بیاورید.
- **یک درخت استثنا** — هر خطا زیرشاخه‌ی `BaseExceptionAP` است و فایل، خط و مسیر JSON
  خراب‌شده را با خود دارد؛ پس گزارش خطا شاهد دارد، نه حدس.
- **بدون تعمیر خاموش** — عضو نامعتبر `enum`، فیلد غایب یا فایل خراب گزارش می‌شود؛
  هرگز بی‌صدا cast یا حذف نمی‌شود.

### پیش‌نیازها

| مورد | نسخه |
|---|---|
| کامپایلر D | DMD 2.100 به بالا (تست‌شده با DMD 2.113.0، x86_64) |
| ابزار بیلد | dub 1.30 به بالا (تست‌شده با dub 1.42.0) |
| پلتفرم | ویندوز (بیلد DLL از لینکر MSVC استفاده می‌کند)؛ سورس‌های D قابل حمل‌اند |

## نصب

**به‌عنوان وابستگی dub**

```json
{
  "dependencies": {
    "jsondap": "~>2.3.0"
  }
}
```

**با کپی سورس (مصرف‌کننده‌ی D)**

فایل‌های `.d` پوشه‌ی `JsonDAP/` را در پروژه‌ی خود کپی کنید (فقط فایل‌ها، نه `bin/`) و
بگذارید بیلد خودتان آن‌ها را کامپایل کند — instantiate همین‌جاست:

```json
{
  "sourcePaths": [ "vendor/JsonDAP" ]
}
```

مصرف‌کننده‌ی D دیگر به `JsonDAP.dll` لینک نمی‌شود. DLL برای کسانی است که D کامپایل
نمی‌کنند؛ یک برنامه‌ی D که فقط با import library لینک شود، فراخوانی‌های template را پیدا
نمی‌کند، چون بدنه‌ی آن‌ها در سورس است نه در DLL.

> **سورس و DLL باید از یک بیلد باشند.** در `JsonDAP.dll` فقط نمادهای غیر-template قرار
> می‌گیرند؛ ترکیب «DLL قدیمی + سورس جدید» (یا برعکس) پشتیبانی نمی‌شود.

**باینری آماده** — `JsonDAP.dll` ویندوز به‌همراه کتابخانه‌ی import و سورس‌های هم‌نسخه در
بخش **Releases** مخزن منتشر می‌شود و هر نسخه زیر `JsonDAP/bin/versionX.Y.Z/` هم نگه‌داری
می‌گردد. آرشیوی را بردارید که با نسخه‌ی `dub.json` شما یکی است و `JsonDAP.dll` را کنار
فایل اجرایی بگذارید.

## شروع سریع

```d
import std.json : JSONValue;   // JsonDAP does not re-export JSONValue
import std.stdio;
import JsonDAP;

struct User
{
    string name;
    int age;
}

void main()
{
    User user = User("Aripa", 2026);

    // struct -> JSONValue
    JSONValue json = JsonAP.APserializeToJson!User(user);
    writeln(json.toString());          // {"age":2026,"name":"Aripa"}

    // JSON text -> struct
    auto loaded = JsonAP.APdeserializeJson!User(`{"name":"Aripa","age":2026}`);
    if (!loaded.isNull)
    {
        writeln(loaded.get.name);      // Aripa
    }

    // file round trip
    JsonAP.APwriteJsonFile!User("user.json", user);
    auto fromFile = JsonAP.APreadJsonFile!User("user.json");
}
```

همه‌ی متدها `static` روی کلاس `JsonAP` هستند و پیشوند `AP` دارند. هر متدی که ممکن است
مقدار نداشته باشد `Nullable!T` برمی‌گرداند — پیش از `.get` همیشه `.isNull` را بررسی کنید؛
متدهای `bool` در خطای قابل‌بازیابی (فایل نبود، نوع گره غلط) `false` می‌دهند.

> `JSONValue` و `JSONType` از `std.json` می‌آیند و `import JsonDAP;` آن‌ها را re-export نمی‌کند.
> `JSONValue` یک associative array است، پس **ترتیب کلیدها در متن تولیدشده ثابت نیست**
> (نمونه‌ی بالا `age` را قبل از `name` چاپ می‌کند)؛ همیشه مقدار تجزیه‌شده را مقایسه کنید، نه متن خام را.

## قرارداد JSON

| نوع D | روی سیم |
|---|---|
| `struct` / `class` | object |
| آرایه / `T[]` | array |
| `enum` | عدد صحیح — و فقط **عضو معتبر**، وگرنه خطا |
| `Nullable!T` (با نام مستعار `Optional!T`) | خالی ⇒ `null`، وگرنه مقدار درون آن |
| ارجاع `class` برابر `null` | `null` (در هر دو جهت پذیرفته می‌شود) |
| `std.sumtype.SumType` | `{"tag":"<نام عضو>","value":<payload>}` |

**نام فیلدها**

- `@JsonName("msg_id") string messageId;` — نام روی سیم `msg_id` می‌شود.
- `@JsonIgnore int scratch;` — این فیلد هرگز روی سیم نمی‌آید.
- بدون UDA — نام فیلد D عیناً استفاده می‌شود.

**حالت strict و lenient**

| وضعیت | strict (پیش‌فرض) | `lenient = true` / `APdeserializeJsonLenient` |
|---|---|---|
| فیلد در JSON نیست | `JSONConvertExceptionAP` (کد `MissingField`) | فیلد مقدار پیش‌فرض خودش را نگه می‌دارد |
| فیلد `Nullable` / `class` در JSON نیست | `JSONConvertExceptionAP` | خالی / `null` می‌ماند |
| مقدار نامعتبر `enum` | خطا | خطا (هرگز cast نمی‌شود) |
| تگ ناشناخته‌ی SumType | خطا همراه با فهرست تگ‌های موجود | خطا همراه با فهرست تگ‌های موجود |

## مرجع API

همه‌ی متدها اعضای `static` کلاس `JsonAP` (ماژول `JsonDAP`) هستند و بر پایه‌ی این‌که به چه
چیزی کار دارند دسته‌بندی شده‌اند. تریت‌های نوعِ زمان‌کامپایل لایه‌ی تبدیل هم عمومی‌اند —
هر کدام یک `struct` با `enum bool value`:
`IsIntAP` · `IsFloatAP` · `IsNumberAP` · `IsBoolAP` · `IsStringAP` · `IsArrayAP` ·
`IsClassAP` · `IsEnumAP` · `IsStructAP`

**فایل**

| متد | خروجی | کار |
|---|---|---|
| `APreadJsonFile!T(string filePath)` | `Optional!T` | خواندن و دیسریالایز فایل |
| `APwriteJsonFile!T(string filePath, T data)` | `bool` | نوشتن `T` در فایل |
| `APgetJsonFileSize(string filePath)` | `Optional!long` | حجم فایل به بایت |
| `APreadJsonArray!T(string filePath)` | `Optional!(T[])` | خواندن فایل آرایه به `T[]` |
| `APexistsFile(string filePath)` | `bool` | وجود فایل |
| `APexists(string filePath)` | `bool` | همان بررسی، برای کد قدیمی |

**خواندن و نوشتن مقدار**

| متد | خروجی | کار |
|---|---|---|
| `APserializeToJson!T(T obj)` | `JSONValue` | تبدیل `T` به مقدار JSON |
| `APserializeToJsonArray!T(T data)` | `JSONValue[]` | تبدیل آرایه/range به آرایه‌ی JSON |
| `APserializeTToJsonValue!T(T obj)` | `JSONValue` | تبدیل سطح‌پایین `T` به JSON |
| `APdeserializeJson!T(string jsonContent)` | `Optional!T` | متن JSON به `T` (strict) |
| `APdeserializeJsonLenient!T(string jsonContent)` | `Optional!T` | متن JSON به `T` (فیلد غایب مجاز) |
| `APdeserializeJsonArray!T(string jsonContent)` | `Optional!(T[])` | متن آرایه به `T[]` |
| `APconvertJsonValueToT!T(JSONValue jsonValue, bool lenient = false)` | `Optional!T` | مقدار JSON به `T` |
| `APgetJsonValue!V(string jsonContent, string path)` | `Optional!V` | خواندن مقدار در `path` |
| `APgetJsonValueType(JSONValue jsonValue)` | `JSONType` | نوع گره در `std.json` |
| `APprettyPrintJson(string jsonContent)` | `Optional!string` | JSON خوانا و تودرتو |

**اعتبارسنجی و بررسی**

| متد | خروجی | کار |
|---|---|---|
| `APisValidJson(string jsonContent)` | `bool` | متن، JSON معتبر است |
| `APisJsonObject(string jsonContent)` | `bool` | گره‌ی سطح‌اول object است |
| `APisJsonArray(string jsonContent)` | `bool` | گره‌ی سطح‌اول array است |
| `APisJsonNumber(string jsonContent)` | `bool` | گره‌ی سطح‌اول عدد است |
| `APisJsonString(string jsonContent)` | `bool` | گره‌ی سطح‌اول رشته است |
| `APgetJsonItemCount(string jsonContent)` | `Optional!long` | شمار آیتم‌های سطح‌اول |
| `APisDigitAP(dchar c)` | `bool` | رقم ASCII، **یا** فارسی، **یا** عربی-هندی |
| `APnormalizeDigitsAP(string s)` | `string` | ارقام فارسی و عربی-هندی را به ASCII بازنویسی می‌کند؛ هیچ کاراکتر دیگری تغییر نمی‌کند |
| `APisInteger(string s)` | `bool` | کل رشته عدد است |
| `APJsonPathParser(string input)` | `PathStep[]` | شکستن `"a.b[2]"` به گام‌های مسیر |
| `APStrIsNUll(string input, string paramName, out bool, out string)` | `void` | گارد null/خالی/سفید + دلیل |
| `APCheckStringIsNullArray(string[] inputs)` | `bool` | گارد برای فهرست رشته‌ها |
| `APrecursiveMerge(ref JSONValue target, ref JSONValue source, bool overwrite, bool mergeArrays, out string message)` | `bool` | ادغام عمیق، با پیام خطا |

**ویرایش فایل با مسیر**

هر فراخوانی فایل را می‌خواند، یک گره را تغییر می‌دهد، فایل را برمی‌گرداند و اگر مسیر یا
فایل قابل استفاده نبود `false` می‌دهد (به‌جای پرتاب استثنا).

| متد | کار |
|---|---|
| `APupdateJsonValueOBJECT!V(string filePath, string jsonPath, V value)` | جایگزینی مقدار `path` در object |
| `APupdateJsonValueARRAY!V(string filePath, string jsonPath, V value)` | جایگزینی مقدار `path` در array |
| `APaddJsonItemOBJECT!T(string filePath, string jsonPath, T item)` | افزودن کلید تازه (اگر وجود داشته باشد شکست می‌خورد) |
| `APaddJsonItemARRAY!T(string filePath, string jsonPath, T item)` | افزودن به آرایه‌ی `path` |
| `APremoveJsonItemOBJECT(string filePath, string jsonPath)` | حذف یک کلید |
| `APremoveJsonItemARRAY(string filePath, string jsonPath)` | حذف یک عضو آرایه |
| `APmergeJson(string filePath, JSONValue jsonContentToMerge, bool overwriteExisting = true, bool mergeArrays = false)` | ادغام سند دیگر در فایل |

**دو شکل مسیر، عمداً.** API ویرایش فایل و `APJsonPathParser` شکل `[ ]` را می‌پذیرند:
`MainData.items[2].name`. اما `APgetJsonValue` مسیر را فقط با `.` می‌شکافد، پس عضو آرایه یک
بخش مستقل است: `items.1` عنصر دوم را می‌خواند و `items[1]` کلید یافت‌نشده گزارش می‌شود.
`APJsonPathParser` ارقام ASCII، فارسی و عربی-هندی را داخل براکت می‌پذیرد و پیش از تبدیل به عدد
آنها را یکسان‌سازی می‌کند. کلید میانیِ غایب در object ساخته می‌شود؛ ایندکس میانیِ غایب در array
ساخته **نمی‌شود**. `APremoveJsonItemOBJECT` کلید سطح‌اول را هم حذف می‌کند.

**آرایه: add و update متقارن نیستند.** `APaddJsonItemARRAY` مقدار `index == length` را می‌پذیرد و
در همان‌جا الحاق می‌کند؛ `APupdateJsonValueARRAY` همان ایندکس را رد می‌کند، چون به‌روزرسانی عضوی که
وجود ندارد جایگزینی نیست. ایندکس خارج از دامنه پیام
`array index N is out of range (length M)` می‌دهد.

هر متد بالا یک دوقلوی `WithMessage` دارد که می‌گوید **چرا** `false` برگشت:

```d
string reason;
if (!JsonAP.APupdateJsonValueOBJECTWithMessage!int(file, "settings.retry", 3, reason))
{
    writeln("edit rejected: ", reason);
    // edit rejected: the path 'settings.retry' does not exist: key 'retry' is missing.
}
```

| متد | چه چیزی اضافه می‌کند |
|---|---|
| `APupdateJsonValueOBJECTWithMessage!V(filePath, jsonPath, value, out string message)` | دلیل رد شدن به‌روزرسانی مقدار در object |
| `APupdateJsonValueARRAYWithMessage!V(filePath, jsonPath, value, out string message)` | دلیل رد شدن به‌روزرسانی مقدار در array |
| `APaddJsonItemOBJECTWithMessage!T(filePath, jsonPath, item, out string message)` | دلیل افزوده نشدن کلید |
| `APaddJsonItemARRAYWithMessage!T(filePath, jsonPath, item, out string message)` | دلیل افزوده نشدن عضو |
| `APremoveJsonItemOBJECTWithMessage(filePath, jsonPath, out string message)` | دلیل حذف نشدن کلید |
| `APremoveJsonItemARRAYWithMessage(filePath, jsonPath, out string message)` | دلیل حذف نشدن عضو آرایه |
| `APmergeJsonWithMessage(filePath, jsonContentToMerge, overwriteExisting, mergeArrays, out string message)` | دلیل انجام نشدن ادغام |
| `APmergeJsonWithMessage(filePath, jsonContentToMerge, overwriteExisting = true, mergeArrays = false)` | همان ادغام با **یک** خروجی از نوع `string` به‌جای `bool` + `out` |

**پاسخ تک‌رشته‌ای ادغام.** شکل کوتاه دلیل شکست را برمی‌گرداند و **رشته‌ی خالی یعنی ادغام موفق بود** —
`""` همان `true` است و هر متن دیگر `false`:

```d
string reason = JsonAP.APmergeJsonWithMessage(file, incoming);
if (reason.length != 0)
{
    writeln("merge rejected: ", reason);
}
```

این شکل به‌خاطر آن است که یک متد `static` بدون `out` نمی‌تواند دو مقدار بدهد؛ شکل `bool` + `out string`
بالا هم سر جای خودش است و وقتی پرچم (`bool`) را می‌خواهید همان را به‌کار ببرید.

`message` در ابتدای هر فراخوانی خالی می‌شود و در موفقیت خالی می‌ماند، پس می‌توانید یک
متغیر را دوباره به‌کار ببرید. این دوقلوها هرگز استثنا نمی‌دهند: فایل غایب، سند خراب یا
مسیر بی‌استفاده همه به‌شکل `false` + پیام برمی‌گردند.

**SumType**

`std.sumtype` بازتاب (reflection) ندارد؛ برای همین پشتیبانی SumType یک API صریح است:

| متد | خروجی | کار |
|---|---|---|
| `APserializeSumType!T(T value, string delegate(string) tagOf = null)` | `JSONValue` | نوشتن پاکت `{"tag","value"}` |
| `APdeserializeSumType!T(JSONValue jsonValue, bool lenient = false, string delegate(string) tagOf = null)` | `Optional!T` | بازسازی عضوی که تگ نامش را می‌برد |
| `APdeserializeSumTypeFromString!T(string jsonContent, bool lenient = false, string delegate(string) tagOf = null)` | `Optional!T` | همان، از متن JSON |
| `APserializeSumTypeWithHandlers!T(T value, string delegate(T) tagOf, JSONValue delegate(T) payloadOf)` | `JSONValue` | تگ و payload را خود فراخوان تعیین می‌کند |
| `APdeserializeSumTypeWithHandlers!T(JSONValue jsonValue, T delegate(string tag, JSONValue payload) resolver)` | `Optional!T` | تگ و payload را خود فراخوان تفسیر می‌کند |

```d
alias Payload = SumType!(int, string);

JSONValue wire = JsonAP.APserializeSumType!Payload(Payload(42));
// {"tag":"int","value":42}

auto back = JsonAP.APdeserializeSumType!Payload(wire);
assert(back.get == Payload(42));
```

تگ ناشناخته خطایی است که تگ‌های موجود را فهرست می‌کند — نه یک جایگزین خاموش.

## استثناها

همه از `BaseExceptionAP` ارث می‌برند که `correlationId`، فایل مبدأ و شماره‌ی خط وقوع خطا
را با خود دارد.

```
BaseExceptionAP
├── ParameterRelatedExceptionAP
│   ├── ConvertExceptionAP
│   │   └── JSONConvertExceptionAP   (jsonPath + jsonSnippet + دلیل دقیق)
│   ├── InvalidArgumentExceptionAP
│   └── ArgumentNullExceptionAP
├── JSONExceptionAP
│   └── JsonOperationExceptionAP     (jsonPath + jsonSnippet)
├── FileOperationExceptionAP         (systemErrorCode)
├── SyntaxErrorExceptionAP
└── UnknownErrorexceptionAP
```

```d
try
{
    auto user = JsonAP.APdeserializeJson!User(jsonText).get;
}
catch (JSONConvertExceptionAP e)
{
    // e.jsonPath نام فیلد و e.jsonSnippet ورودی خراب را نشان می‌دهد
    writeln(e.toString());
}
```

مسیری با ایندکس بی‌استفاده (`items[]`، `items[x]`) یک `ConvertExceptionAP` می‌دهد و مسیری با
براکتِ بسته‌نشده یک `UnknownErrorexceptionAP` — هر دو داخل همین درخت، پس مصرف‌کننده‌ای که
`BaseExceptionAP` را می‌گیرد با یک `std.conv.ConvException` خام نمی‌میرد.
