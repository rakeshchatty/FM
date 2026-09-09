public without sharing class ContactTriggerHandler {

	public void handleTrigger(List<Contact> newList, Map<Id, Contact> oldMap, TriggerOperation operation) {
		switch on operation {
			when BEFORE_DELETE {
				new ContactDeletion(oldMap.values());
			}
		}
	}
}