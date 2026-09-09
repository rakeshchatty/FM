public class EmailMessageTriggerHandler {

	private static final Integer REOPEN_DURATION = CaseSetting.getReopenDuration();
	private static final Integer MAX_CASE_DESCRIPTION_LENGTH = Case.Description.getDescribe().getLength();
	private static final String CASE_TYPE_IGNORE = 'Spam/Duplicate/Autoresponder';

	public void handleTrigger(List<EmailMessage> newList, Map<Id, EmailMessage> oldMap, TriggerOperation operation) {
		switch on operation {
			when BEFORE_INSERT {
				handleClosedCase(newList);
			}
		}
	}

	public void handleClosedCase(List<EmailMessage> emailMessageList) {
		List<Case> caseUpdateList = new List<Case>();
		List<Case> caseInsertList = new List<Case>();
		List<EmailMessage> newCaseEmailMessageList = new List<EmailMessage>();

		for (EmailMessage em : emailMessageList) {
			if (!em.Incoming || em.ParentId == null) {
				continue;
			}

			Case attachedCase = [SELECT IsClosed, ClosedDate, CaseNumber, ParentCaseNumber__c, Type, ContactId, AccountId FROM Case WHERE Id = :em.ParentId];
			if (!attachedCase.IsClosed) {
				continue;
			}

			Case recentCase = attachedCase;
			if (String.isNotBlank(attachedCase.ParentCaseNumber__c)) {
				recentCase = getMostRecentCase(attachedCase.ParentCaseNumber__c);
			}
			if (!recentCase.IsClosed) {
				em.ParentId = recentCase.Id;
				continue;
			}

			if (recentCase.Type == CASE_TYPE_IGNORE) {
				continue;
			}

			if (isWithinReopenDuration(recentCase)) {
				recentCase.Status = 'Active';
				caseUpdateList.add(recentCase);
				em.ParentId = recentCase.Id;
			} else {
				String parentCaseNumber = recentCase.ParentCaseNumber__c;
				if (String.isBlank(parentCaseNumber)) {
					recentCase.ParentCaseNumber__c = parentCaseNumber = recentCase.CaseNumber;
					caseUpdateList.add(recentCase);
				}

				Case newCase = createNewCase(em);
				newCase.ParentCaseNumber__c = parentCaseNumber;
				newCase.ContactId = recentCase.ContactId;
				newCase.AccountId = recentCase.AccountId;
				caseInsertList.add(newCase);
				newCaseEmailMessageList.add(em);
			}
		}

		if (!caseUpdateList.isEmpty()) {
			UPDATE caseUpdateList;
		}

		if (!caseInsertList.isEmpty()) {
			AssignmentRule caseAssignRule = [SELECT Id FROM AssignmentRule
				WHERE SobjectType = 'Case'
				AND Active = TRUE];

			Database.DMLOptions dmlOpts = new Database.DMLOptions();
			dmlOpts.EmailHeader.triggerAutoResponseEmail = true;
			dmlOpts.assignmentRuleHeader.assignmentRuleId = caseAssignRule.Id;
			Database.insert(caseInsertList, dmlOpts);

			for (Integer i=0; i<caseInsertList.size(); i++) {
				newCaseEmailMessageList[i].ParentId = caseInsertList[i].Id;
			}
		}
	}

	private Case getMostRecentCase(String parentCaseNumber) {
		return [SELECT IsClosed, ClosedDate, ParentCaseNumber__c, Type, ContactId, AccountId FROM Case WHERE ParentCaseNumber__c = :parentCaseNumber AND Type != :CASE_TYPE_IGNORE ORDER BY CaseNumber DESC LIMIT 1];
	}

	private Boolean isWithinReopenDuration(Case cs) {
		return System.now() < cs.ClosedDate + REOPEN_DURATION;
	}

	private Case createNewCase(EmailMessage email) {
		Case newCase = new Case();
		newCase.Origin = 'Email';
		newCase.Subject = email.Subject;
		if (String.isNotBlank(email.TextBody)) {
			newCase.Description = email.TextBody.abbreviate(MAX_CASE_DESCRIPTION_LENGTH);
		}
		newCase.SuppliedEmail = email.FromAddress;
		newCase.SuppliedName = email.FromName;
		return newCase;
	}
}