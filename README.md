# APJsonD: A Simple and Robust JSON Library for D

APJsonD is a D language library designed to simplify common JSON operations, including file handling, string parsing, and data validation. It provides a clean, high-level API, leveraging D's powerful features like generics (`T`, `V`) and `Nullable` (aliased as `Optional`) for safe and flexible usage.

---

## Features

* **File I/O**: Easy reading from and writing to JSON files.
* **JSON Parsing**: Convert JSON strings to D objects and vice-versa.
* **Data Validation**: Check JSON structure and primitive types.
* **Path-based Value Extraction**: Retrieve nested values using simple dot-separated paths.
* **Robust Error Handling**: Uses custom exceptions for clear error reporting.
* **Utility Functions**: Includes methods for pretty-printing JSON, counting items, and checking digits (including Persian).

---

## Usage

Import the `JsonAP` module and use its static methods directly.

---

## API Reference

All public methods are static and accessible via the `JsonAP` class, prefixed with `AP`.

* `static Optional!T APreadJsonFile(string filePath)()`: Reads and deserializes a JSON file into type `T`.
* `static bool APwriteJsonFile(T)(string filePath, T data)`: Serializes data of type `T` to a JSON file.
* `static Optional!long APgetJsonFileSize(string filePath)`: Gets the size of a JSON file in bytes.
* `static Optional!(T[]) APreadJsonArray(string filePath)()`: Reads a JSON array file into an array of type `T`.
* `static bool APisValidJson(string jsonContent)`: Checks if a string is valid JSON.
* `static Optional!long APgetJsonItemCount(string jsonContent)`: Counts top-level items in JSON.
* `static bool APisJsonNumber(string jsonContent)`: Checks if JSON content is a number.
* `static bool APisJsonString(string jsonContent)`: Checks if JSON content is a string.
* `static Optional!string APprettyPrintJson(string jsonContent)`: Formats JSON string for readability.
* `static Optional!V APgetJsonValue(string jsonContent, string path)()`: Extracts a value by path from JSON.
* `static bool APisJsonObject(string jsonContent)`: Checks if JSON content is an object.
* `static bool APisJsonArray(string jsonContent)`: Checks if JSON content is an array.
* `static bool APisDigitAP(dchar c)`: Checks if a character is a digit (ASCII/Persian).
* `static bool APisInteger(string s)`: Checks if a string represents an integer (ASCII/Persian digits).

---

## Downloads

Compiled binaries (DLLs for Windows) of the library will be made available in the Releases section of this GitHub repository. You can download the pre-built files from there for direct use in your projects.
