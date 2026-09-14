@IsTest
private class ExceptionServiceTest {

    @IsTest
    static void should_register_and_clear_exceptions() {
        ExceptionService.pendingExceptions.clear();

        ExceptionService.registerException(new AuraHandledException('Test exception'), 'ExceptionServiceTest');

        System.Assert.areEqual(1, ExceptionService.pendingExceptions.size(), 'The service must retain one pending exception.');
        System.Assert.areEqual('ExceptionServiceTest', ExceptionService.pendingExceptions[0].process, 'The service must retain the source.');

        ExceptionService.pendingExceptions.clear();
        System.Assert.areEqual(0, ExceptionService.pendingExceptions.size(), 'The test must leave no pending exceptions.');
    }
}
