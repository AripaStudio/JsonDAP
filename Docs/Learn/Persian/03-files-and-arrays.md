# ۰۳ — فایل‌ها و آرایه‌ها

فهرست: [StartPe.md](../../StartPe.md) · قبلی: [۰۲](02-types-and-the-round-trip.md)

## یک رکورد، یک فایل

```d
struct Point
{
    @JsonName("x") int x;
    @JsonName("y") int y;
}

string path = buildPath(tempDir, "note.json");

assert(!JsonAP.APexistsFile(path));                              // nothing there yet
assert(JsonAP.APwriteJsonFile!Point(path, Point(1, 2)));         // serialize + write, true on success
assert(JsonAP.APexists(path));                                   // the same check, the older name
assert(JsonAP.APgetJsonFileSize(path).get > 0);                   // Optional!long, bytes
assert(JsonAP.APreadJsonFile!Point(path).get == Point(1, 2));     // read + deserialize
```

اکنون فایل `{"x":1,"y":2}` را نگه می‌دارد.

| خط | چه کاری انجام می‌دهد |
|---|---|
| `APwriteJsonFile!Point` | آرگومان template نوعِ *آرگومان دوم* است؛ پاسخ `bool` می‌دهد و مقداری برنمی‌گرداند |
| `APexistsFile` | یک فراخوانی، بدون استثنا روی فایلِ نبودن — فقط `false` جواب می‌دهد |
| `APgetJsonFileSize` | `Optional!long`؛ وقتی اندازه را نشود گرفت خالی است |
| `APreadJsonFile!Point` | وقتی فایل آنجا نباشد `FileOperationExceptionAP` را **پرتاب می‌کند** (پایین‌تر ببینید) |

```d
try
{
    JsonAP.APreadJsonFile!Point(buildPath(tempDir, "no_such_file.json"));
}
catch (FileOperationExceptionAP caught)
{
    caught.filePath;        // C:\Users\…\Temp\no_such_file.json
    caught.operationType;   // read
    // File not found for reading.
}
```

## پوشه‌های والد برایتان ساخته می‌شوند

```d
string nested = buildPath(tempDir, "a", "b", "note.json");
assert(JsonAP.APwriteJsonFile!Point(nested, Point(9, 9)));   // a/ and a/b/ are made on the way
assert(exists(nested));
```

[FileAP.d:87](../../../JsonDAP/FileAP.d#L87) پیش از نوشتن `mkdirRecurse` را صدا می‌زند، پس برنامه‌ای که
وضعیتش را در `state/app.json` ذخیره می‌کند در اولین اجرا لازم نیست چیزی را دستی بسازد.

## یک آرایه از رکوردها در یک فایل

```d
Point[] points = [Point(1, 2), Point(3, 4)];

assert(JsonAP.APwriteJsonFile!(Point[])(path, points));       // writes [{"x":1,"y":2},{"x":3,"y":4}]
Point[] fromFile = JsonAP.APreadJsonArray!Point(path).get;    // the array reader wants T, not T[]
assert(fromFile.length == 2);
assert(fromFile[1] == Point(3, 4));
```

`APreadJsonArray!T` کل فایل را می‌خواند، اصرار دارد که گرهٔ بالاترین سطح یک array است و
`Optional!(T[])` برمی‌گرداند. همان تبدیل از **متن** با `APdeserializeJsonArray!T` انجام می‌شود:

```d
Point[] fromText = JsonAP.APdeserializeJsonArray!Point(`[{"x":5,"y":6}]`).get;
assert(fromText[0] == Point(5, 6));
assertThrown!JSONConvertExceptionAP(JsonAP.APdeserializeJsonArray!Point(`{"x":5}`));  // not an array
```

## `APserializeToJsonArray` الحاق می‌کند

```d
JSONValue[] wire;
foreach (record; records)
{
    wire ~= JsonAP.APserializeToJsonArray!Point(Point(7, 8));   // one value in, ONE element out
}
assert(wire.length == records.length);
```

| ورودی `T` | خروجی `JSONValue[]` |
|---|---|
| یک struct، یک class، یک enum | یک آرایهٔ تک‌عضویی که همان گره را نگه می‌دارد |
| `JSONValue` | یک آرایهٔ تک‌عضویی که او را نگه می‌دارد |
| `JSONValue[]` | همان آرایه، دست‌نخورده |

[FileAPJson.d:155](../../../JsonDAP/FileAPJson.d#L155). این متد برای ساختن یک آرایه از رکوردها داخل
یک حلقه وجود دارد، و همین کاری است که
[TextDAPConvert.d:102](../../../JsonDAPtest/TextDAPConvert.d#L102) پیش از نوشتن فایل تاریخچه انجام
می‌دهد و دو خط بعدتر با `APreadJsonArray` دوباره می‌خواندش ([:114](../../../JsonDAPtest/TextDAPConvert.d#L114)).

## API فایل در یک جدول

| متد | چه برمی‌گرداند | حالت شکست |
|---|---|---|
| `APwriteJsonFile!T(filePath, data)` | `bool` | `false`، یا یک استثنای کتابخانه از لایهٔ OS |
| `APreadJsonFile!T(filePath)` | `Optional!T` | وقتی فایل یا JSONش قابل استفاده نباشد پرتاب می‌کند |
| `APreadJsonArray!T(filePath)` | `Optional!(T[])` | وقتی گرهٔ بالاترین سطح array نباشد پرتاب می‌کند |
| `APgetJsonFileSize(filePath)` | `Optional!long` | `Optional` خالی |
| `APexistsFile(filePath)` | `bool` | `false`، هرگز پرتاب نمی‌کند |
| `APexists(filePath)` | `bool` | همان پاسخ، با نام قدیمی‌تر |

بعدی: [۰۴ — نحوِ مسیر](04-path-syntax.md)
