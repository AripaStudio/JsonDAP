# JsonDAP

**کتابخانه‌ی JSON برای زبان D — سریالایز/دیسریالایز، کار با فایل، ویرایش مسیری و یک درخت استثنای یکپارچه.**
ساخته‌ی [Aripa Pars Studio](https://github.com/AripaStudio) · مجوز MIT · آخرین نسخه **2.4.1** است.

**[English](README.md) · فارسی**

[![license](https://img.shields.io/badge/license-MIT-green)](LICENSE)

> این فایل **مرجع** است. آموزش گام‌به‌گام — یازده فصل، با مثال‌هایی که همه کامپایل و اجرا شده‌اند —
> در [`Docs/`](Docs/StartPe.md) است.

---

## فهرست

- [چرا JsonDAP](#چرا-jsondap)
- [نصب](#نصب)
- [شروع سریع](#شروع-سریع)
- [قرارداد JSON](#قرارداد-json)
- [مرجع API](#مرجع-api)
- [نحو مسیر](#نحو-مسیر)
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
| پلتفرم | هر پلتفرمی که DMD روی آن اجرا می‌شود — ویندوز، لینوکس، macOS |

## نصب

JsonDAP یک **بسته‌ی سورس dub** است: `targetType` برابر `sourceLibrary` است، پس دیگر
`JsonDAP.dll`، کتابخانه‌ی import یا باینری جدا وجود ندارد که بخواهد هم‌نسخه با سورس بماند.
بیلد شما فایل‌های `.d` کتابخانه را کنار فایل‌های خودتان کامپایل می‌کند؛ تنها راهی که
متدهای template مثل `APdeserializeJson!T` و `APgetJsonValue!V` بتوانند instantiate شوند همین است.

**از یک checkout محلی**

```json
{
  "dependencies": {
    "jsondap": { "path": "../JsonDAP" }
  }
}
```

**از راهِ git repository**

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

`repository` آدرس کلون است و `version` دقیقاً نام همان Git tag است که dub روی آن checkout
می‌کند. تگ نسخه‌ی 2.4.1 در این پروژه `v2.4.1` است، پس پیشوند `v` را در این فیلد نگه دارید.
dub آن تگ را کلون می‌کند و سورسش را داخل بیلد شما کامپایل می‌کند، پس نسخه‌ای که قفل
کرده‌اید همان سورسی است که در گیت‌هاب می‌خوانید.

JsonDAP در registry دوب منتشر نشده است، بنابراین `"jsondap": "~>2.4.1"` به چیزی resolve
نمی‌شود. برای چک‌اوتی که کنار پروژه‌تان نگه می‌دارید از حالت `path` و برای همه‌ی حالت‌های
دیگر از حالت git استفاده کنید.

بعد `import JsonDAP;` و استفاده از `JsonAP.AP…`. چیز دیگری نصب نمی‌شود: سورس کتابخانه با
وابستگی می‌آید و در هر پلتفرمی داخل فایل اجرایی شما کامپایل می‌شود.

> چون سورس داخل خود مصرف‌کننده کامپایل می‌شود، امکان «نسخه‌ی ناهم‌خوان» وجود ندارد؛ و یک
> `JsonDAP.dll` یا `.lib` یا `.exp` قدیمی که از نسخه‌های قبل جا مانده هیچ کاری انجام نمی‌دهد.
> اگر از 2.3.0 یا قبل‌تر ارتقا می‌دهید، آن‌ها را حذف کنید.

**مصرف‌کننده‌های غیر D** (مثل C#، C یا FFI‌های دیگر) هرگز هدف این کتابخانه نبودند و نسخه‌ی
2.4.0 هم DLL برایشان منتشر نمی‌کند. اگر به DLL نیاز دارید، خودتان سورس را به یک shared
library تبدیل کنید — سورس‌های D قابل حمل‌اند و هیچ کد ویندوز-محوری در آن‌ها نیست.

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
| `APserializeToJsonArray!T(T data)` | `JSONValue[]` | **یک** مقدار → آرایه‌ی تک‌عضویی، آماده‌ی `~=` کردن در batch؛ یک `JSONValue[]` بدون تغییر برمی‌گردد |
| `APserializeTToJsonValue!T(T obj)` | `JSONValue` | تبدیل سطح‌پایین `T` به JSON |
| `APdeserializeJson!T(string jsonContent)` | `Optional!T` | متن JSON به `T` (strict) |
| `APdeserializeJsonLenient!T(string jsonContent)` | `Optional!T` | متن JSON به `T` (فیلد غایب مجاز) |
| `APdeserializeJsonArray!T(string jsonContent)` | `Optional!(T[])` | متن آرایه به `T[]` |
| `APconvertJsonValueToT!T(JSONValue jsonValue, bool lenient = false)` | `Optional!T` | مقدار JSON به `T` |
| `APgetJsonValue!V(string jsonContent, string path)` | `Optional!V` | خواندن مقدار در `path` با همان تجزیه‌کننده‌ی مشترک [نحو مسیر](#نحو-مسیر)؛ نوع گره باید با `V` بخواند. کلید نبودن، ایندکس خارج از دامنه یا نوع ناسازگار **پرتاب** می‌کند — `Optional` خالی فقط یعنی متن یا مسیر خالی بوده |
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
| `APisDigitAP(dchar c)` | `bool` | یک کاراکتر که رقم ASCII، **یا** فارسی، **یا** عربی-هندی است |
| `APnormalizeDigitsAP(string s)` | `string` | ارقام را به ASCII بازنویسی می‌کند، به‌علاوه‌ی `٫`/`٬` → `.` و `−` → `-`؛ هیچ کاراکتر دیگری تغییر نمی‌کند |
| `APisInteger(string s)` | `bool` | **فقط رقم** — بدون علامت و بدون ممیز (`"7"` بله، `"+7"` و `"12.5"` نه) |
| `APisSignedInteger(string s)` | `bool` | یک `+`/`-` اختیاری و بعد فقط رقم (`"−7"` بله، `"7.5"` نه) |
| `APisDecimal(string s)` | `bool` | علامت اختیاری، رقم، یک `.` و رقم (`"12.5"` و `"۱۲٫۵"` بله؛ `"1e9"` و `"12."` نه) |
| `APJsonPathParser(string input)` | `PathStep[]` | تجزیه‌کننده‌ی مسیر JSON — بخش [نحو مسیر](#نحو-مسیر) را ببینید |
| `APstrIsNil(string input, string paramName, out bool, out string reason)` | `void` | گارد null/خالی/سفید + دلیل |
| `APCheckStringIsNullArray(string[] inputs)` | `bool` | گارد برای فهرست رشته‌ها |
| `APrecursiveMerge(ref JSONValue target, JSONValue source, bool overwrite, bool mergeArrays, out string message)` | `bool` | ادغام عمیق در `target`؛ از `source` اول نسخه‌ی مستقل گرفته می‌شود، پس مقداری که می‌دهید هرگز تغییر نمی‌کند |
| `APrecursiveMergeCopy(JSONValue target, JSONValue source, bool overwrite, bool mergeArrays, out JSONValue result, out string message)` | `bool` | همان ادغام روی یک **کپی**: `target` دست‌نخورده می‌ماند و نتیجه در `result` می‌آید |
| `APdeepCopy(JSONValue v)` | `JSONValue` | نسخه‌ی کاملاً مستقل از درخت JSON — هیچ آرایه، آبجکت یا گره تودرتو مشترک نیست |

`APStrIsNUll` و `StrIsNUll` هنوز هستند و `deprecated` خورده‌اند؛ کار را به `APstrIsNil` و
`strIsNil` می‌سپارند. نام قدیمی هم_case_ی `Null` را قاطی کرده بود و پارام پیامش را `ErrorText`
می‌نامید؛ در نسخه‌ی 2.5.0 حذف می‌شوند.

**ویرایش فایل با مسیر**

هر فراخوانی فایل را می‌خواند، یک گره را تغییر می‌دهد، فایل را برمی‌گرداند و اگر مسیر یا
فایل قابل استفاده نبود `false` می‌دهد (به‌جای پرتاب استثنا).

| متد | کار |
|---|---|
| `APupdateJsonValueOBJECT!V(string filePath, string jsonPath, V value)` | جایگزینی مقدار `path` در object |
| `APupdateJsonValueARRAY!V(string filePath, string jsonPath, V value)` | جایگزینی مقدار `path` در array |
| `APaddJsonItemOBJECT!T(string filePath, string jsonPath, T item)` | افزودن کلید تازه (اگر وجود داشته باشد شکست می‌خورد) |
| `APaddJsonItemARRAY!T(string filePath, string jsonPath, T item)` | درج عضو در جایگاه مشخص‌شده‌ی آرایه |
| `APremoveJsonItemOBJECT(string filePath, string jsonPath)` | حذف یک کلید |
| `APremoveJsonItemARRAY(string filePath, string jsonPath)` | حذف یک عضو آرایه |
| `APmergeJson(string filePath, JSONValue jsonContentToMerge, bool overwriteExisting = true, bool mergeArrays = false)` | ادغام سند دیگر در فایل |

### نحو مسیر

**یک شکل مسیر، همه‌جا.** از نسخه‌ی 2.4.0 متدهای `APgetJsonValue`، `APJsonPathParser` و کل API
ویرایش فایل از **یک** تجزیه‌کننده استفاده می‌کنند، پس یک رشته در همه‌شان یک معنی دارد:

```
MainData.items[2].name
```

| شکل | معنی |
|---|---|
| `a.b` | کلید `b` داخل آبجکت `a` |
| `items[2]` | عنصر سوم آرایه‌ی `items` |
| `rows[0][1]` | ایندکس زنجیره‌ای — عنصر دومِ `rows[0]` |
| `weird\.key.next` | `\` کاراکتر بعد را escape می‌کند، پس یک کلید می‌تواند `.`, `[` یا `]` داشته باشد |
| `rows[۲]` | ارقام فارسی و عربی-هندی پیش از تبدیل به عدد یکسان‌سازی می‌شوند |

> **شکستن سازگاری در 2.4.0 — `items.1` دیگر ایندکس آرایه نیست.** تا 2.3.0 متد
> `APgetJsonValue` مسیر را فقط با `.` می‌شکافد، پس یک بخش عددیِ تنها به‌عنوان ایندکس آرایه
> کار می‌کرد. حالا که همه‌ی متدها یک تجزیه‌کننده دارند، یک بخش تنها همیشه کلید است و تنها
> `[n]` ایندکس محسوب می‌شود؛ `items.1` روی آرایه اکنون `JSON path invalid: key '1' not found.`
> پرتاب می‌کند. بنویسید `items[1]`. چیز دیگری در دستور مسیر تغییر نکرده است.

مسیر کاراکتر‌به‌کاراکتر خوانده می‌شود، پس مسیر خراب به‌جای تولید یک گام غلط، **رد** می‌شود.
همه‌ی این‌ها `InvalidArgumentExceptionAP` (زیرشاخه‌ی `BaseExceptionAP`) می‌دهند:

| مسیر | دلیل رد شدن |
|---|---|
| `""` و `"   "` | `JSON path is empty.` |
| `a..b` | `JSON path contains an empty key.` |
| `items[3` | `JSON path has a missing closing bracket.` |
| `items]` | `JSON path has a ']' without '['.` |
| `items[0]x` | `Unexpected character after ']'.` |
| `items[abc]` | `array index must be a non-negative integer.` |
| `items[-1]` | `array index must be a non-negative integer.` — ایندکس منفی مثل پایتون نیست |

کلید میانیِ غایب در object در API ویرایش فایل **ساخته می‌شود**؛ ایندکس میانیِ غایب در array
ساخته **نمی‌شود**. `APremoveJsonItemOBJECT` کلید سطح‌اول را هم حذف می‌کند.

**آرایه: add درج می‌کند، update جایگزین می‌کند.** `APaddJsonItemARRAY` عضو را **در همان
ایندکس** قرار می‌دهد، پس `index == length` همان جایگاه الحاق است و بزرگ‌تر از آن رد می‌شود با
پیام `array index N is out of range (length M); nothing was changed.`. متد
`APupdateJsonValueARRAY` همان ایندکس را رد می‌کند، چون به‌روزرسانی عضوی که وجود ندارد
جایگزینی نیست.

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
└── UnknownErrorExceptionAP
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

هر ردِّ مسیر یک `InvalidArgumentExceptionAP` است — مسیر خالی، کلید خالی، براکتِ بسته‌نشده،
`]` بدون `[`، کاراکتر بعد از `]`، یا ایندکسی که عددِ نامنفی نباشد (`items[]`، `items[x]`). تنها
استثنا ایندکسی است که در `int` جا نمی‌شود و آن `ConvertExceptionAP` می‌گیرد. هر دو داخل همین
درخت‌اند، پس مصرف‌کننده‌ای که `BaseExceptionAP` را می‌گیرد با یک `std.conv.ConvException`
خام نمی‌میرد.

نام `UnknownErrorexceptionAP` حرف `e` کوچک داشت در حالی که خواهرش `SyntaxErrorExceptionAP`
حرف `E` بزرگ دارد. در 2.4.0 به `UnknownErrorExceptionAP` تغییر نام پیدا کرد و املای قدیمی به‌صورت
یک `deprecated` alias باقی ماند؛ پس کد موجود همچنان کامپایل می‌شود و پیام جابه‌جایی را می‌گیرد.
