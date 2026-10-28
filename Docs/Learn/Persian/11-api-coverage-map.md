# ۱۱ — API، یکی‌یکی با یک مثال

فهرست: [StartPe.md](../../StartPe.md) · قبلی: [۱۰](10-exceptions.md)

همه‌ی نام‌های `AP…` در یک جا، و هر کدام با برنامه‌ای که تنها اجرا می‌شود. این فصل درس نیست،
میزِ کار است: بعد از فصل‌های قبل بخوانیدش، یا مستقیم سراغ بخشی بروید که می‌خواهید و بلوکش را
بردارید.

**راه‌اندازی، یک خط است.** هر بلوک با importهایی شروع می‌شود که خودش لازم دارد — `import JsonDAP`
به‌همراه Phobos تمامِ آن است — و [۰۱](01-setup.md) همان سطر `dub.json` را نشان می‌دهد. بلوک را در
`app.d` بگذارید، `dub run` بزنید، و خروجی را با کادرِ زیرش مقایسه کنید. هیچ فایلی از `JsonDAPtest/`
در این فصل لازم نیست: پوشه‌ی `Docs/` در بسته‌ی منتشرشده بدون آن پروژه سفر می‌کند.

**دو عادت که ارزش نگه‌داشتن دارند.** متدی که `bool` می‌دهد، شکست را پنهان نمی‌کند — همزادِ
`…WithMessage` همان جمله را می‌دهد. و خواننده‌ای که `Optional!T` می‌دهد فقط می‌گوید «مقداری نیست»؛
سند خراب استثنا می‌دهد (فصل [۱۰](10-exceptions.md)).

## ۱ — رفت‌وبرگشتِ یک فایل

شش متد، یک فایل، بدون شگفتی. `APwriteJsonFile` پوشه‌های مسیر را خودش می‌سازد، پس اولین نوشتن در
`data/app/` حالت خاص نیست.

```d
import JsonDAP, std.file, std.stdio;

struct Point
{
    int x;
    int y;
}

void main()
{
    string file = "point.json";
    if (JsonAP.APexistsFile(file))
    {
        remove(file);
    }

    writeln(JsonAP.APexistsFile(file));
    writeln(JsonAP.APwriteJsonFile!Point(file, Point(3, 4)));
    writeln(readText(file));
    writeln(JsonAP.APexists(file));
    writeln(JsonAP.APgetJsonFileSize(file).get);

    Point back = JsonAP.APreadJsonFile!Point(file).get;
    writeln(back.x, " ", back.y);

    string list = "points.json";
    JsonAP.APwriteJsonFile!(Point[])(list, [Point(1, 2), Point(3, 4)]);
    writeln(readText(list));

    Point[] all = JsonAP.APreadJsonArray!Point(list).get;
    writeln(all.length);
}
```

چاپ می‌کند:

```text
false
true
{"x":3,"y":4}
true
13
3 4
[{"x":1,"y":2},{"x":3,"y":4}]
2
```

| متد | پاسخ | معنی |
|---|---|---|
| `APwriteJsonFile!T(file, value)` | `bool` | `T` را سریال می‌کند و می‌نویسد؛ پوشه‌ی نبود را می‌سازد |
| `APreadJsonFile!T(file)` | `Optional!T` | فایل باید یک **object** داشته باشد |
| `APreadJsonArray!T(file)` | `Optional!(T[])` | فایل باید یک **array** داشته باشد |
| `APgetJsonFileSize(file)` | `Optional!long` | اندازه به بایت |
| `APexistsFile(file)` | `bool` | فایلی هست |
| `APexists(path)` | `bool` | فایل **یا** پوشه هست |

`APreadJsonFile` و `APreadJsonArray` عمداً بر اساس شکل جدا شده‌اند: یک سند، یک رکورد است؛ فهرستِ
رکوردها، یک آرایه. خواستنِ شکل اشتباه خطاست، نه نتیجه‌ی خالی.

`.get` در این بلوک امن است، چون نوشتن همین حالا انجام شده. در کدِ واقعی `isNull` را بررسی کنید یا
بگذارید استثنا بالا بیاید — هرگز بعد از خواندنِ مسیری که کاربر تایپ کرده، کورکورانه `.get` نزنید.

## ۲ — انواع و رفت‌وبرگشت

`APserializeToJson` نوع شما را می‌پیماید و `JSONValue` می‌دهد؛ `APdeserializeJson` برمی‌گردد. هر دو
سمت از یک نامِ فیلد پیروی می‌کنند، و فیلدهای `@JsonIgnore` در خانه می‌مانند.

```d
import JsonDAP, std.json, std.stdio, std.typecons;

alias Optional = Nullable;

enum Priority
{
    low,
    high
}

struct Settings
{
    @JsonName("tab_width") int tabWidth;
    @JsonIgnore string cacheKey;
    Optional!bool autosave;
}

void main()
{
    Settings editor = Settings(4, "never-serialised", Optional!bool(true));

    JSONValue wire = JsonAP.APserializeToJson!Settings(editor);
    writeln(wire.toString());

    Settings back = JsonAP.APdeserializeJson!Settings(wire.toString()).get;
    writeln(back.tabWidth);

    auto lenient = JsonAP.APdeserializeJsonLenient!Settings(`{"autosave":false}`);
    writeln(lenient.get.tabWidth);

    JSONValue lowLevel = JsonAP.APserializeTToJsonValue!Settings(Settings(8, null, Optional!bool.init));
    writeln(lowLevel.toString());
    auto converted = JsonAP.APconvertJsonValueToT!Settings(lowLevel, false);
    writeln(converted.get.tabWidth);

    JSONValue[] oneItem = JsonAP.APserializeToJsonArray!Settings(editor);
    writeln(oneItem.length);
    auto many = JsonAP.APdeserializeJsonArray!Settings(`[{"tab_width":1},{"tab_width":2}]`);
    writeln(many.get.length);

    writeln(JsonAP.APgetJsonValueType(wire));

    static assert(IsIntAP!int.value && IsFloatAP!double.value && IsBoolAP!bool.value);
    static assert(IsStringAP!string.value && IsArrayAP!(int[]).value && IsClassAP!Object.value);
    static assert(IsEnumAP!Priority.value && IsStructAP!Settings.value);
    static assert(IsNumberAP!long.value && !IsNumberAP!string.value);
    writeln("the traits agree");
}
```

چاپ می‌کند:

```text
{"autosave":true,"tab_width":4}
4
0
{"autosave":null,"tab_width":8}
8
1
2
object
the traits agree
```

| متد | ورودی | خروجی |
|---|---|---|
| `APserializeToJson!T(value)` | هر `T` قابلِ سریال | `JSONValue` |
| `APserializeTToJsonValue!T(value)` | همان، یک پله پایین‌تر | `JSONValue` — بدونِ میان‌برِ `JSONValue` و بدونِ ترجمه‌ی خطا |
| `APdeserializeJson!T(text)` | **متنِ** JSON با object | `Optional!T`، strict |
| `APdeserializeJsonLenient!T(text)` | همان | `Optional!T`، فیلدِ غایب مقدار پیش‌فرض می‌گیرد |
| `APdeserializeJsonArray!T(text)` | متنِ JSON با array | `Optional!(T[])` |
| `APconvertJsonValueToT!T(node, lenient)` | گره‌ای که همین حالا دارید | `Optional!T` |
| `APserializeToJsonArray!T(value)` | یک مقدار | `JSONValue[]` با **یک** عضو |
| `APgetJsonValueType(node)` | یک گره | `JSONType` (`object`، `array`، `integer`، …) |

چهار چیز را این بلوک بدونِ یک کلمه کامنت ثابت می‌کند:

- روی سیم `tab_width`، در D `tabWidth` — `@JsonName` یک جهت را تغییر نام می‌دهد و برگشت را هم.
- `cacheKey` هرگز ظاهر نمی‌شود و `null` برمی‌گردد — `@JsonIgnore` پیشنهاد نیست.
- `Optional!bool` خالی به‌صورت `null` نوشته می‌شود و خالی برمی‌گردد.
- حالت strict سندی را که فیلد ندارد رد می‌کند؛ `Lenient` جایش `0` می‌گذارد.

نیمه‌ی دوم همان پیمایش است بدونِ راحتی‌ها: `serializeTToJsonValue` به‌همراه `convertJsonValueToT`
دقیقاً همان کاری را می‌کند که `serializeToJson` به‌همراه `deserializeJson`؛ برای همین نگه‌داشتنِ یک
`JSONValue` در میانه — برای بررسی، ادغام یا ذخیره — هیچ هزینه‌ای ندارد.

`APserializeToJsonArray` یک بسته‌بندِ تک‌عضوی است، برای تابعی که همیشه باید فهرست بدهد. نوشتنِ یک
آرایه‌ی واقعی در فایل هیچ کمکی نمی‌خواهد: `APwriteJsonFile!(Point[])(path, points)` در مثال ۱ همین
کار را کرد.

ساختارهای `Is…AP` پرسش‌های زمانِ کامپایل برای کدِ generic خودتان‌اند — `static if (IsStructAP!T.value)`
— و هر کدام یک `enum bool value` است، پس در زمانِ اجرا هزینه‌ای ندارد.

## ۳ — مسیرها و یک مقدار

`APJsonPathParser` نشان می‌دهد یک مسیر به چه تبدیل می‌شود؛ `APgetJsonValue` خودش می‌پیماید.

```d
import JsonDAP, std.json, std.stdio;

void main()
{
    string text = `{"a.b":1,"items":[{"y":1},{"y":2}],"settings":{"theme":"dark"}}`;

    foreach (step; JsonAP.APJsonPathParser(`items[۱].y`))
    {
        if (step.type == PathStepType.ObjectKey)
        {
            writeln("key   ", step.key);
        }
        else
        {
            writeln("index ", step.index);
        }
    }

    writeln(JsonAP.APgetJsonValue!string(text, "settings.theme").get);
    writeln(JsonAP.APgetJsonValue!int(text, "items[1].y").get);
    writeln(JsonAP.APgetJsonValue!int(text, `a\.b`).get);

    try
    {
        JsonAP.APgetJsonValue!int(text, "settings.missing");
    }
    catch (JSONExceptionAP caught)
    {
        writeln(caught.msg);
    }
}
```

چاپ می‌کند:

```text
key   items
index 1
key   y
dark
2
1
JSON path invalid: key 'missing' not found.
```

| متد | پاسخ |
|---|---|
| `APJsonPathParser(path)` | `PathStep[]` — هر گام یا `ObjectKey` است با `.key`، یا `ArrayIndex` با `.index` |
| `APgetJsonValue!V(text, path)` | `Optional!V` برای گره‌ای از آن نوع |

`V` می‌تواند `string`، `int`، `long`، `double`، `float` یا `bool` باشد؛ گرهِ صحیح به `double` هم
تبدیل می‌شود، ولی گرهِ `double` به `int` نه. دو واقعیت را همین خروجی نشان می‌دهد: `۱` فارسی داخل
براکت به `1` یکسان می‌شود، و `a\.b` به کلیدی می‌رسد که واقعاً نقطه دارد (نحوِ کامل در فصل
[۰۴](04-path-syntax.md)).

متنِ خالی یا مسیرِ خالی `Optional` **خالی** می‌دهد؛ مسیری که با سند نمی‌خواند **استثنا** می‌دهد. این دو
وضعیت متفاوت‌اند و کتابخانه جدایشان نگه می‌دارد.

## ۴ — ویرایش یک فایل با مسیر

شش متد یک گره را ویرایش می‌کنند، بدونِ بازنویسیِ سند. شکل‌های ساده `bool` می‌دهند؛ همزادهای
`…WithMessage` هم `bool` و هم دلیل.

```d
import JsonDAP, std.file, std.json, std.stdio, std.typecons;

struct Point
{
    int x;
    int y;
}

void main()
{
    string file = "doc.json";
    JsonAP.APwriteJsonFile!JSONValue(file, parseJSON(
            `{"text":"before","items":[{"x":0,"y":0},{"x":1,"y":1}],"limits":{"rows":10}}`));

    writeln(JsonAP.APupdateJsonValueOBJECT!string(file, "text", "after"));
    writeln(JsonAP.APaddJsonItemOBJECT!int(file, "limits.cols", 80));
    writeln(JsonAP.APupdateJsonValueARRAY!int(file, "items[1].y", 99));
    writeln(JsonAP.APaddJsonItemARRAY!Point(file, "items[2]", Point(7, 8)));
    writeln(JsonAP.APremoveJsonItemARRAY(file, "items[0]"));
    writeln(JsonAP.APremoveJsonItemOBJECT(file, "limits.cols"));
    writeln(readText(file));

    string message;
    writeln(JsonAP.APremoveJsonItemOBJECTWithMessage(file, "missing", message), ": ", message);
    writeln(JsonAP.APupdateJsonValueOBJECTWithMessage!int(file, "settings.retry", 3, message), ": ", message);
    writeln(JsonAP.APaddJsonItemOBJECTWithMessage!int(file, "text", 1, message), ": ", message);
    writeln(JsonAP.APupdateJsonValueARRAYWithMessage!int(file, "items[9].y", 5, message), ": ", message);
    writeln(JsonAP.APaddJsonItemARRAYWithMessage!int(file, "items[9]", 0, message), ": ", message);
    writeln(JsonAP.APremoveJsonItemARRAYWithMessage(file, "items[9]", message), ": ", message);
}
```

چاپ می‌کند:

```text
true
true
true
true
true
true
{"items":[{"x":1,"y":99},{"x":7,"y":8}],"limits":{"rows":10},"text":"after"}
false: the key 'missing' does not exist.
false: the path 'settings.retry' does not exist: key 'settings' is missing.
false: the key 'text' already exists; use APupdateJsonValueOBJECT.
false: array index 9 is out of range (length 2).
false: array index 9 is out of range (length 2); nothing was changed.
false: array index 9 is out of range (length 2).
```

| ساده | همزاد | قرارداد |
|---|---|---|
| `APupdateJsonValueOBJECT!V(file, path, value)` | `…WithMessage` | کلید باید وجود داشته باشد؛ `V` نوعِ مقدار است |
| `APaddJsonItemOBJECT!T(file, path, value)` | `…WithMessage` | کلید باید **نباشد** |
| `APremoveJsonItemOBJECT(file, path)` | `…WithMessage` | کلیدِ تودرتو یا سطحِ اول را برمی‌دارد |
| `APupdateJsonValueARRAY!V(file, path, value)` | `…WithMessage` | عضوِ آن اندیس را جایگزین می‌کند |
| `APaddJsonItemARRAY!T(file, path, value)` | `…WithMessage` | **در** آن اندیس می‌گذارد؛ `index == length` یعنی افزودن به آخر |
| `APremoveJsonItemARRAY(file, path)` | `…WithMessage` | عضوِ آن اندیس را برمی‌دارد |

کلیدِ **object**ی که در میانه نیست، در راه ساخته می‌شود؛ برای همین `limits.cols` روی سندی کار کرد که
فقط `limits` داشت. اندیسِ **array**ی که نیست ساخته نمی‌شود — چیزی نیست که ادامه داده شود.

همزادها `message` را پیش از هر کاری خالی می‌کنند، پس یک متغیر برای همه‌ی فراخوانی‌های پشتِ‌سرهم کافی
است. `APEditMessages` کلاسِ پایه‌ای است که همزادها را نگه می‌دارد؛ هرگز نامش را نمی‌نویسید، همزادها را
روی `JsonAP` صدا می‌زنید.

## ۵ — ادغام و کپی

دو پرسش: ادغام در **فایل**، یا ادغام دو درخت **در حافظه**. و یک تله: انتسابِ یک `JSONValue` دسته را
کپی می‌کند، نه درخت را.

```d
import JsonDAP, std.file, std.json, std.stdio;

void main()
{
    string file = "merge.json";
    JsonAP.APwriteJsonFile!JSONValue(file, parseJSON(
            `{"keep":1,"shared":{"deep":1},"cursor":{"line":3}}`));

    JSONValue incoming = parseJSON(`{"shared":{"deep":2,"added":3},"fresh":true}`);
    writeln(JsonAP.APmergeJson(file, incoming, true, false));
    writeln(readText(file));

    string reason = JsonAP.APmergeJsonWithMessage(file, parseJSON(`{"fresh":false}`), false, false);
    writeln(reason == "" ? "merged" : reason);

    string message;
    writeln(JsonAP.APmergeJsonWithMessage(file, parseJSON(`{"extra":1}`), true, false, message));

    JSONValue target = parseJSON(`{"a":1,"shared":{"deep":1}}`);
    JSONValue source = parseJSON(`{"a":2,"shared":{"deep":2,"added":3}}`);
    writeln(JsonAP.APrecursiveMerge(target, source, true, false, message));
    writeln(target.toString());

    JSONValue result;
    JSONValue untouched = parseJSON(`{"a":1}`);
    writeln(JsonAP.APrecursiveMergeCopy(untouched, source, true, false, result, message));
    writeln(untouched.toString(), " -> ", result.toString());

    JSONValue original = parseJSON(`{"list":[1,{"k":"v"}]}`);
    JSONValue shallow = original;
    shallow.object["list"].array[0] = JSONValue(7);
    writeln(original.toString());

    JSONValue deep = JsonAP.APdeepCopy(original);
    deep.object["list"].array[0] = JSONValue(0);
    writeln(original.toString(), " | ", deep.toString());
}
```

چاپ می‌کند:

```text
true
{"cursor":{"line":3},"fresh":true,"keep":1,"shared":{"added":3,"deep":2}}
merged
true
true
{"a":2,"shared":{"added":3,"deep":2}}
true
{"a":1} -> {"a":2,"shared":{"added":3,"deep":2}}
{"list":[7,{"k":"v"}]}
{"list":[7,{"k":"v"}]} | {"list":[0,{"k":"v"}]}
```

| متد | کجا می‌نویسد | پاسخ |
|---|---|---|
| `APmergeJson(file, source, overwrite, mergeArrays)` | فایلِ روی دیسک | `bool` |
| `APmergeJsonWithMessage(file, source, overwrite, mergeArrays, out message)` | فایلِ روی دیسک | `bool` + دلیل |
| `APmergeJsonWithMessage(file, source, overwrite, mergeArrays)` | فایلِ روی دیسک | در موفقیت `""`، وگرنه دلیل |
| `APrecursiveMerge(target, source, overwrite, mergeArrays, out message)` | خودِ `target` | `bool` |
| `APrecursiveMergeCopy(target, source, overwrite, mergeArrays, out result, out message)` | `result` تازه | `bool` |
| `APdeepCopy(node)` | — | یک کپیِ جدا |

`overwrite` تصمیم می‌گیرد وقتی هر دو سمت کلید را دارند چه شود؛ `mergeArrays` تصمیم می‌گیرد آرایه
جایگزین شود یا افزوده. اولین خروجی دلیلِ وجودِ ادغام است: `keep` و `cursor`، کلیدهایی که این کد هرگز
نامشان را نبرد، از نوشتن جان سالم بردند.

دو خطِ آخر، تله را کامل نشان می‌دهند. `JSONValue shallow = original` یک درخت را به اشتراک می‌گذارد،
پس ویرایشِ یکی، دیگری را هم تغییر می‌دهد. `APdeepCopy` هر گره را از نو می‌سازد و تنها بعد از آن می‌شود
درختی را ویرایش کرد بی‌آنکه همسایه‌اش تکان بخورد. منابعی هم که به متدهای ادغام می‌دهید به همین دلیل
از نو کپی می‌شوند — `source` شما هرگز تغییر نمی‌کند.

## ۶ — سام‌تایپ

`SumType` یکی از اعضا را نگه می‌دارد، پس JSON باید بگوید کدام. پوشش
`{"tag":…,"value":…}` است.

```d
import JsonDAP, std.conv, std.json, std.stdio, std.sumtype;

alias Cursor = SumType!(int, string);

string describe(Cursor held)
{
    return held.match!((int line) => "line " ~ line.to!string,
                       (string needle) => "search " ~ needle);
}

void main()
{
    Cursor line = Cursor(42);

    JSONValue wire = JsonAP.APserializeSumType!Cursor(line);
    writeln(wire.toString());

    auto back = JsonAP.APdeserializeSumType!Cursor(wire);
    writeln(describe(back.get));

    auto fromText = JsonAP.APdeserializeSumTypeFromString!Cursor(
            `{"tag":"string","value":"needle"}`);
    writeln(describe(fromText.get));

    string delegate(string) tagOf = (string memberName) => memberName == "int" ? "line" : "search";

    JSONValue renamed = JsonAP.APserializeSumType!Cursor(line, tagOf);
    writeln(renamed.toString());
    auto reopened = JsonAP.APdeserializeSumType!Cursor(renamed, false, tagOf);
    writeln(describe(reopened.get));

    JSONValue handled = JsonAP.APserializeSumTypeWithHandlers!Cursor(line,
            (Cursor held) => held.match!((int n) => "line", (string s) => "search"),
            (Cursor held) => held.match!((int n) => JSONValue(n), (string s) => JSONValue(s)));
    writeln(handled.toString());

    auto resolved = JsonAP.APdeserializeSumTypeWithHandlers!Cursor(handled,
            (string tag, JSONValue payload) => tag == "line"
                    ? Cursor(cast(int) payload.integer)
                    : Cursor(payload.str));
    writeln(describe(resolved.get));
}
```

چاپ می‌کند:

```text
{"tag":"int","value":42}
line 42
search needle
{"tag":"line","value":42}
line 42
{"tag":"line","value":42}
line 42
```

| متد | ورودی | خروجی |
|---|---|---|
| `APserializeSumType!T(value, tagOf = null)` | یک مقدار | `JSONValue` |
| `APdeserializeSumType!T(node, lenient = false, tagOf = null)` | یک پوشش | `Optional!T` |
| `APdeserializeSumTypeFromString!T(text, lenient = false, tagOf = null)` | متنِ JSON | `Optional!T` |
| `APserializeSumTypeWithHandlers!T(value, tagOf, payloadOf)` | مقدار + دو delegate | `JSONValue` |
| `APdeserializeSumTypeWithHandlers!T(node, resolver)` | پوشش + resolver | `Optional!T` |

تگ‌های پیش‌فرض نامِ نوعِ D هستند — `"int"`، `"string"` — و همین، نوع‌های شما را به فایل درز می‌دهد.
به هر دو جهت **همان** تابع را بدهید (`tagOf` بالا) و سیم می‌گوید `"line"`، در حالی که خواننده هنوز
می‌داند کدام عضو را بسازد. تگِ ناشناخته با فهرستِ تگ‌های موجود رد می‌شود؛ payloadی که با تگش
نمی‌خواند هم رد می‌شود.

`…WithHandlers` به‌جای نامِ عضو، کلِ مقدار را می‌دهد، پس دو عضوِ `int` می‌توانند تگ‌های متفاوت داشته
باشند. `resolver` تنها جایی است که تصمیم می‌گیرد کدام عضو ساخته شود — آن را دروازه‌ی بررسی بدانید، نه
یک cast.

## ۷ — بررسی و نگهبانی

در این بخش هیچ چیز در فایلی نوشته نمی‌شود. این فراخوانی‌ها **پیش از** اعتماد به متنِ یک فایل، یک
کادرِ مسیر یا صفحه‌کلید می‌آیند.

```d
import JsonDAP, std.json, std.stdio;

void main()
{
    writeln(JsonAP.APisValidJson(`{"a":1}`));
    writeln(JsonAP.APisValidJson(`{"a":`));

    writeln(JsonAP.APisJsonObject(`{"a":1}`));
    writeln(JsonAP.APisJsonArray(`[1,2]`));
    writeln(JsonAP.APisJsonNumber(`42`));
    writeln(JsonAP.APisJsonString(`"text"`));
    writeln(JsonAP.APisJsonObject(`[1,2]`));

    writeln(JsonAP.APgetJsonItemCount(`{"a":1,"b":2}`).get);
    writeln(JsonAP.APprettyPrintJson(`{"a":1,"b":[1,2]}`).get);

    bool flag;
    string reason;
    JsonAP.APstrIsNil("notes.txt", "file path", flag, reason);
    writeln(flag);
    JsonAP.APstrIsNil("   ", "file path", flag, reason);
    writeln(flag, " ", reason);

    writeln(JsonAP.APCheckStringIsNullArray(["a", "b"]));
    writeln(JsonAP.APCheckStringIsNullArray([]));
}
```

چاپ می‌کند:

```text
true
false
true
true
true
true
false
2
{
    "a": 1,
    "b": [
        1,
        2
    ]
}
false
true Parameter 'file path' cannot be just whitespace.
false
true
```

| متد | پاسخ |
|---|---|
| `APisValidJson(text)` | آیا اصلاً parse می‌شود — هرگز استثنا نمی‌دهد |
| `APisJsonObject` / `APisJsonArray` / `APisJsonNumber` / `APisJsonString` | شکلِ گرهِ **بالا** |
| `APgetJsonItemCount(text)` | `Optional!long` — کلیدهای یک object، عضوهای یک array |
| `APprettyPrintJson(text)` | `Optional!string`، تودرتویی چهار فاصله |
| `APstrIsNil(input, paramName, out flag, out reason)` | `void`؛ `flag` می‌گوید «بی‌استفاده»، `reason` نامِ پارامتر را می‌گوید |
| `APCheckStringIsNullArray(inputs)` | `bool`؛ با `UnknownErrorExceptionAP` همه‌ی اندیس‌های خالی را فهرست می‌کند |

جفت‌های خروجی را بخوانید. `APisValidJson` برای متنِ خراب `false` می‌دهد نه استثنا، و `APisJsonObject`
برای JSON معتبر ولی با شکلِ دیگر `false` — «JSON است؟» و «همان چیزی است که می‌خواهم؟» دو پرسش‌اند.
`APCheckStringIsNullArray` برای فهرستِ **خالی** `true` می‌دهد: چیزی برای بررسی نیست، شکست نیست.

`APstrIsNil` عمداً الگویِ مخالفِ predicateها را دارد: `void` است، چون فراخوان از یک فراخوانی دو پاسخ
می‌خواهد — یک flag و جمله‌ای که نشان دهد.

## ۸ — رقم‌ها در سه خط

عددها تایپ‌شده می‌رسند، با هر رقمی که صفحه‌کلید تولید کرده. اول یکسان‌سازی، بعد پرسش، بعد تبدیل.

```d
import JsonDAP, std.conv, std.stdio;

void main()
{
    writeln(JsonAP.APisDigitAP('7'), " ", JsonAP.APisDigitAP('۵'), " ",
            JsonAP.APisDigitAP('٧'), " ", JsonAP.APisDigitAP('x'));

    foreach (sample; ["7", "+7", "−7", "۱۲", "12.5", "۱۲٫۵", "1e9", "x"])
    {
        writeln(sample, " -> ", JsonAP.APisInteger(sample), " ",
                JsonAP.APisSignedInteger(sample), " ", JsonAP.APisDecimal(sample));
    }

    writeln(JsonAP.APnormalizeDigitsAP("۱۲٫۵"), " ", JsonAP.APnormalizeDigitsAP("−7"));

    string raw = "۱۲";
    if (JsonAP.APisInteger(raw))
    {
        writeln(JsonAP.APnormalizeDigitsAP(raw).to!int + 1);
    }
}
```

چاپ می‌کند:

```text
true true true false
7 -> true true false
+7 -> false true false
−7 -> false true false
۱۲ -> true true false
12.5 -> false false true
۱۲٫۵ -> false false true
1e9 -> false false false
x -> false false false
12.5 -7
13
```

| متد | پرسشی که پاسخ می‌دهد |
|---|---|
| `APisDigitAP(dchar)` | آیا این یک نویسه، رقم است در فارسی، عربی-هندی یا ASCII |
| `APisInteger(s)` | فقط رقم — بدونِ علامت، بدونِ نقطه |
| `APisSignedInteger(s)` | یک `+`/`-` (یا `−`) اختیاری، سپس رقم |
| `APisDecimal(s)` | علامت، رقم، **یک** نقطه (یا `٫`)، رقم |
| `APnormalizeDigitsAP(s)` | رقم‌ها → ASCII، `٫` → `.`، `−` → `-`؛ بقیهٔ نویسه‌ها دست‌نخورده |

دو خطِ آخر درسِ ماجراست. `APisInteger("۱۲")` درست است، ولی `"۱۲".to!int` استثنا می‌دهد — دروازه متن
را بررسی کرد، `std.conv` هنوز ASCII می‌خواهد. `APnormalizeDigitsAP` پل است: اول یکسان‌سازی، بعد
تبدیل. (مسیرها این کار را برایتان می‌کنند؛ فصل [۰۴](04-path-syntax.md) جایی است که `items[۲]` کار
می‌کند.)

شکلِ نمایی (exponent) اینجا decimal نیست: `1e9` به هر سه دروازه `false` می‌دهد. اگر ورودی‌تان می‌تواند
آن را داشته باشد، خودتان بررسی کنید.

## ۹ — نام‌های deprecated

دو نام هنوز برای کدِ قدیمی export می‌شوند. آن‌ها به املایِ درست delegate می‌کنند، با علامت `deprecated`،
پس کدِ قدیمی کامپایل می‌شود و کدِ جدید هشدار می‌گیرد.

```d
import JsonDAP, std.stdio;

deprecated("Use APstrIsNil; the name was only kept for old code.")
void legacyBlankGuard(string input, out bool flag, out string reason)
{
    JsonAP.APStrIsNUll(input, "input", flag, reason);
}

void main()
{
    bool flag;
    string reason;
    legacyBlankGuard("", flag, reason);
    writeln(flag, " ", reason);
}
```

چاپ می‌کند:

```text
true Parameter 'input' cannot be empty.
```

صدا زدنِ `legacyBlankGuard` از `main` خودتان یک هشدارِ deprecation در زمانِ کامپایل چاپ می‌کند — یعنی
مکانیزم دارد کار می‌کند. فراخوانیِ درونی را در یک تابعِ کوچک بگذارید، مثل بالا، تا هشدار در لبه‌ی
برنامه‌تان بماند نه در همه‌ی فایل‌ها.

| Deprecated | به‌جایش |
|---|---|
| `APStrIsNUll(input, paramName, out flag, out text)` | `APstrIsNil(input, paramName, out flag, out reason)` |
| `StrIsNUll` روی کلاسِ کمکی | `strIsNil` |

## کلِ سطحِ API در یک جدول

هر نامِ صادرشده، مثالی که اجرایش می‌کند، و پاسخی که می‌دهد. این صفحه را هنگامِ کدنویسی باز نگه
دارید.

| API | مثال | پاسخ |
|---|---|---|
| `APwriteJsonFile!T(file, value)` | ۱ | `bool` |
| `APreadJsonFile!T(file)` | ۱ | `Optional!T` |
| `APreadJsonArray!T(file)` | ۱ | `Optional!(T[])` |
| `APgetJsonFileSize(file)` | ۱ | `Optional!long` |
| `APexistsFile(file)` / `APexists(path)` | ۱ | `bool` |
| `APserializeToJson!T(value)` | ۲ | `JSONValue` |
| `APserializeTToJsonValue!T(value)` | ۲ | `JSONValue` |
| `APdeserializeJson!T(text)` | ۲ | `Optional!T`، strict |
| `APdeserializeJsonLenient!T(text)` | ۲ | `Optional!T`، فیلدهای غایب پیش‌فرض |
| `APdeserializeJsonArray!T(text)` | ۲ | `Optional!(T[])` |
| `APconvertJsonValueToT!T(node, lenient)` | ۲ | `Optional!T` |
| `APserializeToJsonArray!T(value)` | ۲ | `JSONValue[]`، یک عضو |
| `APgetJsonValueType(node)` | ۲ | `JSONType` |
| `IsIntAP` `IsFloatAP` `IsBoolAP` `IsStringAP` `IsArrayAP` `IsClassAP` `IsEnumAP` `IsStructAP` `IsNumberAP` | ۲ | `enum bool value` |
| `APJsonPathParser(path)` | ۳ | `PathStep[]` |
| `APgetJsonValue!V(text, path)` | ۳ | `Optional!V` |
| `APupdateJsonValueOBJECT!V(file, path, value)` | ۴ | `bool` |
| `APupdateJsonValueARRAY!V(file, path, value)` | ۴ | `bool` |
| `APaddJsonItemOBJECT!T(file, path, value)` | ۴ | `bool` |
| `APaddJsonItemARRAY!T(file, path, value)` | ۴ | `bool` |
| `APremoveJsonItemOBJECT(file, path)` | ۴ | `bool` |
| `APremoveJsonItemARRAY(file, path)` | ۴ | `bool` |
| همزادهای `…WithMessage` آن شش | ۴ | `bool` + `out string message` |
| `APEditMessages` | ۴ | کلاسِ پایه‌ای که همزادها را دارد؛ در کد نام برده نمی‌شود |
| `APmergeJson(file, source, overwrite, mergeArrays)` | ۵ | `bool` |
| `APmergeJsonWithMessage(…, out message)` | ۵ | `bool` + دلیل |
| `APmergeJsonWithMessage(…)` | ۵ | `string` — در موفقیت `""` |
| `APrecursiveMerge(target, source, …, out message)` | ۵ | `bool`، `target` را تغییر می‌دهد |
| `APrecursiveMergeCopy(target, source, …, out result, out message)` | ۵ | `bool`، `result` را پر می‌کند |
| `APdeepCopy(node)` | ۵ | `JSONValue`، جدا |
| `APserializeSumType!T(value, tagOf)` | ۶ | `JSONValue` |
| `APdeserializeSumType!T(node, lenient, tagOf)` | ۶ | `Optional!T` |
| `APdeserializeSumTypeFromString!T(text, lenient, tagOf)` | ۶ | `Optional!T` |
| `APserializeSumTypeWithHandlers!T(value, tagOf, payloadOf)` | ۶ | `JSONValue` |
| `APdeserializeSumTypeWithHandlers!T(node, resolver)` | ۶ | `Optional!T` |
| `APisValidJson(text)` | ۷ | `bool` |
| `APisJsonObject` / `APisJsonArray` / `APisJsonNumber` / `APisJsonString` | ۷ | `bool` |
| `APgetJsonItemCount(text)` | ۷ | `Optional!long` |
| `APprettyPrintJson(text)` | ۷ | `Optional!string` |
| `APstrIsNil(input, paramName, out flag, out reason)` | ۷ | `void` |
| `APCheckStringIsNullArray(inputs)` | ۷ | `bool` |
| `APisDigitAP(dchar)` | ۸ | `bool` |
| `APisInteger` / `APisSignedInteger` / `APisDecimal` | ۸ | `bool` |
| `APnormalizeDigitsAP(text)` | ۸ | `string` |
| `APStrIsNUll` *(deprecated)* | ۹ | `void` |

هر شکستی که خواننده‌ها بالا می‌آورند یک `BaseExceptionAP` است با فایل و خطی که آن را raise کرده؛
فصل [۱۰](10-exceptions.md) درخت و نردبانِ catch را دارد.

بازگشت به [فهرست](../../StartPe.md).
