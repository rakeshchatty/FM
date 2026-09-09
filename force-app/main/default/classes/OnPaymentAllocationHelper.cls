public with sharing class OnPaymentAllocationHelper {


	public static boolean hasRan = false;

	// Trigger entry point   
	public static void entry(
		System.TriggerOperation triggerEvent,
		List < PaymentAllocation__c > newList,
		Map < Id, PaymentAllocation__c > newMap,
		List < PaymentAllocation__c > oldList,
		Map < Id, PaymentAllocation__c > oldMap
	) {
		// Dispatch trigger event to corresponding methods 
		switch on triggerEvent {
			when BEFORE_INSERT, BEFORE_UPDATE {
				checkForErrors(newList);
			}
			when AFTER_INSERT {
				//updateRelatedRecords(newMap.keySet(), false);
				updateRelatedRecords(newMap, 'INSERT');
			}
			when AFTER_UPDATE {
				//updateRelatedRecords(newMap.keySet(), false);
				updateRelatedRecords(newMap, 'UPDATE');
			}
			when BEFORE_DELETE {
				//updateRelatedRecords(oldMap.keySet(), true);
				updateRelatedRecords(oldMap, 'DELETE');
			}
		}
	}
	private static void updateRelatedRecords( /*Set < Id > paIds*/ Map < Id, PaymentAllocation__c > paMap, string event) {
		/*if (!hasRan) {
			hasRan = true;*/
			Map < Id, Invoice_Header__c > invoiceHeadersToUpdateMap = new Map < Id, Invoice_Header__c > ();
			Map < Id, Bank_Statement__c > bankStatementsToUpdateMap = new Map < Id, Bank_Statement__c > ();
			/* Bruno - 30.01.2019 -> 1215 - Orders by card on CP BEGIN */
			Set < Id > bankStatementIdsForCPCardPayments = new Set < Id > ();




			
			Map < Id, PaymentAllocation__c > paIdsCreditNotes = new Map < Id, PaymentAllocation__c > ();
			Map < Id, PaymentAllocation__c > paCreditNoteMap = new Map < Id, PaymentAllocation__c > ([SELECT Id, AllocatedAmount__c, IsCreditNote__c, BankstatementId__r.Credit_Note_Invoice__c, BankstatementId__r.Credit_Note_Invoice__r.AmountOutstanding__c, BankstatementId__c, BankstatementId__r.Unallocated_Amount__c, Account__c, InvoiceId__c, InvoiceId__r.AmountOutstanding__c FROM PaymentAllocation__c WHERE Id IN: paMap.keySet() AND IsCreditNote__c = true]);

			for (PaymentAllocation__c pa: paMap.values()) {
				if (pa.IsFromCPCard__c == true) {
					bankStatementIdsForCPCardPayments.add(pa.BankstatementId__c);
				}
			}

			/* Bruno - 30.01.2019 -> 1215 - Orders by card on CP END */
			/* Bruno - 18.02.2019 -> 978 - recalculating when PA is deleted BEGIN part 1*/
			//Map < Id, Decimal > bankStatementsPaymentAmountMap = new Map < Id, Decimal > ();
			Set<Id> paymentsToDeleteSet = new Set<Id>();
			/* Bruno - 18.02.2019 -> 978 - recalculating when PA is deleted END part 1*/
			List < PaymentAllocation__c > paymentsToInsert = new List < PaymentAllocation__c > ();
			
			for (PaymentAllocation__c pa: [SELECT Id, IsFromCPCard__c, IsDirectDebit__c, IsCreditNote__c, Automatic_Payment__c, AllocatedAmount__c, Original_Invoice_Payment_Credit_Notes__c, Account__c, BankstatementId__c, BankstatementId__r.Unallocated_Amount__c, BankstatementId__r.Credit_Note_Invoice__c, BankstatementId__r.Credit_Note_Invoice__r.AmountOutstanding__c, InvoiceId__c, InvoiceId__r.Original_Invoice_to_Credit__c, InvoiceId__r.AmountOutstanding__c, InvoiceId__r.Status__c, (SELECT Id FROM OriginalInvoicePayments__r) FROM PaymentAllocation__c WHERE ID IN: paMap.keySet() /*paIds*/ ]) {
				system.debug(pa);
				system.debug(pa.BankstatementId__r.Credit_Note_Invoice__c);
				/* Bruno - Jira 1433 -> Create Sage Extracts and populate amounts after payments creation */
				/* Bruno - Jira 1434 -> Started using the trigger events to update accounts/invoices/bankstatements for direct debits */
				if (pa.IsDirectDebit__c == true && event == 'INSERT') {
					Bank_Statement__c bs = new Bank_Statement__c();
					bs.Id = pa.BankstatementId__c;
					bs.MarkedForSage__c = true;
					bankStatementsToUpdateMap.put(bs.Id, bs);
				} 
				/* Bruno - 18.02.2019 -> 978 - recalculating when PA is deleted BEGIN part 2*/
				//if (pa.BankstatementId__r.Credit_Note_Invoice__c != null) {
				if (pa.IsCreditNote__c) {
					if (event != 'DELETE' && pa.Automatic_Payment__c) {
						continue;
					} 
					/* Bruno 19.02.2019 -> 978 - manual payments START */
					else if (event != 'DELETE' && !pa.Automatic_Payment__c) {
						PaymentAllocation__c paCreditNote = new PaymentAllocation__c();
						paCreditNote.IsCreditNote__c = true;
						paCreditNote.Automatic_Payment__c = true;
						paCreditNote.InvoiceId__c = pa.BankstatementId__r.Credit_Note_Invoice__c;
						paCreditNote.BankstatementId__c = pa.BankstatementId__c;
						paCreditNote.AllocatedAmount__c = pa.AllocatedAmount__c * (-1);
						paCreditNote.Account__c = pa.Account__c;
						paCreditNote.Original_Invoice_Payment_Credit_Notes__c = pa.Id;
						paymentsToInsert.add(paCreditNote);
						SYSTEM.DEBUG(paCreditNote);
						Invoice_Header__c creditNote = new Invoice_Header__c();
						creditNote.Id = pa.BankstatementId__r.Credit_Note_Invoice__c;
						creditNote.AmountOutstanding__c = pa.BankstatementId__r.Credit_Note_Invoice__r.AmountOutstanding__c + pa.AllocatedAmount__c;
						invoiceHeadersToUpdateMap.put(creditNote.Id, creditNote);
					}
					/* Bruno 19.02.2019 -> 978 - manual payments END */
					else if (event == 'DELETE' && pa.Original_Invoice_Payment_Credit_Notes__c != null && !hasRan){
						hasRan = true;
						paymentsToDeleteSet.add(pa.Original_Invoice_Payment_Credit_Notes__c);
						Invoice_Header__c creditNote = new Invoice_Header__c();
						creditNote.Id = pa.BankstatementId__r.Credit_Note_Invoice__c;
						creditNote.AmountOutstanding__c = pa.BankstatementId__r.Credit_Note_Invoice__r.AmountOutstanding__c + pa.AllocatedAmount__c;
						invoiceHeadersToUpdateMap.put(creditNote.Id, creditNote);
						continue;
					}
					else if (event == 'DELETE' && pa.Original_Invoice_Payment_Credit_Notes__c != null && hasRan){
						Invoice_Header__c creditNote = new Invoice_Header__c();
						creditNote.Id = pa.BankstatementId__r.Credit_Note_Invoice__c;
						creditNote.AmountOutstanding__c = pa.BankstatementId__r.Credit_Note_Invoice__r.AmountOutstanding__c + pa.AllocatedAmount__c;
						invoiceHeadersToUpdateMap.put(creditNote.Id, creditNote);
						continue;
					}
					else if (event == 'DELETE' && pa.Original_Invoice_Payment_Credit_Notes__c == null && !hasRan) {
						hasRan = true;
						for (PaymentAllocation__c paCN : pa.OriginalInvoicePayments__r) {
							paymentsToDeleteSet.add(paCN.Id);
						}
					}
				}

				if (invoiceHeadersToUpdateMap.containsKey(pa.InvoiceId__c) && (!pa.IsDirectDebit__c || (pa.IsDirectDebit__c && event == 'DELETE'))) {
					Invoice_Header__c i = invoiceHeadersToUpdateMap.get(pa.InvoiceId__c);
					if (event == 'DELETE') {
						i.AmountOutstanding__c = i.AmountOutstanding__c.setscale(2) + pa.AllocatedAmount__c;
					} else {
						i.AmountOutstanding__c = i.AmountOutstanding__c.setscale(2) - pa.AllocatedAmount__c;
					}
					if (i.Status__c == 'Paid') {
						i.Status__c = null;
					}
					invoiceHeadersToUpdateMap.put(i.Id, i);
				} else if (!pa.IsDirectDebit__c || (pa.IsDirectDebit__c && event == 'DELETE')){
					Invoice_Header__c i = new Invoice_Header__c();
					i.Id = pa.InvoiceId__c;
					system.debug(i);
					if (event == 'DELETE') {
						i.AmountOutstanding__c = pa.InvoiceId__r.AmountOutstanding__c.setscale(2) + pa.AllocatedAmount__c;
					} else {
						system.debug(pa.InvoiceId__r.AmountOutstanding__c);
						system.debug(pa.AllocatedAmount__c);
						//Test bruno 14-01
						if (pa.InvoiceId__r.AmountOutstanding__c == null) {
							i.AmountOutstanding__c = 0;
						} else {
							i.AmountOutstanding__c = pa.InvoiceId__r.AmountOutstanding__c.setscale(2) - pa.AllocatedAmount__c;
						}
					}
					if (pa.InvoiceId__r.Status__c == 'Paid') {
						i.Status__c = null;
					}
					invoiceHeadersToUpdateMap.put(i.Id, i);
				}
				if (bankStatementsToUpdateMap.containsKey(pa.BankstatementId__c) && (!pa.IsDirectDebit__c || (pa.IsDirectDebit__c && event == 'DELETE'))) {
					Bank_Statement__c b = bankStatementsToUpdateMap.get(pa.BankstatementId__c);
					if (event == 'DELETE') {
						b.Unallocated_Amount__c = b.Unallocated_Amount__c + pa.AllocatedAmount__c;
					} else {
						b.Unallocated_Amount__c = b.Unallocated_Amount__c - pa.AllocatedAmount__c;
					}

					bankStatementsToUpdateMap.put(b.Id, b);
				} else if (!pa.IsDirectDebit__c || (pa.IsDirectDebit__c && event == 'DELETE')) {
					Bank_Statement__c b = new Bank_Statement__c();
					b.Id = pa.BankstatementId__c;
					if (event == 'DELETE') {
						b.Unallocated_Amount__c = pa.BankstatementId__r.Unallocated_Amount__c + pa.AllocatedAmount__c;
					} else {
						b.Unallocated_Amount__c = pa.BankstatementId__r.Unallocated_Amount__c - pa.AllocatedAmount__c;
					}
					bankStatementsToUpdateMap.put(b.Id, b);
				}
			}
			system.debug(invoiceHeadersToUpdateMap);
			update invoiceHeadersToUpdateMap.values();
			system.debug(bankStatementsToUpdateMap);
			update bankStatementsToUpdateMap.values();
			/* 978 */
			insert paymentsToInsert;
			/* Bruno - 30.01.2019 -> 1215 - Orders by card on CP BEGIN */
			CreateSageExtract(bankStatementIdsForCPCardPayments);
			/* Bruno - 30.01.2019 -> 1215 - Orders by card on CP END */
			/* Bruno - 18.02.2019 -> 978 - recalculating when PA is deleted BEGIN part 4*/
			if (paymentsToDeleteSet.size() > 0) {
				delete [SELECT Id FROM PaymentAllocation__c WHERE Id IN :paymentsToDeleteSet];
			}
			/* Bruno - 18.02.2019 -> 978 - recalculating when PA is deleted END part 4*/
		//} hasRan

	}

	private static void CreateSageExtract(Set < Id > bankStatementIds) {

		System.debug(bankStatementIds);
		List < SageExtract__c > sageExtractsToInsert = new List < SageExtract__c > ();

		for (Bank_Statement__c b: [SELECT Id, TransactionAmount__c, Entry_Date__c, Name FROM Bank_Statement__c WHERE Id IN: bankStatementIds]) {
			SageExtract__c se1 = new SageExtract__c();
			SageExtract__c se2 = new SageExtract__c();

			se1.Name = 'Payments record in Bank Account - ' + b.Name;
			se1.AccountNumber__c = '1205';
			se1.GoodsAmount__c = b.TransactionAmount__c;
			se1.TransactionDate__c = b.Entry_Date__c;
			se1.Bank_Statement__c = b.Id;
			sageExtractsToInsert.add(se1);

			se2.Name = 'Payments record in Control Account - ' + b.Name;
			se2.AccountNumber__c = '1100';
			se2.GoodsAmount__c = 0 - b.TransactionAmount__c;
			se2.TransactionDate__c = b.Entry_Date__c;
			se2.Bank_Statement__c = b.Id;
			sageExtractsToInsert.add(se2);

		}
		system.debug(sageExtractsToInsert);
		insert sageExtractsToInsert;
	}

	private static void checkForErrors(List < PaymentAllocation__c > newList) {
		Set < Id > bsIds = new Set < Id > ();
		Set < Id > invoicesIds = new Set < Id > ();
		for (PaymentAllocation__c pa: newList) {
			if (pa.IsDirectDebit__c == true) continue;
			bsIds.add(pa.BankstatementId__c);
			invoicesIds.add(pa.InvoiceId__c);
		}
		Map < Id, Bank_Statement__c > bsMap = new Map < Id, Bank_Statement__c > ([SELECT Id, Unallocated_Amount__c FROM Bank_Statement__c WHERE Id IN: bsIds]);
		Map < Id, Invoice_Header__c > invMap = new Map < Id, Invoice_Header__c > ([SELECT Id, VAT__c, AmountOutstanding__c, Original_Invoice_to_Credit__c FROM Invoice_Header__c WHERE Id IN: invoicesIds]);


		for (PaymentAllocation__c pa: newList) {
			if (pa.IsDirectDebit__c == true) continue;
			Bank_Statement__c thisBS = bsMap.get(pa.BankstatementId__c);
			Invoice_Header__c thisIH = invMap.get(pa.InvoiceId__c);
            system.debug('thisIH.VAT__c1' + thisIH.VAT__c);
			system.debug('Unallocated Amount: ' + thisBS.Unallocated_Amount__c + ' -- AllocatedAmount: ' + pa.AllocatedAmount__c + ' -- Original Invoice: ' + thisIH.Original_Invoice_to_Credit__c + ' -- AmountOutstanding: ' + thisIH.AmountOutstanding__c);
			/* Bruno - 13.02.2019 -> 978 - Added Unallocated Amount > 0 to avoid entering this rule for Credit Notes bank statements */
			if (thisBS.Unallocated_Amount__c < pa.AllocatedAmount__c) {
				pa.addError('Allocated Amount is greater than the Unallocated Amount from the selected Bank Statement.');
			}
			if (thisIH.AmountOutstanding__c.setscale(2) < pa.AllocatedAmount__c && thisIH.AmountOutstanding__c.setscale(2) > 0 || thisIH.AmountOutstanding__c.setscale(2) < pa.AllocatedAmount__c && thisIH.AmountOutstanding__c == 0) {
                system.debug('thisIH -->'+ thisIH.AmountOutstanding__c + 'pa.AllocatedAmount__c --->' +pa.AllocatedAmount__c);
				pa.addError('Allocated Amount is greater than the Amount Outstanding from the selected Invoice Header.');
			}
		}
	}
}