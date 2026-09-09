@isTest
public class EmailMessageTrigger_Test {

	@testSetup static void setup() {
		CaseSetting__c cs = new CaseSetting__c();
		cs.ReopenDuration__c = 7;
		INSERT cs;

		Case c1 = new Case();
		c1.Subject = 'Test Case';
		c1.Status ='New';
		c1.Priority = 'Medium';
		c1.Origin = 'Email';
		c1.Type = 'Council Fine';
		c1.CreatedDate = system.today().addDays(-8);
		INSERT c1;
	}

	private static testmethod void testEmailOnExistingOpenCase() {
		Integer caseSize = [SELECT Id FROM Case].size();
		Case currentOpenedCase = [SELECT Id FROM Case WHERE ClosedDate = null LIMIT 1];
		EmailMessage email = new EmailMessage();
		email.FromAddress = 'test@abc.org';
		email.Incoming = True;
		email.ToAddress= 'test@xyz.org';
		email.Subject = 'Test email';
		email.HtmlBody = 'Test email body';
		email.ParentId = currentOpenedCase.Id;
		INSERT email;
		System.assertEquals(caseSize, [SELECT Id FROM Case].size());
	}

	private static testmethod void emailToReopenExistingClosedCase() {
		Case c1 = new Case();
		c1.Subject = 'Test Case 2';
		c1.Status ='Closed';
		c1.Priority = 'Medium';
		c1.Origin = 'Email';
		c1.Type = 'Council Fine';
		c1.CreatedDate = system.today().addDays(-8);
		c1.ClosedDate = system.today().addDays(-6);
		INSERT c1;

		EmailMessage email = new EmailMessage();
		email.FromAddress = 'test@abc.org';
		email.Incoming = True;
		email.ToAddress= 'test@xyz.org';
		email.Subject = 'Test email';
		email.HtmlBody = 'Test email body';
		email.ParentId = c1.Id;
		INSERT email;

		CaseResponseTime.getFirstResponseDuration(new List<Id>{c1.Id});

		System.assertEquals('Active', [SELECT Status FROM Case WHERE Id = :c1.Id].Status);
	}

	private static testmethod void emailOnHistoricalClosedCase() {
		Case c1 = new Case();
		c1.Subject = 'Test Case 2';
		c1.Status ='Closed';
		c1.Priority = 'Medium';
		c1.Origin = 'Email';
		c1.Type = 'Council Fine';
		c1.CreatedDate = system.today().addDays(-8);
		c1.ClosedDate = system.today().addDays(-6);
		INSERT c1;

		String caseNumber = [SELECT CaseNumber FROM Case WHERE Id = :c1.Id].CaseNumber;
		c1.ParentCaseNumber__c = caseNumber;
		UPDATE c1;

		Case c2 = new Case();
		c2.Subject = 'Test Case 2';
		c2.Status ='Closed';
		c2.Priority = 'Medium';
		c2.Origin = 'Email';
		c2.Type = 'Council Fine';
		c2.CreatedDate = system.today().addDays(-8);
		c2.ClosedDate = system.today().addDays(-3);
		c2.ParentCaseNumber__c = caseNumber;
		INSERT c2;

		Case c3 = new Case();
		c3.Subject = 'Test Case 2';
		c3.Status ='Closed';
		c3.Priority = 'Medium';
		c3.Origin = 'Email';
		c3.Type = 'Council Fine';
		c3.CreatedDate = system.today().addDays(-8);
		c3.ClosedDate = system.today().addDays(-2);
		c3.ParentCaseNumber__c = caseNumber;
		INSERT c3;

		CaseSetting__c cs = [SELECT Id From CaseSetting__c LIMIT 1];
		cs.ReopenDuration__c = 1;
		UPDATE cs;

		Integer caseSize = [SELECT Id FROM Case].size();

		EmailMessage email = new EmailMessage();
		email.FromAddress = 'test@abc.org';
		email.Incoming = True;
		email.ToAddress= 'test@xyz.org';
		email.Subject = 'Test email';
		email.HtmlBody = 'Test email body';
		email.ParentId = c1.Id;
		INSERT email;
		System.assertEquals(caseSize+1, [SELECT Id FROM Case].size());
	}
}