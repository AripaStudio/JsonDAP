# JsonDAP — documentation

Two learning tracks, the same content:

- **[English](StartEn.md)** — `Docs/Learn/English/`
- **[فارسی](StartPe.md)** — `Docs/Learn/Persian/`

The API reference lives in the READMEs and is not repeated here:
[README.md](../README.md) (English) · [README.fa.md](../README.fa.md) (Persian).

## Chapters

| # | English | فارسی | About |
|---|---|---|---|
| 01 | [Setup](Learn/English/01-setup.md) | [نصب](Learn/Persian/01-setup.md) | the two dub dependency forms, the first `import`, the reference app |
| 02 | [Types and the round trip](Learn/English/02-types-and-the-round-trip.md) | [انواع و رفت‌وبرگشت](Learn/Persian/02-types-and-the-round-trip.md) | `@JsonName`, `@JsonIgnore`, enum, `Optional`, strict against lenient |
| 03 | [Files and arrays](Learn/English/03-files-and-arrays.md) | [فایل‌ها و آرایه‌ها](Learn/Persian/03-files-and-arrays.md) | read, write, size, exists, arrays of records, auto-created folders |
| 04 | [Path syntax](Learn/English/04-path-syntax.md) | [ نحوِ مسیر](Learn/Persian/04-path-syntax.md) | `PathStep`, escapes, Persian digits, every refusal the parser makes |
| 05 | [Reading one value](Learn/English/05-reading-a-value.md) | [خواندن یک مقدار](Learn/Persian/05-reading-a-value.md) | `APgetJsonValue!V`, which type is accepted, what throws |
| 06 | [Editing a file by path](Learn/English/06-editing-a-file-by-path.md) | [ویرایش فایل با مسیر](Learn/Persian/06-editing-a-file-by-path.md) | update / add / remove, the `WithMessage` twins and their exact messages |
| 07 | [Merging and copying](Learn/English/07-merge-and-copy.md) | [ادغام و کپی](Learn/Persian/07-merge-and-copy.md) | `APmergeJson`, `APrecursiveMerge`, `APrecursiveMergeCopy`, `APdeepCopy` |
| 08 | [SumType](Learn/English/08-sumtype.md) | [سام‌تایپ](Learn/Persian/08-sumtype.md) | the `{"tag","value"}` envelope, custom tags, the handler pair |
| 09 | [Inspecting and guarding](Learn/English/09-inspecting-and-guarding.md) | [بررسی و نگهبان‌ها](Learn/Persian/09-inspecting-and-guarding.md) | the predicates, the digit family, the blank guards |
| 10 | [Exceptions](Learn/English/10-exceptions.md) | [استثناها](Learn/Persian/10-exceptions.md) | the tree, the fields, the catch ladder |
| 11 | [API coverage map](Learn/English/11-api-coverage-map.md) | [نقشه‌ی پوشش API](Learn/Persian/11-api-coverage-map.md) | every `AP…` name → chapter → the line that uses it |

## How these examples were produced

Every code block in `Docs/Learn/` was compiled and run against the sources in this folder —
including the printed output, the exception messages and the JSON text. Nothing here is written
from the signature alone.

The program the chapters point at is **TextDAP** (`JsonDAPtest/`), a console text editor built on
this library; it is the library's largest test at the same time.
