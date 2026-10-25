module ExceptionAP;

import std.string;
import std.conv;

// throw new BaseExceptionAP("A base system error occurred.", __FILE__, __LINE__);
public class BaseExceptionAP : Exception
{
    string correlationId;

    this(string msg, string file = __FILE__, size_t line = __LINE__, Throwable next = null) @safe pure
    {
        super(msg, file, line, next);
    }

    BaseExceptionAP setCorrelationId(string id) @safe
    {
        this.correlationId = id;
        return this;
    }

    string getCorrelationId() const @safe
    {
        return correlationId;
    }

    override string toString() 
    {
        string baseStr = super.toString();
        if (correlationId !is null && !correlationId.empty)
        {
            baseStr ~= "\n Correlation ID : " ~ correlationId;
        }
        return baseStr;
    }
}

// throw new ParameterRelatedExceptionAP("Invalid input parameter.", "username", "", __FILE__, __LINE__);
public class ParameterRelatedExceptionAP : BaseExceptionAP
{
    string parameterName;
    string invalidValue;

    this(string msg, string parameterName, string invalidValue,
            string file = __FILE__, size_t line = __LINE__, Throwable next = null) @safe pure
    {
        super(msg, file, line, next);
        this.parameterName = parameterName;
        this.invalidValue = invalidValue;
    }

    string getParameterName() const @safe
    {
        return parameterName;
    }

    string getInvalidValue() const @safe
    {
        return invalidValue;
    }

    override string toString() 
    {
        return super.toString() ~ "\n Parameter Name : " ~ parameterName
            ~ "\n Invalid Value : " ~ invalidValue;
    }
}

// throw new ConvertExceptionAP("Failed to convert value.", "ageString", "twenty", "string", "int", "toInt", "Value is not numeric.");
public class ConvertExceptionAP : ParameterRelatedExceptionAP
{
    string inputType;
    string outputType;
    string conversionMethod;
    string reasonForFailure;

    this(string msg, string parameterName, string invalidValue, string inputType, string outputType,
            string conversionMethod = null, string reasonForFailure = null,
            string file = __FILE__, size_t line = __LINE__, Throwable next = null) @safe pure
    {
        super(msg, parameterName, invalidValue, file, line, next);
        this.inputType = inputType;
        this.outputType = outputType;
        this.conversionMethod = conversionMethod;
        this.reasonForFailure = reasonForFailure;
    }

    string getInputType() const @safe
    {
        return inputType;
    }

    string getOutputType() const @safe
    {
        return outputType;
    }

    string getConversionMethod() const @safe
    {
        return conversionMethod;
    }

    string getReasonForFailure() const @safe
    {
        return reasonForFailure;
    }

    override string toString() 
    {
        string baseStr = super.toString();
        baseStr ~= "\n Input Type : " ~ inputType ~ "\n Error Output Type : " ~ outputType;
        if (conversionMethod !is null && !conversionMethod.empty)
        {
            baseStr ~= "\n Conversion Method : " ~ conversionMethod;
        }
        if (reasonForFailure !is null && !reasonForFailure.empty)
        {
            baseStr ~= "\n Reason For Failure : " ~ reasonForFailure;
        }
        return baseStr;
    }
}

// throw new FileOperationExceptionAP("Failed to write to file.", "/path/to/file.txt", "write", 5);
// Note: systemErrorCode typically corresponds to OS-level errno or GetLastError()
/**
* Represents an error during file I/O operations.
* Common System Error Codes (Windows):
* 2  - File Not Found
* 3  - Path Not Found
* 5  - Access Denied
* 32 - Sharing Violation (File in use)
*/
public class FileOperationExceptionAP : BaseExceptionAP
{
    string filePath;
    string operationType;
    int systemErrorCode;

    this(string msg, string filePath, string operationType, int systemErrorCode = 0,
            string file = __FILE__, size_t line = __LINE__, Throwable next = null) @safe pure
    {
        super(msg, file, line, next);
        this.filePath = filePath;
        this.operationType = operationType;
        this.systemErrorCode = systemErrorCode;
    }

    string getFilePath() const @safe
    {
        return filePath;
    }

    string getOperationType() const @safe
    {
        return operationType;
    }

    int getSystemErrorCode() const @safe
    {
        return systemErrorCode;
    }

    override string toString() 
    {
        string baseStr = super.toString();
        baseStr ~= "\n File Path : " ~ filePath ~ "\n Operation Type : " ~ operationType;
        if (systemErrorCode != 0)
        {
            baseStr ~= "\n System Error Code : " ~ to!string(systemErrorCode);
        }
        return baseStr;
    }
}

// throw new InvalidArgumentExceptionAP("Input is out of range.", "quantity", "150", "1-100");
public class InvalidArgumentExceptionAP : ParameterRelatedExceptionAP
{
    string expectedFormatOrRange;

    this(string msg, string parameterName, string invalidValue, string expectedFormatOrRange = null,
            string file = __FILE__, size_t line = __LINE__, Throwable next = null) @safe pure
    {
        super(msg, parameterName, invalidValue, file, line, next);
        this.expectedFormatOrRange = expectedFormatOrRange;
    }

    string getExpectedFormatOrRange() const @safe
    {
        return expectedFormatOrRange;
    }

    override string toString() 
    {
        string baseStr = super.toString();
        if (expectedFormatOrRange !is null && !expectedFormatOrRange.empty)
        {
            baseStr ~= "\n Expected Format/Range : " ~ expectedFormatOrRange;
        }
        return baseStr;
    }
}

// throw new UnknownErrorexceptionAP("An unhandled system error occurred.");
public class UnknownErrorexceptionAP : BaseExceptionAP
{
    this(string msg, string file = __FILE__, size_t line = __LINE__, Throwable next = null) @safe pure
    {
        super(msg, file, line, next);
    }
}

// throw new SyntaxErrorExceptionAP("Invalid JSON syntax found at line 10.", __FILE__, __LINE__);
public class SyntaxErrorExceptionAP : BaseExceptionAP
{
    this(string msg, string file = __FILE__, size_t line = __LINE__, Throwable next = null) @safe pure
    {
        super(msg, file, line, next);
    }
}

// throw new ArgumentNullExceptionAP("username", "Username cannot be empty.");
public class ArgumentNullExceptionAP : ParameterRelatedExceptionAP
{
    this(string parameterName, string msg = "Value cannot be null.",
            string file = __FILE__, size_t line = __LINE__, Throwable next = null) @safe pure
    {
        super(msg, parameterName, "null", file, line, next);
    }
}
