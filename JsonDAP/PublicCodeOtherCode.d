module PublicCodeOtherCode;


import std.json;
import std.typecons; 
import std.stdio;
import std.conv;
import std.string;
import std.array;
import std.exception;
import ExceptionAP;

alias Optional = Nullable;

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
			string paramName;			
			CL_PublicCodeOtherCode.StrIsNUll(input , paramName , isNull, errorText);
			if (isNull) {
				throw new UnknownErrorexceptionAP("Unknown error: " ~ errorText ~ " |__| Like input : ~ "~ paramName ~  " |____| " , __FILE__, __LINE__);
			}
		}

		return false;
	
	}

	

	




}

