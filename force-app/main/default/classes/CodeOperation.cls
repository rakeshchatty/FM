public without sharing class CodeOperation {

	private static Boolean isCodeOperation = false;

    @InvocableMethod(label='Allow DML on Custom Objects' description='Allows programatic DML on custom objects')
    public static void setCodeOperation() {
		isCodeOperation = true;
    }

    public static Boolean isCodeOperation() {
		return isCodeOperation;
	}
 
	public static void setUserOperation() {
		isCodeOperation = false;
	}
}