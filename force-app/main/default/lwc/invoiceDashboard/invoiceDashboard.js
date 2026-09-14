import { LightningElement } from 'lwc';
import getDashboard from '@salesforce/apex/InvoiceDashboardController.getDashboard';
import getInvoiceLines from '@salesforce/apex/InvoiceDashboardController.getInvoiceLines';
import HAS_ACCESS from '@salesforce/customPermission/Invoice_Dashboard';

const MODE_YEARLY = 'YEARLY';
const MODE_MONTHLY = 'MONTHLY';
const MODE_WEEKLY = 'WEEKLY';
const MODE_CUSTOM = 'CUSTOM';

export default class InvoiceDashboard extends LightningElement {
    hasAccess = HAS_ACCESS;
    isLoading = false;
    errorMessage = '';
    validationMessage = '';
    mode = MODE_MONTHLY;
    selectedYear;
    selectedMonth;
    weekStart;
    startDate;
    endDate;
    accountId;
    summary = this.emptySummary();
    rows = [];

    modeOptions = [
        { label: 'Yearly', value: MODE_YEARLY },
        { label: 'Monthly', value: MODE_MONTHLY },
        { label: 'Weekly', value: MODE_WEEKLY },
        { label: 'Custom range', value: MODE_CUSTOM }
    ];

    connectedCallback() {
        const today = new Date();
        this.selectedYear = today.getFullYear();
        this.selectedMonth = today.getMonth() + 1;
        this.weekStart = this.mondayFor(today).toISOString().slice(0, 10);
    }

    get isYearly() {
        return this.mode === MODE_YEARLY;
    }

    get isMonthly() {
        return this.mode === MODE_MONTHLY;
    }

    get isWeekly() {
        return this.mode === MODE_WEEKLY;
    }

    get isCustom() {
        return this.mode === MODE_CUSTOM;
    }

    get hasRows() {
        return this.rows.length > 0;
    }

    get showEmptyState() {
        return !this.isLoading && !this.errorMessage && !this.hasRows;
    }

    get canExport() {
        return this.hasRows && !this.isLoading;
    }

    get isExportDisabled() {
        return !this.canExport;
    }

    handleModeChange(event) {
        this.mode = event.detail.value;
        this.validationMessage = '';
    }

    handleYearChange(event) {
        this.selectedYear = Number(event.target.value);
    }

    handleMonthChange(event) {
        this.selectedMonth = Number(event.target.value);
    }

    handleWeekChange(event) {
        this.weekStart = event.target.value;
    }

    handleStartDateChange(event) {
        this.startDate = event.target.value;
    }

    handleEndDateChange(event) {
        this.endDate = event.target.value;
    }

    handleAccountChange(event) {
        this.accountId = event.detail.recordId;
    }

    async handleApply() {
        this.validationMessage = this.validateFilter();
        if (this.validationMessage) {
            return;
        }

        this.isLoading = true;
        this.errorMessage = '';
        try {
            const result = await getDashboard({ filter: this.buildFilter() });
            this.summary = result?.summary || this.emptySummary();
            this.rows = (result?.rows || []).map((row) => ({
                ...row,
                isExpanded: false,
                iconName: 'utility:chevronright',
                isLineLoading: false,
                lineError: '',
                lines: []
            }));
        } catch (error) {
            this.errorMessage = this.reduceError(error, 'The invoice dashboard could not be loaded.');
            this.summary = this.emptySummary();
            this.rows = [];
        } finally {
            this.isLoading = false;
        }
    }

    async handleRowToggle(event) {
        const invoiceId = event.currentTarget.dataset.id;
        const row = this.rows.find((item) => item.id === invoiceId);
        if (!row) {
            return;
        }

        if (row.isExpanded) {
            this.updateRow(invoiceId, { isExpanded: false, iconName: 'utility:chevronright' });
            return;
        }
        if (row.lines.length > 0 || row.lineError) {
            this.updateRow(invoiceId, { isExpanded: true, iconName: 'utility:chevrondown' });
            return;
        }

        this.updateRow(invoiceId, { isExpanded: true, iconName: 'utility:chevrondown', isLineLoading: true, lineError: '' });
        try {
            const lines = await getInvoiceLines({ invoiceId });
            this.updateRow(invoiceId, { lines: lines || [], isLineLoading: false });
        } catch (error) {
            this.updateRow(invoiceId, {
                isLineLoading: false,
                lineError: this.reduceError(error, 'The invoice lines could not be loaded.')
            });
        }
    }

    handleExportCsv() {
        if (!this.canExport) {
            return;
        }

        try {
            const headers = ['Invoice number', 'Customer', 'Invoice date', 'Status', 'Due date', 'Amount excl. VAT', 'VAT', 'Amount incl. VAT', 'Outstanding'];
            const values = this.rows.map((row) => [
                row.invoiceNumber,
                row.accountName,
                row.invoicedDate,
                row.status,
                row.dueDate,
                row.amountExclVat,
                row.vat,
                row.amountInclVat,
                row.amountOutstanding
            ]);
            const csv = [headers, ...values].map((line) => line.map((value) => this.escapeCsv(value)).join(',')).join('\r\n');
            const link = this.template.querySelector('[data-id="csv-download"]');
            if (!link) {
                throw new Error('CSV download link is unavailable.');
            }
            link.href = `data:text/csv;charset=utf-8,${encodeURIComponent(csv)}`;
            link.click();
        } catch (error) {
            this.errorMessage = 'The CSV export could not be created. Please try again.';
        }
    }

    buildFilter() {
        return {
            mode: this.mode,
            year: this.selectedYear,
            month: this.isMonthly ? this.selectedMonth : null,
            weekStart: this.isWeekly ? this.weekStart : null,
            startDate: this.isCustom ? this.startDate : null,
            endDate: this.isCustom ? this.endDate : null,
            accountId: this.accountId || null
        };
    }

    validateFilter() {
        if (this.isCustom && (!this.startDate || !this.endDate)) {
            return 'Enter both custom reporting dates.';
        }
        if (this.isCustom && this.endDate < this.startDate) {
            return 'The custom end date cannot be before the start date.';
        }
        if (this.isWeekly && !this.weekStart) {
            return 'Select a reporting week.';
        }
        return '';
    }

    updateRow(invoiceId, changes) {
        this.rows = this.rows.map((row) => row.id === invoiceId ? { ...row, ...changes } : row);
    }

    emptySummary() {
        return {
            invoiceCount: 0,
            totalAmountExclVat: 0,
            totalVat: 0,
            totalAmountInclVat: 0,
            totalOutstandingAmount: 0,
            totalLineQuantity: 0,
            totalLineAmount: 0
        };
    }

    mondayFor(date) {
        const monday = new Date(date);
        const day = monday.getDay();
        const offset = day === 0 ? -6 : 1 - day;
        monday.setDate(monday.getDate() + offset);
        monday.setHours(0, 0, 0, 0);
        return monday;
    }

    escapeCsv(value) {
        const text = value === null || value === undefined ? '' : String(value);
        return `"${text.replace(/"/g, '""')}"`;
    }

    reduceError(error, fallback) {
        return error?.body?.message || error?.message || fallback;
    }
}
