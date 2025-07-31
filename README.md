# JsonDAP: A Powerful JSON Library for D by Aripa Pars Studio

JsonDAP is a robust D language library developed by **Aripa Pars Studio** to streamline JSON operations, including file handling, parsing, serialization, validation, and manipulation. It leverages D's generics (`T`, `V`) and `Nullable` (aliased as `Optional`) for safe, flexible, and efficient JSON processing. The library is under active development, with a dedicated **GitHub Pages** site in progress to showcase its capabilities and provide learning resources. The latest version is **2.0.0**.

---

## Overview

JsonDAP simplifies JSON-related tasks with a clean, high-level API. It supports file I/O, JSON parsing, data validation, path-based value extraction, and advanced manipulation while ensuring robust error handling with custom exceptions.

---

## Features

- **File I/O**: Read and write JSON files effortlessly.
- **JSON Parsing & Serialization**: Convert JSON strings to D types and vice versa.
- **Data Validation**: Validate JSON structures and types.
- **Path-based Extraction**: Access nested JSON values using dot-separated paths.
- **Manipulation**: Merge, update, add, or remove JSON items.
- **Utility Functions**: Pretty-print JSON, count items, and support Persian/ASCII digits.
- **Error Handling**: Comprehensive custom exceptions for clear error reporting.

---

## Usage

Import the `JsonAP` module and use its static methods, prefixed with `AP`, directly.

---

## API Reference

All methods are static, accessible via the `JsonAP` class, and prefixed with `AP`.

### File Operations

###import JsonDAP and JsonAP.APreadJsonFile!T

- `APreadJsonFile<T>(string filePath) -> Optional!T`: Reads and deserializes a JSON file into type `T`.
- `APwriteJsonFile<T>(string filePath, T data) -> bool`: Serializes data of type `T` to a JSON file.
- `APgetJsonFileSize(string filePath) -> Optional!long`: Returns the size of a JSON file in bytes.
- `APreadJsonArray<T>(string filePath) -> Optional!(T[])`: Reads a JSON array file into an array of type `T`.
- `APexistsFile(string filePath) -> bool`: Checks if a file exists.

### JSON Validation

- `APisValidJson(string jsonContent) -> bool`: Verifies if a string is valid JSON.
- `APisJsonObject(string jsonContent) -> bool`: Checks if JSON content is an object.
- `APisJsonArray(string jsonContent) -> bool`: Checks if JSON content is an array.
- `APisJsonNumber(string jsonContent) -> bool`: Checks if JSON content is a number.
- `APisJsonString(string jsonContent) -> bool`: Checks if JSON content is a string.
- `APgetJsonItemCount(string jsonContent) -> Optional!long`: Counts top-level items in JSON.
- `APisDigitAP(dchar c) -> bool`: Checks if a character is a digit (ASCII/Persian).
- `APisInteger(string s) -> bool`: Checks if a string represents an integer (ASCII/Persian digits).

### JSON Manipulation

- `APprettyPrintJson(string jsonContent) -> Optional!string`: Formats JSON for readability.
- `APgetJsonValue<V>(string jsonContent, string path) -> Optional!V`: Extracts a value by path from JSON.
- `APJsonPathParser(string jsonContent) -> JsonAP`: Parses JSON for path-based operations.
- `APrecursiveMerge(JsonAP json1, JsonAP json2) -> JsonAP`: Recursively merges two JSON objects.
- `APStrIsNUll(string s) -> bool`: Checks if a string is null or empty.
- `APCheckStringIsNullArray(string[] arr) -> bool`: Checks if a string array contains null/empty strings.
- `APexists(JsonAP json, string path) -> bool`: Verifies if a JSON path exists.
- `APupdateJsonValueOBJECT(JsonAP json, string path, JsonAP value) -> bool`: Updates a value in a JSON object.
- `APupdateJsonValueARRAY(JsonAP json, string path, JsonAP value) -> bool`: Updates a value in a JSON array.
- `APaddJsonItemOBJECT(JsonAP json, string path, JsonAP value) -> bool`: Adds an item to a JSON object.
- `APaddJsonItemARRAY(JsonAP json, string path, JsonAP value) -> bool`: Adds an item to a JSON array.
- `APremoveJsonItemOBJECT(JsonAP json, string path) -> bool`: Removes an item from a JSON object.
- `APremoveJsonItemARRAY(JsonAP json, string path) -> bool`: Removes an item from a JSON array.
- `APmergeJson(JsonAP json1, JsonAP json2) -> JsonAP`: Merges two JSON objects (non-recursive).
- `APdeserializeJsonArray<T>(string jsonContent) -> Optional!(T[])`: Deserializes a JSON array into type `T[]`.
- `APdeserializeJson<T>(string jsonContent) -> Optional!T`: Deserializes a JSON string into type `T`.
- `APserializeToJson<T>(T data) -> Optional!string`: Serializes data of type `T` to a JSON string.
- `APserializeToJsonArray<T>(T[] data) -> Optional!string`: Serializes an array of type `T` to a JSON array.
- `APgetJsonValueType(string jsonContent) -> string`: Returns the type of a JSON value.
- `APconvertJsonValueToT<T>(string jsonContent) -> Optional!T`: Converts a JSON value to type `T`.
- `APserializeTToJsonValue<T>(T data) -> Optional!string`: Serializes data of type `T` to a JSON value.

### Custom Structs for Data Comparison

- `IsIntAP`: Validates if a value is an integer.
- `IsFloatAP`: Validates if a value is a floating-point number.
- `IsBoolAP`: Validates if a value is a boolean.
- `IsStringAP`: Validates if a value is a string.
- `IsArrayAP`: Validates if a value is an array.
- `IsClassAP`: Validates if a value is a class.
- `IsEnumAP`: Validates if a value is an enum.
- `IsStructAP`: Validates if a value is a struct.
- `IsNumberAP`: Validates if a value is a number (integer or float).

### Powerful and Robust Custom Exception Classes

- `BaseExceptionAP`: Base class for all JsonDAP exceptions.
- `ParameterRelatedExceptionAP`: Handles invalid parameter errors.
- `JSONExceptionAP`: Handles JSON parsing errors.
- `JsonOperationExceptionAP`: Handles JSON operation failures.
- `ConvertExceptionAP`: Handles type conversion errors.
- `FileOperationExceptionAP`: Handles file operation failures.
- `JSONConvertExceptionAP`: Handles JSON conversion errors.
- `InvalidArgumentExceptionAP`: Handles invalid argument errors.
- `UnknownErrorexceptionAP`: Handles unknown errors.

---

## Downloads

Compiled binaries (DLLs for Windows) are available in the Releases section of the GitHub repository. Download pre-built files for direct integration into your projects.
