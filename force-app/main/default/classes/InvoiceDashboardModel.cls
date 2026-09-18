/** DTO contract for the invoice dashboard. */
public class InvoiceDashboardModel {

    /** Filter input supplied by the dashboard. */
    public class Filter {
        /** Filter mode. */
        @AuraEnabled public String mode { get; set; }
        /** Selected year. */
        @AuraEnabled public Integer year { get; set; }
        /** Selected month. */
        @AuraEnabled public Integer month { get; set; }
        /** Monday date for the selected week. */
        @AuraEnabled public Date weekStart { get; set; }
        /** Inclusive custom start date. */
        @AuraEnabled public Date startDate { get; set; }
        /** Inclusive custom end date. */
        @AuraEnabled public Date endDate { get; set; }
        /** Optional customer account. */
        @AuraEnabled public Id accountId { get; set; }

        /** Initializes filter input. */
        public Filter() {
            mode = null;
        }
    }

    /** Inclusive date range used by the query utility. */
    public class DateRange {
        /** Inclusive start date. */
        @AuraEnabled public Date startDate { get; set; }
        /** Inclusive end date. */
        @AuraEnabled public Date endDate { get; set; }

        /** Creates a date range.
         * @param  startDate inclusive range start
         * @param  endDate inclusive range end
         */
        public DateRange(Date startDate, Date endDate) {
            this.startDate = startDate;
            this.endDate = endDate;
        }
    }

    /** Dashboard summary values. */
    public class Summary {
        /** Number of invoice headers. */
        @AuraEnabled public Integer invoiceCount { get; set; }
        /** Total amount excluding VAT. */
        @AuraEnabled public Decimal totalAmountExclVat { get; set; }
        /** Total VAT. */
        @AuraEnabled public Decimal totalVat { get; set; }
        /** Total amount including VAT. */
        @AuraEnabled public Decimal totalAmountInclVat { get; set; }
        /** Total outstanding amount. */
        @AuraEnabled public Decimal totalOutstandingAmount { get; set; }
        /** Total child-line quantity. */
        @AuraEnabled public Decimal totalLineQuantity { get; set; }
        /** Total child-line amount. */
        @AuraEnabled public Decimal totalLineAmount { get; set; }

        /** Initializes zero-valued summary fields. */
        public Summary() {
            invoiceCount = 0;
            totalAmountExclVat = 0;
            totalVat = 0;
            totalAmountInclVat = 0;
            totalOutstandingAmount = 0;
            totalLineQuantity = 0;
            totalLineAmount = 0;
        }
    }

    /** Complete dashboard response. */
    public class DashboardResult {
        /** Summary values. */
        @AuraEnabled public Summary summary { get; set; }
        /** Filtered invoice rows. */
        @AuraEnabled public List<InvoiceRow> rows { get; set; }

        /** Initializes an empty dashboard response. */
        public DashboardResult() {
            summary = new Summary();
            rows = new List<InvoiceRow>();
        }
    }

    /** Invoice row displayed by the dashboard. */
    public class InvoiceRow {
        /** Invoice record ID. */
        @AuraEnabled public Id id { get; set; }
        /** Invoice number. */
        @AuraEnabled public String invoiceNumber { get; set; }
        /** Customer account ID. */
        @AuraEnabled public Id accountId { get; set; }
        /** Customer account name. */
        @AuraEnabled public String accountName { get; set; }
        /** Invoice date. */
        @AuraEnabled public Date invoicedDate { get; set; }
        /** Billing period start. */
        @AuraEnabled public Date periodStart { get; set; }
        /** Billing period end. */
        @AuraEnabled public Date periodEnd { get; set; }
        /** Invoice status. */
        @AuraEnabled public String status { get; set; }
        /** Payment due date. */
        @AuraEnabled public Date dueDate { get; set; }
        /** Amount excluding VAT. */
        @AuraEnabled public Decimal amountExclVat { get; set; }
        /** VAT amount. */
        @AuraEnabled public Decimal vat { get; set; }
        /** Amount including VAT. */
        @AuraEnabled public Decimal amountInclVat { get; set; }
        /** Outstanding amount. */
        @AuraEnabled public Decimal amountOutstanding { get; set; }

        /** Initializes a row. */
        public InvoiceRow() {
            id = null;
        }
    }

    /** Invoice line detail displayed under an invoice row. */
    public virtual class InvoiceLine {
        /** Invoice line record ID. */
        @AuraEnabled public Id id { get; set; }
        /** Product name. */
        @AuraEnabled public String productName { get; set; }
        /** Line description. */
        @AuraEnabled public String description { get; set; }
        /** Line quantity. */
        @AuraEnabled public Decimal quantity { get; set; }
        /** Unit price. */
        @AuraEnabled public Decimal unitPrice { get; set; }
        /** Total line price. */
        @AuraEnabled public Decimal totalPrice { get; set; }
        /** Line VAT amount. */
        @AuraEnabled public Decimal vat { get; set; }

        /** Initializes a line. */
        public InvoiceLine() {
            id = null;
        }
    }
}
