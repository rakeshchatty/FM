import { createElement } from 'lwc';
import InvoiceDashboard from 'c/invoiceDashboard';
import getDashboard from '@salesforce/apex/InvoiceDashboardController.getDashboard';
import getInvoiceLines from '@salesforce/apex/InvoiceDashboardController.getInvoiceLines';

jest.mock('@salesforce/customPermission/Invoice_Dashboard', () => ({ default: true }), { virtual: true });
jest.mock('@salesforce/apex/InvoiceDashboardController.getDashboard', () => ({ default: jest.fn() }), { virtual: true });
jest.mock('@salesforce/apex/InvoiceDashboardController.getInvoiceLines', () => ({ default: jest.fn() }), { virtual: true });

describe('c-invoice-dashboard', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
        jest.clearAllMocks();
    });

    it('initializes the current month and renders empty summaries', () => {
        const element = createElement('c-invoice-dashboard', { is: InvoiceDashboard });
        document.body.appendChild(element);

        expect(element.shadowRoot.querySelector('lightning-card')).not.toBeNull();
        expect(element.shadowRoot.querySelector('lightning-combobox').value).toBe('MONTHLY');
    });

    it('loads filtered results and supports lazy invoice lines', async () => {
        getDashboard.mockResolvedValue({
            summary: { invoiceCount: 1, totalAmountExclVat: 10, totalVat: 2, totalAmountInclVat: 12, totalOutstandingAmount: 12 },
            rows: [{ id: 'a001', invoiceNumber: 'INV-1', accountName: 'Customer', invoicedDate: '2026-09-01', status: 'Open', dueDate: '2026-09-30', amountExclVat: 10, amountInclVat: 12, amountOutstanding: 12 }]
        });
        getInvoiceLines.mockResolvedValue([{ id: 'l001', productName: 'Product', quantity: 1, unitPrice: 10, totalPrice: 10 }]);
        const element = createElement('c-invoice-dashboard', { is: InvoiceDashboard });
        document.body.appendChild(element);

        element.shadowRoot.querySelector('lightning-button').click();
        await Promise.resolve();
        await Promise.resolve();

        expect(getDashboard).toHaveBeenCalled();
        const expandButton = element.shadowRoot.querySelector('lightning-button-icon');
        expandButton.click();
        await Promise.resolve();
        await Promise.resolve();
        expect(getInvoiceLines).toHaveBeenCalledWith({ invoiceId: 'a001' });
    });

    it('prevents reversed custom ranges from calling Apex', async () => {
        const element = createElement('c-invoice-dashboard', { is: InvoiceDashboard });
        document.body.appendChild(element);
        const modeInput = element.shadowRoot.querySelector('lightning-combobox');
        modeInput.dispatchEvent(new CustomEvent('change', { detail: { value: 'CUSTOM' } }));
        await Promise.resolve();
        const dateInputs = element.shadowRoot.querySelectorAll('lightning-input');
        dateInputs[0].value = '2026-09-15';
        dateInputs[1].value = '2026-09-14';
        dateInputs[0].dispatchEvent(new CustomEvent('change'));
        dateInputs[1].dispatchEvent(new CustomEvent('change'));

        element.shadowRoot.querySelector('lightning-button').click();
        await Promise.resolve();

        expect(getDashboard).not.toHaveBeenCalled();
        expect(element.shadowRoot.textContent).toContain('cannot be before');
    });
});
