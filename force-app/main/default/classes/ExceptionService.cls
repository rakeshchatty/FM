/** Records unexpected Apex exceptions through the existing FM log abstraction. */
public with sharing class ExceptionService {

    @TestVisible
    private static List<LogRegister> pendingExceptions = new List<LogRegister>();

    /**
     * Registers an exception for the current transaction.
     *
     * @param  exceptionValue exception to record
     * @param  source         source class and method
     */
    public static void registerException(Exception exceptionValue, String source) {
        pendingExceptions.add(new LogRegister(
            'Invoice Dashboard',
            source,
            'Exception',
            null,
            exceptionValue == null ? 'Unknown exception' : exceptionValue.getMessage()
        ));
    }

    /** Commits registered exceptions and clears transaction state. */
    public static void commitWork() {
        if (pendingExceptions.isEmpty()) {
            return;
        }
        LogRegister.createLogs(pendingExceptions);
        pendingExceptions.clear();
    }
}
