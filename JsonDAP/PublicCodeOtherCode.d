module PublicCodeOtherCode;


import std.json;
import std.typecons; 
import std.stdio;
import std.conv;
import std.string;

alias Optional = Nullable;


//ایکسپشن ها به لیست ایکسپورت ها اضافه شود 

public class JsonOperationExceptionAP : Exception{
	this(string msg, string file = __FILE__ , size_t line = __LINE__ , Throwable next = null) pure{
		super(msg,file,line,next);
	}
}

public class FileOperationExceptionAP : Exception{
	string filePath;
	this(string msg, string filePath, string file = __FILE__, int line = __LINE__, Throwable next = null) {
        super(msg, file, line, next);
        this.filePath = filePath;
    }
}

public class JSONExceptionAP : Exception {
    this(string msg, string file = __FILE__, int line = __LINE__, Throwable next = null) pure {
        super(msg, file, line, next);
    }
}

public class JSONConvertExceptionAP : Exception
{
    this(string msg, string file = __FILE__, size_t line = __LINE__ , Throwable next = null) pure
    {
        super(msg, file, line , next);
    }
}

public class InvalidArgumentExceptionAP : Exception{
	string parameterName;
	string invalidValue;

	this(string msg, string parameterName , string invalidValue , 
		 string file = __FILE__ , size_t line = __LINE__ , Throwable next = null) pure
	{
		super(msg,file,line,next);
		this.parameterName = parameterName; 
		this.invalidValue = invalidValue;
	}

	this(string msg, string parameterName, string invalidValue) pure
    {
        this(msg, parameterName, invalidValue, __FILE__, __LINE__, null);
    }
	override string toString() {
        return super.toString() ~
            "\n Parameter Name : " ~ parameterName ~
            "\n Invalid Value : " ~ invalidValue;
    }

	string getParameterName() const {
        return parameterName;
    }

    string getInvalidValue() const {
        return invalidValue;
    }
}

public class UnknownErrorexceptionAP : Exception{
	this(string msg , string file = __FILE__ , size_t line = __LINE__ , Throwable next = null ) pure
	{
		super(msg , file , line , next);
	}
}


public static class CL_PublicCodeOtherCode
{
	public static isDigitAP(dchar c)
	{
		if(c >= '0'  && c <= '9')
		{
			return true;
		}
		if (c >= '۰' && c <= '۹') {
            return true;
        }

		return false;
	}


	public static bool isInteger(string s) {
        if (s.empty) return false;

		foreach(dchar c; s)
		{
			if(!isDigitAP(c))
			{
				return false;
			}
		}
        return true;
    }


    public static void StrIsNUll(string input, string paramName = "input" , out bool outputBool , out string ErrorText) 
    {
        try
		{
			if (input is null)
			{
				throw new InvalidArgumentExceptionAP("Parameter '" ~ paramName ~ "' cannot be null.", paramName, "null", __FILE__, __LINE__);
			}
			if (input.empty)
			{
				throw new InvalidArgumentExceptionAP("Parameter '" ~ paramName ~ "' cannot be empty.", paramName, "''", __FILE__, __LINE__);
			}
			if (input.strip.empty)
			{
				throw new InvalidArgumentExceptionAP("Parameter '" ~ paramName ~ "' cannot be just whitespace.", paramName, "'" ~ input ~ "'", __FILE__, __LINE__);
			}
			outputBool = false;
			ErrorText = "";
		}catch(Exception e)
		{
			outputBool = true;
			ErrorText = e.msg;
		}
    }

		
	public static  bool checkStringIsNull_array(string[] inputs) {
		

		if(inputs.length == 0)
		{
			return true;
		}
		foreach(input; inputs)
		{
			string errorText;
			bool isNull;
			if (StrIsNUll(input, out isNull, out errorText) && isNull) {
				throw new UnknownErrorexceptionAP("Unknown error: " ~ errorText ~ " |____|", FILE, LINE);
			}
		}

		return false;
	
	}

	




}