@IsTest
private class InvoiceDashboardControllerTest {

    @IsTest
    static void should_return_validation_error_for_missing_dashboard_filter() {
        try {
            InvoiceDashboardController.getDashboard(null);
            System.Assert.fail('A missing dashboard filter must return a handled error.');
        } catch (AuraHandledException exceptionValue) {
            System.Assert.isTrue(exceptionValue.getMessage().contains('required'), 'The handled error must explain the missing filter.');
        }
    }

    @IsTest
    static void should_return_validation_error_for_missing_invoice_id() {
        try {
            InvoiceDashboardController.getInvoiceLines(null);
            System.Assert.fail('A missing invoice ID must return a handled error.');
        } catch (AuraHandledException exceptionValue) {
            System.Assert.isTrue(exceptionValue.getMessage().contains('required'), 'The handled error must explain the missing invoice.');
        }
    }
}
