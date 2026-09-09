/** 
(c) 2018 
@date 08.2018
@author Bruno Mendes 

@description JIRA 899 - As a User, I want to manage Cash Collection and Payments Allocation in SF 


*/
public with sharing class OnBankStatementHelper {

    static boolean flag = false;

    // Trigger entry point   
    public static void entry(
        System.TriggerOperation triggerEvent,
        List < Bank_Statement__c > newList,
        Map < Id, Bank_Statement__c > newMap,
        List < Bank_Statement__c > oldList,
        Map < Id, Bank_Statement__c > oldMap
    ) {
        // Dispatch trigger event to corresponding methods 
        system.debug(triggerEvent);
        
        switch on triggerEvent {
            when BEFORE_DELETE{         
                for(Bank_Statement__c bs: oldList){
                    Id userProfileId = userinfo.getProfileId();
                    String userProfileName = [SELECT ID, Name from Profile Where Id = : userProfileId].Name;
                    if(userProfileName != 'System Administrator')
                    {
                        bs.addError('You cannot delete this record because this BankStatement because you dont have permission');
                    }
                }                
            }
            when BEFORE_INSERT{
                for (Bank_Statement__c bs: newList) {
                    if (bs.Is_New__c != true){
                        bs.Is_New__c = true;
                    }
                    if (bs.Is_New__c = true && bs.Credit_Note_Invoice__c == null){
                        bs.Unallocated_Amount__c = bs.TransactionAmount__c;
                    }
                    
                }
            }
            when AFTER_INSERT {
                //Jira 1034 - Direct Debit Payments
                /*for (Bank_Statement__c bs : newList) {
                    if (bs.Account__c != null)
                }*/


                // When a bank statement is created, the value on account is recalculated with no conditions
                Set < Id > bsAccounts = new Set < Id > ();
                Map < Id, List < Bank_Statement__c >> bsAccountsToGetInvoicesMap = new Map < Id, List < Bank_Statement__c >> ();
                Map < Id, List < Bank_Statement__c >> BankStatementsPaidByCard = new Map < Id, List < Bank_Statement__c >> ();
                Map < Id, Bank_Statement__c >  BankStatementsPaidFromCP = new Map < Id, Bank_Statement__c >();
                
                List<Bank_Statement__c> bsToCreatePaymentsCreditNotes = new List<Bank_Statement__c>();
                List<Bank_Statement__c> bsToCreateSageExtracts = new List<Bank_Statement__c>();
                List<Bank_Statement__c> bsToCreateFeeSageExtracts = new List<Bank_Statement__c>();
                List<Bank_Statement__c> bsDirectDebitToUpdate = new List<Bank_Statement__c>();        
                
                Id RecordTypeIdBankStatement = Schema.SObjectType.Bank_Statement__c.getRecordTypeInfosByName().get('Bank Statement').getRecordTypeId();
                Id RecordTypeIdFee = Schema.SObjectType.Bank_Statement__c.getRecordTypeInfosByName().get('Fee').getRecordTypeId();
                
                for (Bank_Statement__c bs: newList) {
                    system.debug(bs);
                    /* Bruno - 30-01-2019 -> 1215 - added && bs.CP_Transactional_Info__c == null to avoid creating the Sage Extract before it's supposed to for CP Card payments */
                    /* ( 29-03-2019 ) jira 1484 -> Removed bs.CP_Transactional_Info__c == null;*/
                    if (bs.Transaction_Type__c != 'Direct Debit' && bs.Transaction_Type__c != 'Credit Note' && bs.fromCustomerPortal__c == false && bs.RecordTypeId == RecordTypeIdBankStatement /* Bruno - 04.02.2019 -> 978 */) {
                        bsToCreateSageExtracts.add(bs);
                    }
                    if (bs.RecordTypeId == RecordTypeIdFee /* Nuno - 18.07.2019 -> 1603 */) {
                        bsToCreateFeeSageExtracts.add(bs);
                    }
                    bsAccounts.add(bs.Account__c);
                    system.debug(bs.Account__c);
                    //Pays from oldest Invoice to newst while Unallocated_Amount__c > 0
                    if (bs.Unallocated_Amount__c > 0 && bs.Account__c != null && bs.CP_Transactional_Info__c == null && bs.Transaction_Type__c != 'Direct Debit' && bs.Transaction_Type__c != 'Credit Note') {
                        system.debug('This bank statement pays from oldest Invoice to newst while Unallocated_Amount__c > 0: ' + bs.Id);
                        if (bsAccountsToGetInvoicesMap.containsKey(bs.Account__c)) {
                            bsAccountsToGetInvoicesMap.get(bs.Account__c).add(bs); 
                           
                        } else {
                            bsAccountsToGetInvoicesMap.put(bs.Account__c, new List < Bank_Statement__c > {bs});
                        }
                    }
                    /* 
                        Bruno   06-03-2019 - JIRA 1389 -> 1st version only supports paymants for account balance (oldest to newset invoices)
                        Joao    24/04/2019 - JIRA 1389 -> add logic to pay specific invoices
                        Joao    09/05/2019 - JIRA 1389 -> removed '&& bs.Customer_Reference__c == null' from the if condition
                    */
                    if (bs.CP_Transactional_Info__c != null)
                    {
                        if(bs.Document_name__c.contains('Charge for ['))
                        {
                            system.debug('This bank statement pays spefific invoices, specified in the Name field, separated by comas: ' + bs.Id);
                            BankStatementsPaidFromCP.put(bs.Id, bs);
                        }
                        else if (bs.Document_name__c.contains('Charge for all'))
                        {
                            system.debug('This bank statement pays from oldest Invoice to newst while Unallocated_Amount__c > 0: ' + bs.Id);
                            if (bsAccountsToGetInvoicesMap.containsKey(bs.Account__c)) {
                                bsAccountsToGetInvoicesMap.get(bs.Account__c).add(bs);
                            } else {
                                bsAccountsToGetInvoicesMap.put(bs.Account__c, new List < Bank_Statement__c > {bs});
                            }
                        }
                    }

                    /*
                        Joao    23/04/2019 JIRA 1215 -> logic is in invoice header helper, payInvoices method
                    */
                    //Payment from Credit Card that should pay a specific order/invoice
                    /*if(bs.CP_Transactional_Info__c != null && bs.Customer_Reference__c != null)
                    {
                        system.debug('This bank statement is to pay a spefific order/invoice, paid through CP: ' + bs.Id);
                        if (BankStatementsPaidByCard.containsKey(bs.Account__c)) {
                            BankStatementsPaidByCard.get(bs.Account__c).add(bs); 
                        } else {
                            BankStatementsPaidByCard.put(bs.Account__c, new List < Bank_Statement__c > {bs});
                        }
                    }*/

                    /* Bruno - 04.02.2019 -> 978 */
                    if (bs.Transaction_Type__c == 'Credit Note') {
                        // create payment allocation and make sure it doesn't break with the update in the end
                        bsToCreatePaymentsCreditNotes.add(bs);
                    }
                }
                system.debug(bsAccountsToGetInvoicesMap);
                system.debug(bsAccountsToGetInvoicesMap.size());

                //Deal with payments
                if (bsAccountsToGetInvoicesMap.keySet().size() > 0) {
                    getInvoiceHeadersForBSAccounts(bsAccountsToGetInvoicesMap);
                }
                /*if (BankStatementsPaidByCard.keySet().size() > 0) {
                    //payCreditCardInvoices(BankStatementsPaidByCard);
                }*/
                if (BankStatementsPaidFromCP.size() > 0) {
                    paySpecifiedInvoices(BankStatementsPaidFromCP);
                }
                if (bsToCreatePaymentsCreditNotes.size() > 0) {
                    createPaymentsCreditNotes(bsToCreatePaymentsCreditNotes);
                }

                //Create Sage Extracts
                if (bsToCreateSageExtracts.size() > 0) {
                    CreateSageExtract(bsToCreateSageExtracts);
                }
                
                //Create Fee Sage Extracts
                if (bsToCreateFeeSageExtracts.size() > 0) {
                    CreateFeeSageExtract(bsToCreateFeeSageExtracts);
                }
                
                update bsDirectDebitToUpdate;
            }
            when AFTER_UPDATE {
              // Every time a bank statement unallocated amount changes, the unallocated payments field on the account must be updated    
                system.debug('flag - '+flag);
                if (!flag) {
                    
                    List<Bank_Statement__c> cancelledBankStatement = new List<Bank_Statement__c>();        
                    flag = true;
                    Set<Id> bsIdsDD = new Set<Id>();
                    
                    for (Bank_Statement__c bs: newList) {
                        Bank_Statement__c oldBs = oldMap.get(bs.Id);
                        Bank_Statement__c newBs = newMap.get(bs.Id);
                        system.debug('bs.Cancelled__c'+bs.Cancelled__c +' '+ bs.MarkedForSage__c +' '+ bs.Transaction_Type__c);
                        if(oldBs.Cancelled__c == false && newBs.Cancelled__c == true){
                            cancelledBankStatement.add(bs);
                        }
                        if (bs.Transaction_Type__c == 'Direct Debit' && bs.MarkedForSage__c == true && bs.Cancelled__c == false && bs.fromCustomerPortal__c == false && bs.IsDirectDebit__c == true && bs.Sage_Extract_Created__c == false) {
                            bsIdsDD.add(bs.Id);
                        }
                    }
                    OnBankStatementHelper.cancelBankStatements(cancelledBankStatement); 
                    if (bsIdsDD.size() > 0) {
                        List < Bank_Statement__c > bsDDList = new List<Bank_Statement__c>();
                        for (Bank_Statement__c bs: [SELECT Id, Name, /*AllocAmount__c*/ (SELECT AllocatedAmount__c FROM PaymentAllocations__r), Payment_Amount__c, Receipt_Amount__c, Ledger_Balance__c FROM Bank_Statement__c WHERE Id IN: bsIdsDD]) {
                            Decimal amount = 0;
                            for (PaymentAllocation__c pa : bs.PaymentAllocations__r) {
                                amount += pa.AllocatedAmount__c;
                            }
                            system.debug(amount);
                            bs.Payment_Amount__c = amount;
                            bs.Receipt_Amount__c = amount;
                            bs.Ledger_Balance__c = amount;
                            bsDDList.add(bs);
                        }
                        system.debug(bsDDList);
                        update bsDDList;
                        CreateSageExtract(bsDDList);
                    } 
                }
                //jira 1681 -> Fix
                boolean flagPayment = false;
                for (Bank_Statement__c bs: newList) {
                    if(bs.Account__c != null){
                        flagPayment = false;
                    }
                }
                if(!flagPayment){
                    Map < Id, List < Bank_Statement__c >> bsAccountsToGetInvoicesMap = new Map < Id, List < Bank_Statement__c >> ();
                    
                    for (Bank_Statement__c bs: newList) {
                        Bank_Statement__c oldBs = oldMap.get(bs.Id);
                        Bank_Statement__c newBs = newMap.get(bs.Id);
                        system.debug('bs.Unallocated_Amount__c -- '+bs.Unallocated_Amount__c + ' bs.Account__c --> '+ bs.Account__c + ' oldBs.Account__c --> ' +oldBs.Account__c);
                        if (bs.Unallocated_Amount__c > 0 && bs.Account__c != oldBs.Account__c && bs.Account__c != null && bs.Transaction_Type__c != 'Direct Debit' && bs.Transaction_Type__c != 'Credit Note') { // && bs.Account__c != oldBs.Account__c
                            system.debug('JJ'+bs.Account__c);
                            
                            if (bsAccountsToGetInvoicesMap.containsKey(bs.Account__c)) {
                                bsAccountsToGetInvoicesMap.get(bs.Account__c).add(bs);
                            } else {
                                bsAccountsToGetInvoicesMap.put(bs.Account__c, new List < Bank_Statement__c > {
                                    bs
                                        });
                            }
                        }
                    }
                    
                    if (bsAccountsToGetInvoicesMap.keySet().size() > 0) {
                        getInvoiceHeadersForBSAccounts(bsAccountsToGetInvoicesMap);
                    }
                }     
            }
        }
    }

    private static void paySpecifiedInvoices(Map < Id, Bank_Statement__c > BankStatementsPaidFromCP) 
    {
        //Split the list of invoice Ids from the Document Name field to query on next line
        Map<Id, List<String>> invoiceIDsByBankStatementID =  new Map<Id, List<String>> ();
        Set<Id> invoiceIDs = new Set<Id>();
        System.debug('Invoices that came from CP to pay specific invoices: ' + BankStatementsPaidFromCP);
        for(Bank_Statement__c bankStatementToPay :BankStatementsPaidFromCP.values())
        {
            //Document Name filed format 'Charge for [invID-1, invID-2, .... , invID-N]'
            String invoiceIDsForBankStatement = bankStatementToPay.Document_name__c.substring(bankStatementToPay.Document_name__c.indexOf('[')+1, bankStatementToPay.Document_name__c.indexOf(']'));
            invoiceIDsForBankStatement = invoiceIDsForBankStatement.replaceAll('(\\s+)', '');
            System.debug('Invoice IDs splitted whithout spaces: ' + invoiceIDsForBankStatement.split(','));
            invoiceIDsByBankStatementID.put(bankStatementToPay.Id, invoiceIDsForBankStatement.split(','));

            List<String> IDsAsString = new List<String>(invoiceIDsForBankStatement.split(','));
            List<Id> IDsAsID = (List<Id>) IDsAsString;
            invoiceIDs.addAll(new Set<Id>(IDsAsID));
        }
        system.debug('Number of invoices to query: ' + invoiceIDs.size());
        Map<Id, Invoice_Header__c> InvoicesToPay = new Map<Id, Invoice_Header__c>( [SELECT Id, AmountOutstanding__c FROM Invoice_Header__c WHERE ID IN :invoiceIDs] );
        system.debug('Number of invoices queried: ' + InvoicesToPay.size());

        List<PaymentAllocation__c> paymentsForInvoices = new List<PaymentAllocation__c>();
        List<PaymentAllocation__c> bankStatementsToUpdate = new List<PaymentAllocation__c>();
        for(Id bankStatementID :BankStatementsPaidFromCP.keySet())
        {
            Bank_Statement__c bankStatementToPay = BankStatementsPaidFromCP.get(bankStatementID);
            for(String invoiceToPayID :invoiceIDsByBankStatementID.get(bankStatementID))
            {
                Invoice_Header__c invoiceToPay = InvoicesToPay.get(invoiceToPayID);
                PaymentAllocation__c payment = new PaymentAllocation__c();
                payment.InvoiceId__c = invoiceToPay.Id;
                payment.Account__c = bankStatementToPay.Account__c;
                payment.BankstatementId__c = bankStatementToPay.Id;
                payment.AllocatedAmount__c = invoiceToPay.AmountOutstanding__c.setscale(2);
                paymentsForInvoices.add(payment);
            }
        }

        if(paymentsForInvoices.size() > 0)
        {
            Database.SaveResult[] paymentsSaveResult = Database.insert(paymentsForInvoices, false);
            LogRegister.createLogsUpsert(paymentsSaveResult, paymentsForInvoices, 'Pay CP specific invoices', 'Insert', 'PaymentAllocation__c', '');
        }
    }

    private static void getInvoiceHeadersForBSAccounts(Map < Id, List < Bank_Statement__c >> bsAccountsMap) {
        Map < Id, Account > accountsWithInvoices;
        system.debug(bsAccountsMap.keySet());
        system.debug(bsAccountsMap.values());
        system.debug(bsAccountsMap.keySet().size());
        /* Bruno - 04.02.2019 -> 1334 - Beth asked to remove the ToPublish filter */
        /*if (Test.IsRunningTest()) {
            accountsWithInvoices = new Map < Id, Account > ([SELECT Id, (SELECT Id, AmountOutstanding__c, Status__c FROM Invoice_Headers__r WHERE AmountOutstanding__c > 0 AND ToPublish__c = false AND Query__c = false AND Status__c != 'Paid'
            ORDER BY CreatedDate ASC) FROM Account WHERE Id IN: bsAccountsMap.keySet() and Id IN(SELECT Account__c FROM Invoice_Header__c WHERE AmountOutstanding__c > 0 AND ToPublish__c = false AND Query__c = false AND Status__c != 'Paid')]);
        
        }
        else {
            accountsWithInvoices = new Map < Id, Account > ([SELECT Id, (SELECT Id, AmountOutstanding__c, Status__c FROM Invoice_Headers__r WHERE AmountOutstanding__c > 0 AND ToPublish__c = true AND Query__c = false AND Status__c != 'Paid'
            ORDER BY CreatedDate ASC) FROM Account WHERE Id IN: bsAccountsMap.keySet() and Id IN(SELECT Account__c FROM Invoice_Header__c WHERE AmountOutstanding__c > 0 AND ToPublish__c = true AND Query__c = false AND Status__c != 'Paid')]);
        }*/

        /* Bruno - 08.03.2019 -> Jira 1436 - changed query to make it selective and avoid query limits exceptions */
        accountsWithInvoices = new Map < Id, Account > ([SELECT Id, (SELECT Id, AmountOutstanding__c, Status__c FROM Invoice_Headers__r WHERE AmountOutstanding__c > 0 AND Query__c = false AND Status__c != 'Paid'
            ORDER BY CreatedDate ASC) FROM Account WHERE Id IN: bsAccountsMap.keySet() AND RecordType.DeveloperName = 'Account' /*and Id IN(SELECT Account__c FROM Invoice_Header__c WHERE AmountOutstanding__c > 0 AND Query__c = false AND Status__c != 'Paid') ---- Changed the query on 08-03-2019 to make it selective */]);
        
        system.debug(accountsWithInvoices);
        List < PaymentAllocation__c > paymentsToInsert = new List < PaymentAllocation__c > ();
        Map < Id, Invoice_Header__c > invoicesToUpdate = new Map < Id, Invoice_Header__c > ();
        Map < Bank_Statement__c, Decimal > bsToUpdate = new Map < Bank_Statement__c, Decimal > ();

        /* Joao - 06/05/2019 -> JIRA 1386 - need to remove "AND CP_Transactional_Info__c = null" from the query*/
        Map<Id, Bank_Statement__c> bankstatements = new Map<Id,Bank_Statement__c>([SELECT Id, Unallocated_Amount__c FROM Bank_Statement__c WHERE Account__c IN :bsAccountsMap.keySet() /*AND CP_Transactional_Info__c = null*/]);

        for (Account a: accountsWithInvoices.values()) {
            if (a.Invoice_Headers__r.size() == 0) {
                continue;
            }
                system.debug(a);
            for (Bank_Statement__c bs: bsAccountsMap.get(a.Id)) {
                Bank_Statement__c updateableBS = bankstatements.get(bs.Id);
                system.debug(updateableBS);
                for (Invoice_Header__c ih: a.Invoice_Headers__r) {
                    //system.debug(updateableBS.Unallocated_Amount__c);
                    if (ih.Status__c == 'Paid' || ih.Status__c == 'Query') {
                        continue;
                    }
                    system.debug('BS Unallocated Amount: ' + updateableBS.Unallocated_Amount__c + '\ninvoice Amount Outstanding: ' + ih.AmountOutstanding__c + '\nBS Unalocated Amount: ' + updateableBS.Unallocated_Amount__c);
                    if (updateableBS.Unallocated_Amount__c < ih.AmountOutstanding__c && updateableBS.Unallocated_Amount__c > 0) {
                        PaymentAllocation__c pa = new PaymentAllocation__c();
                        pa.InvoiceId__c = ih.Id;
                        pa.BankstatementId__c = updateableBS.Id;
                        pa.AllocatedAmount__c = updateableBS.Unallocated_Amount__c;
                        pa.Account__c = a.Id;
                        paymentsToInsert.add(pa);
                        ih.AmountOutstanding__c = ih.AmountOutstanding__c.setscale(2) - updateableBS.Unallocated_Amount__c;
                        invoicesToUpdate.put(ih.Id, ih);
                        updateableBS.Unallocated_Amount__c = 0;
                        bsToUpdate.put(updateableBS, 0);
                        break;
                    } else if (updateableBS.Unallocated_Amount__c >= ih.AmountOutstanding__c) {
                        PaymentAllocation__c pa = new PaymentAllocation__c();
                        pa.InvoiceId__c = ih.Id;
                        pa.BankstatementId__c = updateableBS.Id;
                        pa.AllocatedAmount__c = ih.AmountOutstanding__c.setscale(2);
                        pa.Account__c = a.Id;
                        paymentsToInsert.add(pa);
                        updateableBS.Unallocated_Amount__c = updateableBS.Unallocated_Amount__c - ih.AmountOutstanding__c;
                        system.debug(updateableBS);
                        ih.AmountOutstanding__c = 0;
                        ih.Status__c = 'Paid';
                        invoicesToUpdate.put(ih.Id, ih);
                        bsToUpdate.put(updateableBS, updateableBS.Unallocated_Amount__c);
                    } else {
                        continue;
                        //break;
                    }
                }
            }
        }
        List<Bank_Statement__c> bsToUpdateList = new List<Bank_Statement__c>(bsToUpdate.keySet());
        Set<Bank_Statement__c> bsSet = new Set<Bank_Statement__c>(bsToUpdateList);
        List<Bank_Statement__c> bsList = new List<Bank_Statement__c>(bsSet);

        system.debug(paymentsToInsert);
        system.debug(invoicesToUpdate);
        system.debug('bsaccountmap: '+bsAccountsMap);
        system.debug('bsaccountmapkeyset: '+bsAccountsMap.keySet());
        system.debug('bsaccountmapvalues: '+bsAccountsMap.values());
        system.debug('bsaccountmapkeysetsize: '+bsAccountsMap.keySet().size());
        system.debug(bsList);
        
        insert paymentsToInsert;
        update invoicesToUpdate.values();
        update bsList;
    }

    /* Bruno - 04.02.2019 -> 978 */
    private static void createPaymentsCreditNotes(List < Bank_Statement__c > bsList) {
        Set<Id> invoiceIds = new Set<Id>();
        system.debug('List of BS entering for payment: ' + bsList);
        for (Bank_Statement__c b : bsList) {
            system.debug('Unallocated_Amount__c 2 -->' + b.Unallocated_Amount__c);
            system.debug('Credit_Note_Invoice__c -->' + b.Credit_Note_Invoice__c);
            invoiceIds.add(b.Credit_Note_Invoice__c);
        }
        Map<Id, Bank_Statement__c> updateableBSMap = new Map<Id, Bank_Statement__c>([SELECT Id, Unallocated_Amount__c FROM Bank_Statement__c WHERE Id IN :bsList]);
        List < PaymentAllocation__c > paymentsCreditNotesToInsert = new List < PaymentAllocation__c > ();
        List < PaymentAllocation__c > paymentsOriginalToInsert = new List < PaymentAllocation__c > ();
        Map < Id, Invoice_Header__c > invoicesToUpdate = new Map < Id, Invoice_Header__c > ();

        Map < Id, Account > accountsWithInvoices = new Map < Id, Account > ([SELECT Id, (SELECT Id, AmountOutstanding__c, Status__c, ToPublish__c, Original_Invoice_to_Credit__c, Original_Invoice_to_Credit__r.AmountOutstanding__c, Original_Invoice_to_Credit__r.Name, Name FROM Invoice_Headers__r WHERE AmountOutstanding__c <= 0 AND Query__c = false AND Status__c != 'Paid' AND Id IN :invoiceIds
                ORDER BY CreatedDate ASC) FROM Account WHERE Id IN(SELECT Account__c FROM Invoice_Header__c WHERE AmountOutstanding__c <= 0 AND Query__c = false AND Status__c != 'Paid' AND Id IN :invoiceIds)]);
        
        system.debug('Accounts with invoices: ' + accountsWithInvoices);
        for (Bank_Statement__c bs: bsList) {
            system.debug('Account\'s invoices: ' + accountsWithInvoices.get(bs.Account__c).Invoice_Headers__r);
            system.debug('Bank Statement: ' + bs.Credit_Note_Invoice__c);
            for (Invoice_Header__c ih: accountsWithInvoices.get(bs.Account__c).Invoice_Headers__r) {
                System.debug('Invoice to credit name: ' + ih.Name + 
                            + '|Outstanding: ' + ih.AmountOutstanding__c + ' |Id: ' + ih.Id + ' |Original to Credit Outs: ' + ih.Original_Invoice_to_Credit__r.AmountOutstanding__c
                            + ' |Original to Cred Name: ' + ih.Original_Invoice_to_Credit__r.Name);
                if (ih.AmountOutstanding__c < 0 && ih.Id == bs.Credit_Note_Invoice__c && ih.Original_Invoice_to_Credit__r.AmountOutstanding__c > 0) {
                    system.debug(ih);
                    PaymentAllocation__c paCreditNote = new PaymentAllocation__c();
                    paCreditNote.IsCreditNote__c = true;
                    paCreditNote.Automatic_Payment__c = true;
                    paCreditNote.InvoiceId__c = ih.Id;
                    paCreditNote.BankstatementId__c = bs.Id;
                    //paCreditNote.AllocatedAmount__c = ih.AmountOutstanding__c;
                    Decimal negativeBSValue = bs.Unallocated_Amount__c * (-1);
                    if (bs.Unallocated_Amount__c >= ih.Original_Invoice_to_Credit__r.AmountOutstanding__c) {
                        paCreditNote.AllocatedAmount__c = ih.Original_Invoice_to_Credit__r.AmountOutstanding__c * (-1);
                    }
                    else {
                        paCreditNote.AllocatedAmount__c = negativeBSValue;
                    }
                    system.debug('AllocatedAmmount' + paCreditNote.AllocatedAmount__c);
                    system.debug('BankStatement' + bs.Unallocated_Amount__c);
                    paCreditNote.Account__c = bs.Account__c;
                    paymentsCreditNotesToInsert.add(paCreditNote);
                    
                    PaymentAllocation__c paOriginal = new PaymentAllocation__c();
                    paOriginal.IsCreditNote__c = true;
                    paOriginal.Automatic_Payment__c = true;
                    paOriginal.InvoiceId__c = ih.Original_Invoice_to_Credit__c;
                    paOriginal.BankstatementId__c = bs.Id;
                    //paOriginal.AllocatedAmount__c = 0 - ih.AmountOutstanding__c;
                    
                    if (bs.Unallocated_Amount__c >= ih.Original_Invoice_to_Credit__r.AmountOutstanding__c) {
                        paOriginal.AllocatedAmount__c = ih.Original_Invoice_to_Credit__r.AmountOutstanding__c;
                    }
                    else {
                        paOriginal.AllocatedAmount__c = bs.Unallocated_Amount__c;
                    }
                    paOriginal.Account__c = bs.Account__c;
                    paymentsOriginalToInsert.add(paOriginal);
                    
                    Bank_Statement__c b = updateableBSMap.get(bs.Id);
                    Invoice_Header__c originalInvoice = new Invoice_Header__c();        
                    
                    system.debug(b.Unallocated_Amount__c);
                    if (bs.Unallocated_Amount__c >= ih.Original_Invoice_to_Credit__r.AmountOutstanding__c) {
                        b.Unallocated_Amount__c = bs.Unallocated_Amount__c - ih.Original_Invoice_to_Credit__r.AmountOutstanding__c;
                        originalInvoice.Id = ih.Original_Invoice_to_Credit__c;      
                        originalInvoice.AmountOutstanding__c = 0;
                        ih.AmountOutstanding__c += paOriginal.AllocatedAmount__c;
                        ih.AmountOutstanding__c.setscale(2);
                    }
                    else {
                        originalInvoice.Id = ih.Original_Invoice_to_Credit__c;      
                        originalInvoice.AmountOutstanding__c = ih.Original_Invoice_to_Credit__r.AmountOutstanding__c - bs.Unallocated_Amount__c;
                        ih.AmountOutstanding__c += bs.Unallocated_Amount__c;
                        ih.AmountOutstanding__c.setscale(2);
                        b.Unallocated_Amount__c = 0;
                    }
                    updateableBSMap.put(b.Id, b);
                    
                    system.debug(originalInvoice);
                    invoicesToUpdate.put(originalInvoice.Id, originalInvoice);
                    
                    invoicesToUpdate.put(ih.Id, ih);
                    //bs.Unallocated_Amount__c = bs.Unallocated_Amount__c - ih.AmountOutstanding__c;
                }
            }
        }
        system.debug(paymentsCreditNotesToInsert);
        system.debug(paymentsOriginalToInsert);
        system.debug(invoicesToUpdate);
        system.debug(updateableBSMap);
        Database.SaveResult[] resultsPA = Database.insert(paymentsOriginalToInsert, false);
        for (Integer idx = 0; idx < resultsPA.size(); idx++) { 
            if (resultsPA[idx].isSuccess()) {
                paymentsCreditNotesToInsert[idx].Original_Invoice_Payment_Credit_Notes__c = paymentsOriginalToInsert[idx].Id;
            }
        }
        insert paymentsCreditNotesToInsert;
        update invoicesToUpdate.values();
        update updateableBSMap.values();
    }
    
    //Jira - 1603 (18/07/2019)
    public static void CreateSageExtract(List <Bank_Statement__c> bankStatements) {
        
        system.debug('Sage Extracts created from BSHelper');
        System.debug(bankStatements);
        List<SageExtract__c> sageExtractsToInsert = new List<SageExtract__c>(); 
         List < Bank_Statement__c > bankStatementsToUpdate = new List < Bank_Statement__c > ();
        
        for (Bank_Statement__c b : [SELECT Id, TransactionAmount__c, Entry_Date__c, Name, Bank_Account_Number__c FROM Bank_Statement__c WHERE Id IN :bankStatements]){            
            SageExtract__c se1 = new SageExtract__c();
            SageExtract__c se2 = new SageExtract__c();
            
            se1.Name = 'Payments record in Bank Account - '+ b.Name;
            if(b.Bank_Account_Number__c == '23881334' || b.Bank_Account_Number__c == null || b.Bank_Account_Number__c == ''){
                se1.AccountNumber__c = '1205';
            }else if(b.Bank_Account_Number__c == '70181293'){
                se1.AccountNumber__c = '1204'; 
            }
            se1.GoodsAmount__c = b.TransactionAmount__c;
            se1.TransactionDate__c = b.Entry_Date__c;
            se1.Bank_Statement__c = b.Id;
            sageExtractsToInsert.add(se1);
            
            se2.Name = 'Payments record in Control Account - '+ b.Name;
            se2.AccountNumber__c = '1100';
            se2.GoodsAmount__c = 0-b.TransactionAmount__c;
            se2.TransactionDate__c = b.Entry_Date__c;
            se2.Bank_Statement__c = b.Id;
            sageExtractsToInsert.add(se2);
            
            b.Sage_Extract_Created__c = true;
            bankStatementsToUpdate.add(b);
            
        }
        system.debug(sageExtractsToInsert);
        if(sageExtractsToInsert.size() > 0){
            insert sageExtractsToInsert;
        }
        
         if(bankStatementsToUpdate.size() > 0){
             update bankStatementsToUpdate;
        }  
    }
    
    public static void CreateFeeSageExtract(List <Bank_Statement__c> bankStatements) {
        
        system.debug('Sage Extracts created from BSHelper');
        System.debug(bankStatements);
        List<SageExtract__c> feeSageExtractsToInsert = new List<SageExtract__c>(); 
         List < Bank_Statement__c > bankStatementsToUpdate = new List < Bank_Statement__c > ();
        
        for (Bank_Statement__c b : [SELECT Id, Entry_Date__c, Name, Bank_Account_Number__c, Receipt_Amount__c FROM Bank_Statement__c WHERE Id IN :bankStatements]){            
            SageExtract__c se1 = new SageExtract__c();
            SageExtract__c se2 = new SageExtract__c();
            
            se1.Name = 'Fees Record with Control Account - '+ b.Name;
            se1.AccountNumber__c = '1100';
            se1.GoodsAmount__c = 0 - b.Receipt_Amount__c;
            se1.TransactionDate__c = b.Entry_Date__c;
            se1.Bank_Statement__c = b.Id;
            feeSageExtractsToInsert.add(se1);
            
            se2.Name = 'Fees Record with Fee Account - '+ b.Name;
            se2.AccountNumber__c = '7040';
            se2.GoodsAmount__c = b.Receipt_Amount__c;
            se2.TransactionDate__c = b.Entry_Date__c;
            se2.Bank_Statement__c = b.Id;
            feeSageExtractsToInsert.add(se2);
            
            b.Sage_Extract_Created__c = true;
            bankStatementsToUpdate.add(b);
            
        }
        system.debug(feeSageExtractsToInsert);
        if(feeSageExtractsToInsert.size() > 0){
            insert feeSageExtractsToInsert;
        }
        
         if(bankStatementsToUpdate.size() > 0){
             update bankStatementsToUpdate;
        }  
    }

    public static void cancelBankStatements(List < Bank_Statement__c > bsList) {
        
        List < LogRegister > logs = new List < LogRegister > ();
        List < Database.SaveResult > results;
        List < sObject > records;
        String process;
        String action;
        String sObjectType;
        String ParentField;
        
        List<Bank_Statement__c> bsToCancel = new List <Bank_Statement__c>();
        List<SageExtract__c> sageExtractsToInsert = new List<SageExtract__c>();        
        List<PaymentAllocation__c> paymentsToDelete = new List<PaymentAllocation__c>();
        
        for (Bank_Statement__c bs : [SELECT Id, Name, Entry_Date__c, Unallocated_Amount__c, TransactionAmount__c,(SELECT Id, AllocatedAmount__c, InvoiceId__c, InvoiceId__r.AmountOutstanding__c FROM PaymentAllocations__r) FROM Bank_Statement__c WHERE Id IN :bsList]){

            paymentsToDelete.addAll(bs.PaymentAllocations__r);
            
            SageExtract__c se1 = new SageExtract__c();
            SageExtract__c se2 = new SageExtract__c();
            
            se1.Name = 'Payments record in Bank Account - '+ bs.Name;
            se1.AccountNumber__c = '1205';
            se1.GoodsAmount__c = 0-bs.TransactionAmount__c;
            se1.TransactionDate__c = bs.Entry_Date__c;
            se1.Bank_Statement__c = bs.Id;
            sageExtractsToInsert.add(se1);
            
            se2.Name = 'Payments record in Control Account - '+ bs.Name;
            se2.AccountNumber__c = '1100';
            se2.GoodsAmount__c = bs.TransactionAmount__c;
            se2.TransactionDate__c = bs.Entry_Date__c;
            se2.Bank_Statement__c = bs.Id;
            sageExtractsToInsert.add(se2);
            
            bs.Unallocated_Amount__c = 0; 
            bs.Sage_Extract_Created__c = true;
            bsToCancel.add(bs);
        }
        
        if(sageExtractsToInsert.size() > 0){
            insert sageExtractsToInsert;
        }
  
        if(paymentsToDelete.size()>0){
            
            Database.DeleteResult[] resultsBS = Database.delete(paymentsToDelete, false);
            records = paymentsToDelete;
            process = 'paymentsToDelete delete PaymentAllocations';
            action = 'Delete';
            sObjectType = 'PaymentAllocation__c';
            ParentField = 'Bank_Statement__c';
            
            //LogRegister.createLogsUpsert(resultsBS, records, process, action, sObjectType, ParentField); *To execute in te future
        }
        update bsToCancel;
    }
}