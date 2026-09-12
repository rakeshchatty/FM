public without sharing class HubSpotAcrSync {
	private static Map<String, HubspotAssociationLabel__mdt> associationMap = HubspotAssociationLabel__mdt.getAll();

	private static String NO_REPLY_EMAIL = [SELECT Id FROM OrgWideEmailAddress WHERE Address = 'noreply@thefirstmile.co.uk'].Id;
	private static List<String> RECIPIENT_ADDRESSES = new List<String>{'timothy.goh@thefirstmile.co.uk', 'fm.salesforce@xperiensys.com'};

	public void handleInsert(List<AccountContactRelation> acrs) {
		List<AccountContactRelation> invalidAcrs = new List<AccountContactRelation>();
		for (AccountContactRelation acr : acrs) {
			if (String.isBlank(acr.HubSpotAccountId__c) || String.isBlank(acr.HubSpotContactId__c)) {
				invalidAcrs.add(new AccountContactRelation(Id = acr.Id, HubSpotSyncStatus__c = 'Error', HubSpotSyncMessage__c = 'Either HubSpot CompanyId or HubSpot ContactId is empty.'));
				continue;
			}

			if (!String.isBlank(acr.Roles)) {
				EventBus.publish(new HubSpotAcrSync__e(Action__c = 'UPSERT', HubSpotContactId__c = acr.HubSpotContactId__c, HubSpotAccountId__c = acr.HubSpotAccountId__c, AcrId__c = acr.Id, Roles__c = acr.Roles));
			}
		}

		if (!invalidAcrs.isEmpty()) {
			UPDATE invalidAcrs;
		}
	}

	public void handleDelete(List<AccountContactRelation> acrs) {
		for (AccountContactRelation acr : acrs) {
			if (String.isBlank(acr.HubSpotContactId__c) || String.isBlank(acr.HubSpotAccountId__c)) {
				continue;
			}
			EventBus.publish(new HubSpotAcrSync__e(Action__c = 'DELETE', HubSpotContactId__c = acr.HubSpotContactId__c, HubSpotAccountId__c = acr.HubSpotAccountId__c));
		}
	}

	public void handleUpdate(List<AccountContactRelation> acrs, Map<Id, AccountContactRelation> oldAcrMap) {
		List<AccountContactRelation> invalidAcrs = new List<AccountContactRelation>();
		AccountContactRelation oldAcr;
		List<String> newRoles;
		for (AccountContactRelation acr : acrs) {
			oldAcr = oldAcrMap.get(acr.Id);
			if (acr.Roles == oldAcr.Roles && acr.HubSpotSyncStatus__c != 'Retry') {
				continue;
			}

			if (String.isBlank(acr.HubSpotAccountId__c) || String.isBlank(acr.HubSpotContactId__c)) {
				invalidAcrs.add(new AccountContactRelation(Id = acr.Id, HubSpotSyncStatus__c = 'Error', HubSpotSyncMessage__c = 'Either HubSpot CompanyId or HubSpot ContactId is empty.'));
				continue;
			}

			newRoles = StringUtil.splitTrim(acr.Roles, ';');
			if (newRoles.isEmpty()) {
				EventBus.publish(new HubSpotAcrSync__e(Action__c = 'DELETE', HubSpotContactId__c = acr.HubSpotContactId__c, HubSpotAccountId__c = acr.HubSpotAccountId__c, AcrId__c = acr.Id));
				continue;
			}

			Boolean performDelete = acr.HubSpotSyncStatus__c == 'Retry' || isOldRoleRemoved(newRoles, oldAcr.Roles);
			EventBus.publish(new HubSpotAcrSync__e(Action__c = 'UPSERT', HubSpotContactId__c = acr.HubSpotContactId__c, HubSpotAccountId__c = acr.HubSpotAccountId__c, AcrId__c = acr.Id, Roles__c = acr.Roles, PerformDelete__c = performDelete));
		}

		if (!invalidAcrs.isEmpty()) {
			UPDATE invalidAcrs;
		}
	}

	private Boolean isOldRoleRemoved(List<String> newRoles, String oldRole) {
		List<String> oldRoles = StringUtil.splitTrim(oldRole, ';');
		Set<String> newRolesSet = new Set<String>(newRoles);

		return !newRolesSet.containsAll(oldRoles);
	}

	@future(callout=true)
	public static void upsertAssociation(String hubspotContactId, String hubspotCompanyId, String acrId, String roles, Boolean performDelete) {
		try {
			if (performDelete) {
				new HubSpotAcrSync().deleteAssociationCallout(hubspotContactId, hubspotCompanyId, null);
			}

			Input input = new Input(hubspotContactId, hubspotCompanyId);

			HubSpotAssociationLabel__mdt associationLabel;
			for (String role : StringUtil.splitTrim(roles, ';')) {
				associationLabel = associationMap.get(role.replace(' ','_'));
				if (associationLabel != null) {
					input.types.add(new Type(associationLabel.Category__c, Integer.ValueOf(associationLabel.TypeId__c)));
				} else {
					UPDATE new AccountContactRelation(Id = acrId, HubSpotSyncStatus__c = 'Error', HubSpotSyncMessage__c = 'ACR Role mapping does not exist in HubSpotAssociationLabel__mdt.');
					return;
				}
			}

			AssociationRequest associationRequest = new AssociationRequest(input);

			String requestBody = JSON.serialize(associationRequest).replace('"fromObject"','"from"').replace('"toObject"','"to"');
			HttpRequest request = new HttpRequest();
			request.setEndpoint('callout:HubSpot/crm/v4/associations/contacts/companies/batch/create');
			request.setMethod('POST');
			request.setHeader('Content-Type','application/json');
			request.setBody(requestBody);

			HttpResponse response = new Http().send(request);
			String responseBody = response.getBody();
			if (response.getStatusCode() != 200 && response.getStatusCode() != 201) {
				UPDATE new AccountContactRelation(Id = acrId, HubSpotSyncStatus__c = 'Error', HubSpotSyncMessage__c = responseBody.abbreviate(255));
			} else {
				UPDATE new AccountContactRelation(Id = acrId, HubSpotSyncStatus__c = 'Success', HubSpotSyncMessage__c = '');
			}
		} catch (Exception e) {
			UPDATE new AccountContactRelation(Id = acrId, HubSpotSyncStatus__c = 'Error', HubSpotSyncMessage__c = e.getMessage().abbreviate(255));
		}
	}

	@future(callout=true)
	public static void deleteAssociation(String hubspotContactId, String hubspotCompanyId, String acrId) {
		new HubSpotAcrSync().deleteAssociationCallout(hubspotContactId, hubspotCompanyId, acrId);
	}

	public void deleteAssociationCallout(String hubspotContactId, String hubspotCompanyId, String acrId) {
		HttpRequest request = new HttpRequest();
		request.setEndpoint('callout:HubSpot/crm/v4/objects/contacts/' + hubspotContactId + '/associations/companies/' + hubspotCompanyId);
		request.setMethod('DELETE');

		HttpResponse response = new Http().send(request);

		if (response.getStatusCode() != 200 && response.getStatusCode() != 204) {
			Messaging.SingleEmailMessage errorMail = new Messaging.SingleEmailMessage();
			errorMail.setToAddresses(RECIPIENT_ADDRESSES);
			errorMail.setOrgWideEmailAddressId(NO_REPLY_EMAIL);
			errorMail.setSubject('ACR Sync failure occurred while deleting association');
			errorMail.setPlainTextBody('Account HubSpotId: ' + hubspotCompanyId + ', Contact HubSpotId: ' + hubspotContactId);
			Messaging.sendEmail(new Messaging.SingleEmailMessage[] {errorMail});
		} else if (acrId != null) {
			UPDATE new AccountContactRelation(Id = acrId, HubSpotSyncStatus__c = 'Success', HubSpotSyncMessage__c = '');
		}
	}

	private class AssociationRequest {
		private List<Input> inputs = new List<Input>();

		private AssociationRequest(Input input) {
			inputs.add(input);
		}
	}
	private class Input {
		private FromObject fromObject = new FromObject();
		private ToObject toObject = new ToObject();
		private List<Type> types = new List<Type>();

		private Input(String hubspotContactId, String hubspotCompanyId) {
			fromObject.id = hubspotContactId;
			toObject.id = hubspotCompanyId;
		}
	}
	private class FromObject {
		private String id;
	}
	private class ToObject {
		private String id;
	}
	private class Type {
		private String associationCategory;
		private Integer associationTypeId;

		private Type(String associationCategory, Integer associationTypeId) {
			this.associationCategory = associationCategory;
			this.associationTypeId = associationTypeId;
		}
	}
}