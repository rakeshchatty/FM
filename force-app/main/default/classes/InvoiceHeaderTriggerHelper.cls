public class InvoiceHeaderTriggerHelper {

    public static void populateAmounts(List < Invoice_Header__c > headers) {
        List < Invoice_Header__c > headersWithLinesList = [SELECT Id, Account__r.VAT_Exempt__c, AmountExclVAT__c, VAT__c, AllocAmount__c, AmountOutstanding__c, Payment_Reference__c, OrderLookUp__r.PaymentReference__c, OrderLookUp__r.CreditCard_Payment__c, Generate_Payment__c, (SELECT Id, Amount__c, Vat__c FROM Invoice_Lines__r) FROM Invoice_Header__c WHERE Id IN: headers];
        for (Invoice_Header__c h: headersWithLinesList) {
            for (Invoice_Header__c original: headers) {
                if (h.Id == original.Id) {
                    original.AmountExclVAT__c = 0;
                    for (Invoice_Line__c l: h.Invoice_Lines__r) {
                        original.AmountExclVAT__c += l.Amount__c;
                    }
                    original.VAT__c = h.Account__r.VAT_Exempt__c ? 0 : (original.AmountExclVAT__c * TheVat__c.getInstance().Value__c).setScale(2, RoundingMode.HALF_UP);
                    original.AmountOutstanding__c = original.AmountExclVAT__c + original.VAT__c - original.AllocAmount__c;
                    original.AmountOutstanding__c.setscale(2);
                    original.Outstanding__c = original.AmountOutstanding__c > 0 ? original.Account__c : null;
                    //Joao [JIRA 1612] - added to set generate payment and payment reference
                    //Fix jira 1677/1673
                    if (h.OrderLookUp__r.CreditCard_Payment__c)
                    {
                        original.Generate_Payment__c = true;
                        original.Payment_Reference__c = h.OrderLookUp__r.PaymentReference__c;
                    }
                }
            }
        }
    }

    public static void createSageExtract(List <Invoice_Header__c> invoicesReadOnly) {
        List <Invoice_Header__c> invoices = [SELECT Id, (SELECT Product__r.Nl_accode__c, Product_AccCode__c, Amount__c, VAT__c, Invoice_HeaderId__c, Invoice_HeaderId__r.DueDate__c FROM Invoice_Lines__r) FROM Invoice_Header__c WHERE Id IN :invoicesReadOnly];

        List <Invoice_Line__c> invoiceLines = new List <Invoice_Line__c>();
        List <SageExtract__c> sageLines = new List <SageExtract__c>();
        for (Invoice_Header__c invoice : invoices) {
            for (Invoice_Line__c invoiceLine : invoice.Invoice_Lines__r) {
                sageLines.addAll(Sage.createLines(invoiceLine));
                invoiceLines.add(invoiceLine);
            }

            invoice.SageExtractCreated__c = true;
            invoice.Ready_to_Email__c = true;
        }

        if (!sageLines.isEmpty()) {
            Database.SaveResult[] results1 = Database.update(invoiceLines, false);
            LogRegister.createLogsUpsert(results1, invoiceLines, 'InvoiceHeaderTriggerHelper update invoiceLines', 'update', 'Invoice_Line__c', 'Invoice_Header__c');

            Database.SaveResult[] results2 = Database.insert(sageLines, false);
            LogRegister.createLogsUpsert(results2, sageLines, 'InvoiceHeaderTriggerHelper insert sageLines', 'insert', 'SageExtract__c', 'Invoice_Line__c');
        }

        Database.SaveResult[] results = Database.update(invoices, false);
        LogRegister.createLogsUpsert(results, invoices, 'InvoiceHeaderTriggerHelper update invoices', 'update', 'Invoice_Header__c', 'Account__c');
    }

    /* Bruno - 14-01-2019 - 1215 - Create Payments for Invoices paid by Card on CP */
    public static void payInvoices(List < Invoice_Header__c > headers) {
        system.debug(headers);
        system.debug('Entrou payInvoices');
        Set<Id> accountIds = new Set<Id>();
        List<PaymentAllocation__c> paymentsToInsert = new List<PaymentAllocation__c>();
        for (Invoice_Header__c h : headers) {
            accountIds.add(h.Account__c);
        }
        for (Bank_Statement__c bs : [SELECT Id, Unallocated_Amount__c, Account__c, CP_Transactional_Info__c FROM Bank_Statement__c WHERE Account__c IN :accountIds AND Transaction_Type__c = 'Credit Card' AND fromCustomerPortal__c = true and Unallocated_Amount__c > 0]) {
            for (Invoice_Header__c h : headers) {
                if (String.isNotBlank(bs.CP_Transactional_Info__c) && bs.CP_Transactional_Info__c.length() >= 27)
                {
                    String paymentReference = bs.CP_Transactional_Info__c.substring(0, 27);
                    system.debug('bs --> '+bs);
                    System.debug('BS Payment Reference: '+paymentReference+'  BS AccountId: '+bs.Account__c);
                    System.debug('Inv Payment Reference: '+h.Payment_Reference__c+'  Inv AccountId: '+h.Account__c);

                    if (bs.Account__c == h.Account__c && paymentReference == h.Payment_Reference__c && h.AmountOutstanding__c > 0) {
                        system.debug('Entrou payInvoices if clause');
                        PaymentAllocation__c p = new PaymentAllocation__c(
                            Account__c = bs.Account__c,
                            BankstatementId__c = bs.Id,
                            InvoiceId__c = h.Id,
                            AllocatedAmount__c = bs.Unallocated_Amount__c,
                            IsFromCPCard__c = true
                        );
                        paymentsToInsert.add(p);
                    }
                }
            }
        }
        try {
            if (paymentsToInsert.size() > 0) {
                system.debug(paymentsToInsert);
                insert paymentsToInsert;
            }
        }
        catch (Exception e) {
            system.debug(e.getMessage());
            throw new GeneralException(e.getMessage());
        }
    }

    /* Bruno - 04.02.2019 -> 978 */
    public static void processCreditNotes(List < Invoice_Header__c > headers) {
        List < Bank_Statement__c > bsToCreate = new List < Bank_Statement__c > ();
        for (Invoice_Header__c h: [SELECT Id, AmountExclVAT__c, VAT__c, InvoiceNo__c, Account__c, Account__r.CP_Account_Code__c FROM Invoice_Header__c WHERE ID IN: headers]) {
            system.debug(h);
            Bank_Statement__c b = new Bank_Statement__c();
            b.Document_Name__c = h.InvoiceNo__c + ' CREDIT NOTE';
            b.Entry_Date__c = System.today();
            b.Transaction_Details__c = h.InvoiceNo__c + ' CREDIT';
            b.Transaction_Type__c = 'Credit Note';
            b.Payment_Amount__c = 0;
            b.Receipt_Amount__c = 0;
            b.Customer_Reference__c = h.Account__r.CP_Account_Code__c;
            b.Account__c = h.Account__c;
            b.Unallocated_Amount__c = (h.AmountExclVAT__c + h.Vat__c) * (-1);
            system.debug('AmountExclVAT__c --> '+h.AmountExclVAT__c);
            system.debug('Unallocated_Amount__c 1 --> '+b.Unallocated_Amount__c);
            b.Credit_Note_Invoice__c = h.Id;
            bsToCreate.add(b);
        }
        system.debug(bsToCreate);
        insert bsToCreate;

    }
}