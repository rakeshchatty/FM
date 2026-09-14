@IsTest(SeeAllData=false)
private class InvoiceDashboardUtilTest {

    @IsTest
    static void should_build_yearly_date_range() {
        InvoiceDashboardModel.Filter filter = new InvoiceDashboardModel.Filter();
        filter.mode = InvoiceDashboardUtil.MODE_YEARLY;
        filter.year = 2024;

        InvoiceDashboardModel.DateRange result = InvoiceDashboardUtil.buildDateRange(filter);

        System.Assert.areEqual(Date.newInstance(2024, 1, 1), result.startDate, 'Yearly range must start on January 1.');
        System.Assert.areEqual(Date.newInstance(2024, 12, 31), result.endDate, 'Yearly range must end on December 31.');
    }

    @IsTest
    static void should_build_monthly_date_range() {
        InvoiceDashboardModel.Filter filter = new InvoiceDashboardModel.Filter();
        filter.mode = InvoiceDashboardUtil.MODE_MONTHLY;
        filter.year = 2024;
        filter.month = 2;

        InvoiceDashboardModel.DateRange result = InvoiceDashboardUtil.buildDateRange(filter);

        System.Assert.areEqual(Date.newInstance(2024, 2, 1), result.startDate, 'Monthly range must start on the first day.');
        System.Assert.areEqual(Date.newInstance(2024, 2, 29), result.endDate, 'Leap-year February must include February 29.');
    }

    @IsTest
    static void should_build_weekly_date_range() {
        InvoiceDashboardModel.Filter filter = new InvoiceDashboardModel.Filter();
        filter.mode = InvoiceDashboardUtil.MODE_WEEKLY;
        filter.weekStart = Date.newInstance(2026, 9, 7);

        InvoiceDashboardModel.DateRange result = InvoiceDashboardUtil.buildDateRange(filter);

        System.Assert.areEqual(Date.newInstance(2026, 9, 7), result.startDate, 'Weekly range must retain Monday as its start.');
        System.Assert.areEqual(Date.newInstance(2026, 9, 13), result.endDate, 'Weekly range must include Sunday.');
    }

    @IsTest
    static void should_reject_reversed_custom_date_range() {
        InvoiceDashboardModel.Filter filter = new InvoiceDashboardModel.Filter();
        filter.mode = InvoiceDashboardUtil.MODE_CUSTOM;
        filter.startDate = Date.newInstance(2026, 9, 14);
        filter.endDate = Date.newInstance(2026, 9, 13);

        try {
            InvoiceDashboardUtil.buildDateRange(filter);
            System.Assert.fail('A reversed custom range must be rejected.');
        } catch (InvoiceDashboardUtil.InvoiceDashboardValidationException exceptionValue) {
            System.Assert.isTrue(exceptionValue.getMessage().contains('cannot be before'), 'The validation message must explain the date order.');
        }
    }

    @IsTest
    static void should_return_empty_dashboard_for_no_matching_records() {
        InvoiceDashboardModel.Filter filter = new InvoiceDashboardModel.Filter();
        filter.mode = InvoiceDashboardUtil.MODE_CUSTOM;
        filter.startDate = Date.newInstance(1900, 1, 1);
        filter.endDate = Date.newInstance(1900, 1, 2);

        Test.startTest();
        InvoiceDashboardModel.DashboardResult result = InvoiceDashboardUtil.buildDashboard(filter);
        Test.stopTest();

        System.Assert.areEqual(0, result.summary.invoiceCount, 'No matching invoices must produce a zero count.');
        System.Assert.areEqual(0, result.rows.size(), 'No matching invoices must produce no rows.');
        System.Assert.areEqual(0, result.summary.totalAmountExclVat, 'No matching invoices must produce zero net amount.');
    }

    @IsTest
    static void should_reject_missing_filter() {
        try {
            InvoiceDashboardUtil.buildDateRange(null);
            System.Assert.fail('A missing filter must be rejected.');
        } catch (InvoiceDashboardUtil.InvoiceDashboardValidationException exceptionValue) {
            System.Assert.isTrue(exceptionValue.getMessage().contains('required'), 'The validation message must explain the missing filter.');
        }
    }
}
