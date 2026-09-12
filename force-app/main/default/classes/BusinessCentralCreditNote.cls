public with sharing class BusinessCentralCreditNote {

    public String documentType;
	public String documentNumber;
	public String salesforceId;
	public Date postingDate;
	public String sellToCustomerNo;
	public String billToCustomerNumber;
	public String cpAccountCode;
	public String frequency;
	public String externalDocumentNumber;
	public String appliesToDocumentType;
	public String appliesToDocumentNumber;
	public Date dueDate;
	public Decimal vat;
	public Decimal amountInclVAT;
	public Integer lineCount;
	public String currencyCode;
	public List<SalesLines> salesLines = new List<SalesLines>();

	public class SalesLines {
		public String number_X;
		public String salesforceId;
		public String productDescription;
		public Decimal quantity;
		public Decimal unitPrice;
		public Date shipmentDate;
		public String externalDocumentNumber;
		public String sellToCustomerNumber;
		public String orderNumber;
	}
}