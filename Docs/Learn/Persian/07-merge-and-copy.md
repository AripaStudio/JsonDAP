# ۰۷ — ادغام و کپی

فهرست: [StartPe.md](../../StartPe.md) · قبلی: [۰۶](06-editing-a-file-by-path.md)

چهار API، سه پرسش: ادغام **در یک فایل**، ادغامِ **دو درخت در حافظه**، و کپیِ درختی تا اصلی سالم
بماند.

## چرا ادغام؟

`save` در هر چیزی که حالا روی دیسک است ادغام می‌کند، تا کلیدهایی که برنامه نمی‌شناسد — مثل یک
`cursor` که قابلیت دیگری نوشته — بعد از ذخیره بمونند
([TextDAPSession.d:83](../../../JsonDAPtest/TextDAPSession.d#L83)):

```d
JSONValue wire = JsonAP.APserializeToJson!SessionFile(session);

if (JsonAP.APexistsFile(filePath))
{
    if (JsonAP.APmergeJsonWithMessage(filePath, wire, true, false, message))
    {
        return verify(filePath, message);      // ادغام شد، بعد دوباره خوانده و بررسی شد
    }

    CL_TextDap_Console.sayNote(message);       // دلیلِ رد شدن
}

if (!JsonAP.APwriteJsonFile!JSONValue(filePath, wire))   // اولین ذخیره، یا ادغامِ افتاده به پایین
{
    message = format!"nothing was written to %s."(filePath);
    return false;
}
```

| آرگومان | اثر |
|---|---|
| `overwriteExisting` | `true` کلیدی را که هدف دارد جایگزین می‌کند؛ `false` مقدارِ هدف را نگه می‌دارد |
| `mergeArrays` | `false` کلِ آرایه را جایگزین می‌کند؛ `true` عنصرهای مبدأ را اضافه می‌کند |

`message` همان دلیل است: خالی یعنی ادغام انجام شد، و هر چیزِ دیگری می‌گوید چرا نشد.
`"" <=> true`.

## دو درخت در حافظه

```d
JSONValue target = parseJSON(`{"keep":1,"shared":{"deep":1}}`);
JSONValue source = parseJSON(`{"shared":{"deep":2,"added":3},"fresh":true}`);
JSONValue result;

// در جا — خودِ target تغییر می‌کند
assert(JsonAP.APrecursiveMerge(target, source, true, false, mergeMessage));
assert(target.object["shared"].object["deep"] == JSONValue(2));    // جایگزین شد
assert(target.object["shared"].object["added"] == JSONValue(3));   // اضافه شد
assert(target.object["fresh"].type == JSONType.TRUE);              // کلید تازه در ریشه

// در یک خروجیِ تازه — هدف دست‌نخورده می‌ماند
assert(JsonAP.APrecursiveMergeCopy(untouched, source, true, false, result, mergeMessage));
assert("fresh" !in untouched.object);                              // واقعاً دست‌نخورده ماند
assert(result.object["shared"].object["added"] == JSONValue(3));   // نتیجه در result است
```

از `source` قبل از خواندنش یک کپی عمیق گرفته می‌شود، پس درختی که شما داده‌اید در هر حالت دست
نمی‌خورد. `arrayAndMergeDemo` خودِ همین ایده از ابتدا تا انتهاست — خواندنِ آرایه‌ای از دو رکورد
از متن، ادغام، و تبدیلِ یکی به رکورد:

```d
Optional!(DocumentRecord[]) many = JsonAP.APdeserializeJsonArray!DocumentRecord(pack);

JSONValue base   = JsonAP.APserializeToJson!DocumentRecord(many.get[0]);
JSONValue added  = JsonAP.APserializeToJson!DocumentRecord(many.get[1]);

JSONValue mergedValue;
if (JsonAP.APrecursiveMergeCopy(base, added, true, false, mergedValue, mergeMessage))
{
    auto merged = JsonAP.APconvertJsonValueToT!DocumentRecord(mergedValue, true);
    // base دست‌نخورده می‌ماند: "title" هنوز مقدار اصلی را دارد
}
```

## چرا کپیِ یک `JSONValue` کپی نیست

```d
JSONValue original = parseJSON(`{"list":[1,2,{"k":"v"}]}`);

JSONValue shallow = original;                                   // در پشتِ صحنه همان هندل است
shallow.object["list"].array[0] = JSONValue(7);
assert(original.object["list"].array[0] == JSONValue(7));       // هر دو با هم جابه‌جا شدند

JSONValue deep = JsonAP.APdeepCopy(original);
deep.object["list"].array[2].object["k"] = JSONValue("changed");
assert(original.object["list"].array[2].object["k"] == JSONValue("v"));   // اصلی سرِ جایش ماند
```

| خط | چه می‌کند |
|---|---|
| `JSONValue shallow = original` | `JSONValue` یک هندلِ آرایهٔ انجمنی است؛ انتساب داده را مشترک می‌کند |
| `APdeepCopy(original)` | شیءها و آرایه‌ها را طی می‌کند و هر گره را از نو می‌سازد |
| نوشتنِ تودرتو | فقط درختی که هیچ گره مشترکی ندارد، بدون تکان‌دادنِ آن یکی قابل ویرایش است |

قبل از ویرایشِ درختی که از جای دیگری خوانده‌اید `APdeepCopy` را صدا کنید. در
[jsondap_path_tests.d:144](../../../JsonDAPtest/test/jsondap_path_tests.d#L144) هم آزموده شده.

## چهارتا در یک جا

| متد | در کجا می‌نویسد | پاسخ |
|---|---|---|
| `APmergeJson(path, source, overwrite, mergeArrays)` | فایل روی دیسک | `bool` |
| `APmergeJsonWithMessage(path, source, overwrite, mergeArrays, out message)` | فایل روی دیسک | `bool` + دلیل |
| `APrecursiveMerge(target, source, …, out message)` | خودِ `target` | `bool` |
| `APrecursiveMergeCopy(target, source, …, out result, out message)` | `result` تازه | `bool` |
| `APdeepCopy(node)` | — | یک کپیِ جداشده |

بعدی: [۰۸ — سام‌تایپ (SumType)](08-sumtype.md)