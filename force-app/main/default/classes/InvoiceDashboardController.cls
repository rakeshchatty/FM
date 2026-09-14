/** LWC-facing controller for the invoice dashboard. */
public with sharing class InvoiceDashboardController {

    /** Returns the filtered dashboard result.
     *
     * @param  filter dashboard filter input
     * @return       dashboard result DTO
     */
    @AuraEnabled
    public static InvoiceDashboardModel.DashboardResult getDashboard(InvoiceDashboardModel.Filter filter) {
        try {
            return InvoiceDashboardUtil.buildDashboard(filter);
        } catch (InvoiceDashboardUtil.InvoiceDashboardValidationException exceptionValue) {
            throw new AuraHandledException(exceptionValue.getMessage());
        } catch (Exception exceptionValue) {
            ExceptionService.registerException(exceptionValue, 'InvoiceDashboardController.getDashboard');
            ExceptionService.commitWork();
            throw new AuraHandledException('The invoice dashboard could not be loaded.');
        }
    }

    /** Returns child lines for one invoice.
     *
     * @param  invoiceId invoice header ID
     * @return           invoice line DTOs
     */
    @AuraEnabled
    public static List<InvoiceDashboardModel.InvoiceLine> getInvoiceLines(Id invoiceId) {
        try {
            return InvoiceDashboardUtil.getInvoiceLines(invoiceId);
        } catch (InvoiceDashboardUtil.InvoiceDashboardValidationException exceptionValue) {
            throw new AuraHandledException(exceptionValue.getMessage());
        } catch (Exception exceptionValue) {
            ExceptionService.registerException(exceptionValue, 'InvoiceDashboardController.getInvoiceLines');
            ExceptionService.commitWork();
            throw new AuraHandledException('The invoice lines could not be loaded.');
        }
    }
}
