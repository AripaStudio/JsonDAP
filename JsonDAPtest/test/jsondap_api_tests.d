module jsondap_api_tests;

import JsonDAP;

unittest
{
    import std.stdio;
    import std.file : exists, remove;
    import std.json : JSONValue;

    writeln("==================================================");
    writeln("STARTING JSONDAP CORE OPERATIONAL TESTS");
    writeln("==================================================");

    // -------------------------------------------------------------------------
    // TEST STRUCTURE DEFINITION
    // -------------------------------------------------------------------------
    static struct TestUser
    {
        string name;
        int age;
        string role;
    }

    TestUser originalUser = TestUser("Aripa Studio", 2026, "Developer");
    string testFilePath = "test_aripa_dap.json";

    if (exists(testFilePath))
    {
        remove(testFilePath);
    }

    // -------------------------------------------------------------------------
    // PRIORITY 1: FILE I/O TESTS (APwriteJsonFile & APreadJsonFile)
    // -------------------------------------------------------------------------
    writeln("Running Priority 1: File I/O Tests...");

    bool writeSuccess = JsonAP.APwriteJsonFile!TestUser(testFilePath, originalUser);
    assert(writeSuccess == true, "Failed to write JSON object to file.");
    assert(exists(testFilePath), "Test file was not actually created on disk.");

    auto readResult = JsonAP.APreadJsonFile!TestUser(testFilePath);
    assert(!readResult.isNull, "Failed to read JSON object from file (Returned Nullable.null).");

    TestUser loadedUser = readResult.get();
    assert(loadedUser.name == originalUser.name, "Mismatch in loaded data: name");
    assert(loadedUser.age == originalUser.age, "Mismatch in loaded data: age");
    assert(loadedUser.role == originalUser.role, "Mismatch in loaded data: role");

    writeln("-> Priority 1 Passed successfully.");

    // -------------------------------------------------------------------------
    // PRIORITY 2: SERIALIZATION & DESERIALIZATION TESTS
    // -------------------------------------------------------------------------
    writeln("Running Priority 2: Serialization & Deserialization Tests...");

    JSONValue serializedValue = JsonAP.APserializeToJson!TestUser(originalUser);
    string jsonString = serializedValue.toString();

    auto deserializeResult = JsonAP.APdeserializeJson!TestUser(jsonString);
    assert(!deserializeResult.isNull, "Deserialization returned Nullable.null.");

    TestUser deserializedUser = deserializeResult.get();
    assert(deserializedUser.name == originalUser.name, "Serialization round-trip mismatch: name");
    assert(deserializedUser.age == originalUser.age, "Serialization round-trip mismatch: age");
    assert(deserializedUser.role == originalUser.role, "Serialization round-trip mismatch: role");

    writeln("-> Priority 2 Passed successfully.");

    // -------------------------------------------------------------------------
    // PRIORITY 3: VALIDATION TOOLS TESTS (APisValidJson)
    // -------------------------------------------------------------------------
    writeln("Running Priority 3: Validation Tests...");

    string validJsonStr = `{"project": "JsonDAP", "status": "active", "items": [1, 2, 3]}`;
    string invalidJsonStr = `{"project": "JsonDAP", "status": "active", "items": [1, 2, 3`; // Missing closing bracket

    bool isValid = JsonAP.APisValidJson(validJsonStr);
    bool isInvalid = JsonAP.APisValidJson(invalidJsonStr);

    assert(isValid == true, "Valid JSON string was falsely reported as invalid.");
    assert(isInvalid == false, "Malformed JSON string was falsely reported as valid.");

    writeln("-> Priority 3 Passed successfully.");

    // -------------------------------------------------------------------------
    // CLEANUP
    // -------------------------------------------------------------------------
    if (exists(testFilePath))
    {
        remove(testFilePath);
    }

    writeln("==================================================");
    writeln("ALL CORE JSONDAP TESTS PASSED SUCCESSFULLY!");
    writeln("==================================================");
}