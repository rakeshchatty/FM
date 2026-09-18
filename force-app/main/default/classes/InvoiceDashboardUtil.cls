/** Query and mapping utility for the invoice dashboard. */
public with sharing class InvoiceDashboardUtil {

    /** Supported yearly filter mode. */
    public static final String MODE_YEARLY = 'YEARLY';
    /** Supported monthly filter mode. */
    public static final String MODE_MONTHLY = 'MONTHLY';
    /** Supported weekly filter mode. */
    public static final String MODE_WEEKLY = 'WEEKLY';
    /** Supported custom filter mode. */
    public static final String MODE_CUSTOM = 'CUSTOM';

    /** Builds an inclusive date range from dashboard filter input.
        *
     * @param  filter dashboard filter input
     * @return       inclusive date range
     */
    public static InvoiceDashboardModel.DateRange buildDateRange(InvoiceDashboardModel.Filter filter) {
        if (filter == null || String.isBlank(filter.mode)) {
            throw new InvoiceDashboardValidationException('A reporting filter is required.');
        }

        switch on filter.mode {
            when 'YEARLY' {
                return buildYearlyRange(filter.year);
            }
            when 'MONTHLY' {
                return buildMonthlyRange(filter.year, filter.month);
            }
            when 'WEEKLY' {
                return buildWeeklyRange(filter.weekStart);
            }
            when 'CUSTOM' {
                return buildCustomRange(filter.startDate, filter.endDate);
            }
            when else {
                throw new InvoiceDashboardValidationException('The reporting mode is not supported.');
            }
        }
    }

    /** Queries filtered invoice headers and grouped line totals.
        *
     * @param  filter dashboard filter input
     * @return       dashboard result
     */
    public static InvoiceDashboardModel.DashboardResult buildDashboard(InvoiceDashboardModel.Filter filter) {
        InvoiceDashboardModel.DateRange dateRange = buildDateRange(filter);
        List<Invoice_Header__c> headers = queryHeaders(dateRange, filter.accountId);
        InvoiceDashboardModel.DashboardResult result = new InvoiceDashboardModel.DashboardResult();
        result.summary.invoiceCount = headers.size();

        Set<Id> headerIds = new Map<Id, Invoice_Header__c>(headers).keySet();
        Map<Id, AggregateResult> lineTotalsByHeaderId = queryLineTotals(headerIds);

        for (Invoice_Header__c header : headers) {
            InvoiceDashboardModel.InvoiceRow row = toInvoiceRow(header);
            result.rows.add(row);
            result.summary.totalAmountExclVat += zeroIfNull(header.AmountExclVAT__c);
            result.summary.totalVat += zeroIfNull(header.VAT__c);
            result.summary.totalAmountInclVat += zeroIfNull(header.AmountInclVAT__c);
            result.summary.totalOutstandingAmount += zeroIfNull(header.AmountOutstanding__c);

            AggregateResult lineTotals = lineTotalsByHeaderId.get(header.Id);
            if (lineTotals != null) {
                result.summary.totalLineQuantity += decimalValue(lineTotals, 'totalQuantity');
                result.summary.totalLineAmount += decimalValue(lineTotals, 'totalAmount');
            }
        }
        return result;
    }

    /** Queries child lines for one invoice header.
        *
     * @param  invoiceId invoice header ID
     * @return           invoice line DTOs
     */
    public static List<InvoiceDashboardModel.InvoiceLine> getInvoiceLines(Id invoiceId) {
        if (invoiceId == null) {
            throw new InvoiceDashboardValidationException('An invoice is required.');
        }

        List<InvoiceDashboardModel.InvoiceLine> lines = new List<InvoiceDashboardModel.InvoiceLine>();
        for (Invoice_Line__c line : [
            SELECT Id, Product_Name__c, Description__c, Qty__c, UnitPrice__c, Total_Price__c, VAT__c
            FROM Invoice_Line__c
            WHERE Invoice_HeaderId__c = :invoiceId
            WITH USER_MODE
            ORDER BY InvoiceDate__c ASC, Name ASC, Id ASC
        ]) {
            InvoiceDashboardModel.InvoiceLine lineModel = new InvoiceDashboardModel.InvoiceLine();
            lineModel.id = line.Id;
            lineModel.productName = line.Product_Name__c;
            lineModel.description = line.Description__c;
            lineModel.quantity = line.Qty__c;
            lineModel.unitPrice = line.UnitPrice__c;
            lineModel.totalPrice = line.Total_Price__c;
            lineModel.vat = line.VAT__c;
            lines.add(lineModel);
        }
        return lines;
    }

    /** Exception raised for invalid dashboard filter input. */
    public class InvoiceDashboardValidationException extends Exception {
    }

    private static List<Invoice_Header__c> queryHeaders(InvoiceDashboardModel.DateRange dateRange, Id accountId) {
        if (accountId == null) {
            return [
                SELECT Id, InvoiceNo__c, Account__c, Account__r.Name, Invoiced_Date__c,
                    PeriodStart__c, PeriodEnd__c, Status__c, DueDate__c, AmountExclVAT__c,
                    VAT__c, AmountInclVAT__c, AmountOutstanding__c
                FROM Invoice_Header__c
                WHERE Invoiced_Date__c >= :dateRange.startDate
                    AND Invoiced_Date__c <= :dateRange.endDate
                WITH USER_MODE
                ORDER BY Invoiced_Date__c DESC, Id DESC
            ];
        }

        return [
            SELECT Id, InvoiceNo__c, Account__c, Account__r.Name, Invoiced_Date__c,
                PeriodStart__c, PeriodEnd__c, Status__c, DueDate__c, AmountExclVAT__c,
                VAT__c, AmountInclVAT__c, AmountOutstanding__c
            FROM Invoice_Header__c
            WHERE Invoiced_Date__c >= :dateRange.startDate
                AND Invoiced_Date__c <= :dateRange.endDate
                AND Account__c = :accountId
            WITH USER_MODE
            ORDER BY Invoiced_Date__c DESC, Id DESC
        ];
    }

    private static Map<Id, AggregateResult> queryLineTotals(Set<Id> headerIds) {
        Map<Id, AggregateResult> totalsByHeaderId = new Map<Id, AggregateResult>();
        if (headerIds.isEmpty()) {
            return totalsByHeaderId;
        }

        for (AggregateResult total : [
            SELECT Invoice_HeaderId__c headerId, SUM(Qty__c) totalQuantity, SUM(Total_Price__c) totalAmount
            FROM Invoice_Line__c
            WHERE Invoice_HeaderId__c IN :headerIds
            WITH USER_MODE
            GROUP BY Invoice_HeaderId__c
        ]) {
            totalsByHeaderId.put((Id)total.get('headerId'), total);
        }
        return totalsByHeaderId;
    }

    private static InvoiceDashboardModel.InvoiceRow toInvoiceRow(Invoice_Header__c header) {
        InvoiceDashboardModel.InvoiceRow row = new InvoiceDashboardModel.InvoiceRow();
        row.id = header.Id;
        row.invoiceNumber = header.InvoiceNo__c;
        row.accountId = header.Account__c;
        row.accountName = header.Account__r == null ? null : header.Account__r.Name;
        row.invoicedDate = header.Invoiced_Date__c;
        row.periodStart = header.PeriodStart__c;
        row.periodEnd = header.PeriodEnd__c;
        row.status = header.Status__c;
        row.dueDate = header.DueDate__c;
        row.amountExclVat = header.AmountExclVAT__c;
        row.vat = header.VAT__c;
        row.amountInclVat = header.AmountInclVAT__c;
        row.amountOutstanding = header.AmountOutstanding__c;
        return row;
    }

    private static Decimal decimalValue(AggregateResult total, String aliasName) {
        Object value = total.get(aliasName);
        return value == null ? 0 : (Decimal)value;
    }

    private static Decimal zeroIfNull(Decimal value) {
        return value == null ? 0 : value;
    }

    private static void validateYear(Integer year) {
        if (year == null || year < 1900 || year > 2200) {
            throw new InvoiceDashboardValidationException('A valid reporting year is required.');
        }
    }

    private static InvoiceDashboardModel.DateRange buildYearlyRange(Integer year) {
        validateYear(year);
        Date startDate = Date.newInstance(year, 1, 1);
        return new InvoiceDashboardModel.DateRange(startDate, startDate.addYears(1).addDays(-1));
    }

    private static InvoiceDashboardModel.DateRange buildMonthlyRange(Integer year, Integer month) {
        validateYear(year);
        if (month == null || month < 1 || month > 12) {
            throw new InvoiceDashboardValidationException('A valid reporting month is required.');
        }
        Date startDate = Date.newInstance(year, month, 1);
        return new InvoiceDashboardModel.DateRange(startDate, startDate.addMonths(1).addDays(-1));
    }

    private static InvoiceDashboardModel.DateRange buildWeeklyRange(Date weekStart) {
        if (weekStart == null) {
            throw new InvoiceDashboardValidationException('A reporting week is required.');
        }
        return new InvoiceDashboardModel.DateRange(weekStart, weekStart.addDays(6));
    }

    private static InvoiceDashboardModel.DateRange buildCustomRange(Date startDate, Date endDate) {
        if (startDate == null || endDate == null) {
            throw new InvoiceDashboardValidationException('Both custom reporting dates are required.');
        }
        if (endDate < startDate) {
            throw new InvoiceDashboardValidationException('The custom end date cannot be before the start date.');
        }
        return new InvoiceDashboardModel.DateRange(startDate, endDate);
    }
}
