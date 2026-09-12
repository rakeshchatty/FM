public without sharing class BusinessCentralInvoice {

	public String documentNumber;
	public String salesforceId;
	public Date postingDate;
	public String sellToCustomerNo;
	public String cpAccountCode;
	public String frequency;
	public String externalDocumentNumber;
	public Date dueDate;
	public Decimal vat;
	public Decimal amountInclVAT;
	public String paymentMethodCode;
	public Integer lineCount;
	public String currencyCode;
	public List<FMsalesInvoiceLines> fMsalesInvoiceLines = new List<FMsalesInvoiceLines>();

	public class FMsalesInvoiceLines {
		public String number_X;
		public String salesforceId;
		public String productDescription;
		public Decimal quantity;
		public Decimal unitPrice;
		public Date shipmentDate;
		public String externalDocumentNumber;
		public String sellToCustomerNumber;
		public String orderNumber;
		public String paymentId;
	}

	public BusinessCentralInvoice() {}

	public BusinessCentralInvoice(BusinessCentralInvoice clone) {
		this.documentNumber = clone.documentNumber;
		this.salesforceId = clone.salesforceId;
		this.postingDate = clone.postingDate;
		this.sellToCustomerNo = clone.sellToCustomerNo;
		this.cpAccountCode = clone.cpAccountCode;
		this.frequency = clone.frequency;
		this.externalDocumentNumber = clone.externalDocumentNumber;
		this.dueDate = clone.dueDate;
		this.vat = clone.vat;
		this.amountInclVAT = clone.amountInclVAT;
		this.paymentMethodCode = clone.paymentMethodCode;
		this.lineCount = clone.lineCount;
		this.currencyCode = clone.currencyCode;
	}
}