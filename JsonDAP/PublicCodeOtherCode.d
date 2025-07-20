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
			string
			StrIsNUll(input , paramName , isNull, errorText);
			if (isNull) {
				throw new UnknownErrorexceptionAP("Unknown error: " ~ errorText ~ " |__| Like input : ~ "~ paramName ~  " |____| " , __FILE__, __LINE__);
			}
		}

		return false;
	
	}

	

	




}


//اضافه شود 
public class CL_JsonOtherCode{
		
	public static enum PathStepType{
		ObjectKey,
		ArrayIndex
	}

	public static struct PathStep{
		PathStepType type;
		union{
			string key;
			int index;
		}
	}

	 
	public static PathStep[] JsonPathParserAP(string input ){
		string errorTextStrIsNull;
		bool CheckStrIsNull;
		CL_PublicCodeOtherCode.StrIsNUll(input , out CheckStrIsNull , out errorTextStrIsNull);
		if(CheckStrIsNull)
		{
			throw new UnknownErrorexceptionAP("Unknown error." ~ errorTextStrIsNull ~ " |____|  " , __FILE__ , __LINE__);
		}

		PathStep[] pathSteps; 
		int currentIndex = 0;

		while(currentIndex < input.length)
		{
			if(input[currentIndex] == '.')
			{
				currentIndex++;				
				continue;
			}

			if(input[currentIndex] == '[')
			{		
				currentIndex++;
				auto startIndex = currentIndex;
				auto closingBracketIndex  = input.indexOf(']' , startIndex);

				if(closingBracketIndex == -1)
				{
					throw new UnknownErrorexceptionAP("Syntax Error: Missing closing bracket in JSON path. |____|  " , __FILE__ , __LINE__);
				}

				string indexString = input[startIndex .. closingBracketIndex];
				if(indexString.empty)
				{
					throw new UnknownErrorexceptionAP("Syntax Error: Empty array index in JSON path. |____|  " , __FILE__ , __LINE__);
				}

				auto IndexValue = assertThrown!ConvException(to!int(indexString));
				
				PathStep newStep;
				newStep.type = PathStepType.ArrayIndex;
				newStep.index = IndexValue;

				pathSteps ~= newStep;

				currentIndex = closingBracketIndex + 1;
				continue;
			}else{
				auto startIndex = currentIndex;
				auto nextSeparatorIndex = input.length;
				
				auto dotIndex = input.indexOf('.' , startIndex);
				auto bracketIndex = input.indexOf('[' , startIndex);
				
				if (dotIndex != -1 && (dotIndex < nextSeparatorIndex))
				{
					nextSeparatorIndex = dotIndex;
				}

				if (bracketIndex != -1 && (bracketIndex < nextSeparatorIndex))
				{
					nextSeparatorIndex = bracketIndex;
				}

				string keyString = input[startIndex .. nextSeparatorIndex];

				if(keyString.empty)
				{
					throw new UnknownErrorexceptionAP("Syntax Error: Empty object key in JSON path. |____|  " , __FILE__ , __LINE__);
				}

				PathStep newStep;

				newStep.type = PathStepType.ObjectKey;
				newStep.key = keyString;
				
				pathSteps ~= newStep;

				currentIndex = nextSeparatorIndex; 
			}

			
					
		}

		return pathSteps;
	}
}