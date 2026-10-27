# ۰۷ — ادغام و کپی

فهرست: [StartPe.md](../../StartPe.md) · قبلی: [۰۶](06-editing-a-file-by-path.md)

چهار API، سه سؤال: ادغام **در یک فایل**، ادغام **دو `JSONValue`**، و کپی یک درخت تا نسخه‌ی اصلی
سالم بماند.

## ادغام یک سند دیگر در فایل

```d
string path = /* a file holding {"a":1,"nested":{"x":1}} */;

JSONValue incoming = parseJSON(`{"a":2,"b":3,"nested":{"y":2}}`);

assert(JsonAP.APmergeJson(path, incoming, true, false));   // overwrite, do not join arrays
JSONValue merged = JsonAP.APreadJsonFile!JSONValue(path).get;

assert(merged.object["a"] == JSONValue(2));                // overwriteExisting = true
assert(merged.object["nested"].object["x"] == JSONValue(1));   // the untouched key survived
assert(merged.object["nested"].object["y"] == JSONValue(2));   // the new key arrived
// {"a":2,"b":3,"nested":{"x":1,"y":2}}
```

| آرگومان | اثر |
|---|---|
| `overwriteExisting` | `true` کلیدی را که هدف از قبل دارد جایگزین می‌کند؛ `false` مقدارِ هدف را دست‌نخورده می‌گذارد |
| `mergeArrays` | `false` کل آرایه را جایگزین می‌کند؛ `true` عنصرهای مبدأ را اضافه می‌کند |

دو شکلِ پیام‌دار، با یک `bool`:

```d
bool ok = JsonAP.APmergeJsonWithMessage(path, incoming, true, false, message);   // the out-param form

string reason = JsonAP.APmergeJsonWithMessage(path, parseJSON(`{"b":4}`));       // the short form
assert(reason.length == 0);                              // "" means the merge happened
```

شکلِ کوتاه همان فراخوانیِ دو آرگومانی است (`overwriteExisting = true`، `mergeArrays = false` به‌صورت
پیش‌فرض) و به‌جای `bool` + `out` با یک `string` جواب می‌دهد
([JsonDAP.d:217](../../../JsonDAP/JsonDAP.d#L217)) — یک متد `static` بدون `out` نمی‌تواند دو مقدار
برگرداند. `""` یعنی `true`.

اپ برای ذخیره‌ی یک نشست (session) ادغام می‌کند نه بازنویسی، تا ویرایش‌های پنجره‌ی دوم از بین نروند
([TextDAPSession.d:95](../../../JsonDAPtest/TextDAPSession.d#L95)):

```d
if (JsonAP.APexistsFile(filePath))
{
    if (JsonAP.APmergeJsonWithMessage(filePath, wire, true, false, message))
    {
        return verify(filePath, message);            // the file was already there: merge into it
    }

    CL_TextDap_Console.sayNote(message);             // the merge refused: fall through to a write
}

if (!JsonAP.APwriteJsonFile!JSONValue(filePath, wire))   // first save, or a merge that failed
{
    message = format!"nothing was written to %s."(filePath);
    return false;
}
```

## ادغام دو درخت در حافظه

```d
JSONValue target = parseJSON(`{"keep":1,"shared":{"deep":1}}`);
JSONValue source = parseJSON(`{"shared":{"deep":2,"added":3},"fresh":true}`);

string mergeMessage;
assert(JsonAP.APrecursiveMerge(target, source, true, false, mergeMessage));

assert(target.object["shared"].object["deep"] == JSONValue(2));   // the deep key was replaced
assert(target.object["shared"].object["added"] == JSONValue(3));  // the new sibling was added
assert(target.object["fresh"].type == JSONType.TRUE);              // the new top key arrived
```

`target` تغییر می‌کند — امضای تابع `ref JSONValue target` است
([JsonDAP.d:133](../../../JsonDAP/JsonDAP.d#L133)). از `source` قبل از اینکه چیزی از آن خوانده شود
کپی گرفته می‌شود، پس در هر حالت درختی که شما داده‌اید هرگز دست نمی‌خورد.

## اصلی را دست‌نخورده نگه دارید

```d
JSONValue untouched = parseJSON(`{"keep":1,"shared":{"deep":1}}`);
JSONValue result;

assert(JsonAP.APrecursiveMergeCopy(untouched, source, true, false, result, mergeMessage));

assert("fresh" !in untouched.object);                     // the target was not written into
assert(result.object["shared"].object["added"] == JSONValue(3));   // the outcome is in result
// {"fresh":true,"keep":1,"shared":{"added":3,"deep":2}}
```

`APrecursiveMerge` یک `bool` برمی‌گرداند و در `target` می‌نویسد؛ `APrecursiveMergeCopy` هم `bool`
برمی‌گرداند و در یک `out JSONValue result` می‌نویسد — هر دو با همان چهار فلگ، پس فراخوان می‌تواند یکی
را انتخاب کند بدون اینکه دوباره قواعد ادغام را یاد بگیرد.

## چرا کپیِ یک `JSONValue` کپی نیست

```d
JSONValue original = parseJSON(`{"list":[1,2,{"k":"v"}]}`);

JSONValue shallow = original;              // no new tree: the same handle
shallow.object["list"].array[0] = JSONValue(7);
assert(original.object["list"].array[0] == JSONValue(7));   // the "copy" and the original moved together

JSONValue deep = JsonAP.APdeepCopy(original);
deep.object["list"].array[2].object["k"] = JSONValue("changed");
assert(original.object["list"].array[2].object["k"] == JSONValue("v"));   // the original did not move
```

| خط | چه کاری انجام می‌دهد |
|---|---|
| `JSONValue shallow = original` | `std.json.JSONValue` یک هندلِ آرایه‌ی انجمنی است؛ انتساب، داده را مشترک می‌کند |
| `APdeepCopy(original)` | شیءها و آرایه‌ها را طی می‌کند و هر گره را از نو می‌سازد ([JsonDAP.d:147](../../../JsonDAP/JsonDAP.d#L147)) |
| نوشتنِ تودرتو | فقط درختی که هیچ گره‌ای با دیگری مشترک ندارد، بدون تکون‌دادنِ آن یکی قابل ویرایش است |

همان `APdeepCopy` است که قولِ `APrecursiveMerge` درباره‌ی `source` را درست می‌کند، و همان API است که
قبل از ویرایشِ درختی که از جای دیگری خوانده‌اید باید صدا کنید. در
[jsondap_path_tests.d:144](../../../JsonDAPtest/test/jsondap_path_tests.d#L144) هم آزموده شده است.

بعدی: [۰۸ — سام‌تایپ (SumType)](08-sumtype.md)
