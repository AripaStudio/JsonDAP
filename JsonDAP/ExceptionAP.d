module ExceptionAP;

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


public class ConvertExceptionAP : Exception{
    string parameterName;
    string invalidValue;
    string InputType;
    string OutPutType;
    this(string msg , string parameterName , string InputType , string OutputType , string invalidValue , 
		 string file = __FILE__ , size_t line = __LINE__ , Throwable next = null)pure{
            super(msg,file,line,next);
            this.parameterName = parameterName;
            this.invalidValue = invalidValue;
            this.InputType = InputType;
            this.OutPutType = OutputType;
		 }
    this(string msg,string parameterName , string invalidValue , string InputType , string OutputType )pure
	{
        this(msg,parameterName,invalidValue , InputType , OutputType , __FILE__ , __LINE__ , null);
	}

    override string toString(){
        return super.toString() ~ 
            "\n Parameter Name : " ~ parameterName ~
            "\n Invalid  Value : " ~ invalidValue ~ 
			"\n Input Type : "  ~ InputType ~ 
            "\n Error Output Type : " ~ OutPutType;
            
	}

    string getParameterName() const {
        return parameterName;
    }

    string getInvalidValue() const {
        return invalidValue;
    }
    
    string getInputType() const {
        return InputType;
	}
    
    string getOutputType() const {
        return OutPutType;
	}

}