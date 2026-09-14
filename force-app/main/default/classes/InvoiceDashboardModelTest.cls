@IsTest
private class InvoiceDashboardModelTest {

    @IsTest
    static void should_initialize_empty_dashboard_result() {
        InvoiceDashboardModel.DashboardResult result = new InvoiceDashboardModel.DashboardResult();

        System.Assert.isNotNull(result.summary, 'A dashboard result must initialize its summary.');
        System.Assert.areEqual(0, result.summary.invoiceCount, 'An empty result must have zero invoices.');
        System.Assert.areEqual(0, result.summary.totalAmountExclVat, 'An empty result must have zero net amount.');
        System.Assert.isNotNull(result.rows, 'A dashboard result must initialize its row list.');
        System.Assert.areEqual(0, result.rows.size(), 'An empty result must have no rows.');
    }

    @IsTest
    static void should_store_filter_values() {
        Date weekStart = Date.newInstance(2026, 9, 7);
        InvoiceDashboardModel.Filter filter = new InvoiceDashboardModel.Filter();
        filter.mode = 'WEEKLY';
        filter.year = 2026;
        filter.month = 9;
        filter.weekStart = weekStart;

        System.Assert.areEqual('WEEKLY', filter.mode, 'The filter must retain its mode.');
        System.Assert.areEqual(2026, filter.year, 'The filter must retain its year.');
        System.Assert.areEqual(weekStart, filter.weekStart, 'The filter must retain its week start.');
        System.Assert.isNull(filter.accountId, 'The filter account must remain optional.');
    }

    @IsTest
    static void should_construct_date_range() {
        Date startDate = Date.newInstance(2026, 9, 1);
        Date endDate = Date.newInstance(2026, 9, 30);
        InvoiceDashboardModel.DateRange dateRange = new InvoiceDashboardModel.DateRange(startDate, endDate);

        System.Assert.areEqual(startDate, dateRange.startDate, 'The date range must retain its start date.');
        System.Assert.areEqual(endDate, dateRange.endDate, 'The date range must retain its end date.');
    }

    @IsTest
    static void should_construct_two_hundred_invoice_rows_without_queries() {
        List<InvoiceDashboardModel.InvoiceRow> rows = new List<InvoiceDashboardModel.InvoiceRow>();

        for (Integer index = 0; index < 200; index++) {
            InvoiceDashboardModel.InvoiceRow row = new InvoiceDashboardModel.InvoiceRow();
            row.invoiceNumber = 'INV-' + index;
            row.amountExclVat = index;
            rows.add(row);
        }

        System.Assert.areEqual(200, rows.size(), 'The model must support 200 mapped invoice rows.');
        System.Assert.areEqual('INV-199', rows[199].invoiceNumber, 'The final bulk row must retain its value.');
    }
}
