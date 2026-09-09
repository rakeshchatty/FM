# Skill: Apex Trigger Framework

How triggers are structured in FM. Existing classes already follow a handler/helper
pattern (`AccountTriggerHandler`, `AccountTriggerHelper`,
`AccountContactRelationTriggerHandler`, etc.) — stay consistent with that.

## Rules
1. **One trigger per SObject.** Never two triggers on the same object.
2. Trigger body = routing only. No SOQL, DML, or business rules.
3. All logic lives in `<Object>TriggerHandler`; reusable calculations may go in
   `<Object>TriggerHelper`.
4. SOQL is done through a selector class, bulk-safe, `WITH USER_MODE`.
5. Recursion is controlled in the handler via a static guard.

## Trigger template
```apex
trigger AccountTrigger on Account (
    before insert, before update, before delete,
    after insert, after update, after delete, after undelete
) {
    AccountTriggerHandler handler = new AccountTriggerHandler();

    if (Trigger.isBefore && Trigger.isInsert)   handler.beforeInsert(Trigger.new);
    if (Trigger.isBefore && Trigger.isUpdate)   handler.beforeUpdate(Trigger.new, Trigger.oldMap);
    if (Trigger.isBefore && Trigger.isDelete)   handler.beforeDelete(Trigger.oldMap);
    if (Trigger.isAfter  && Trigger.isInsert)   handler.afterInsert(Trigger.new, Trigger.newMap);
    if (Trigger.isAfter  && Trigger.isUpdate)   handler.afterUpdate(Trigger.new, Trigger.oldMap);
    if (Trigger.isAfter  && Trigger.isDelete)   handler.afterDelete(Trigger.oldMap);
    if (Trigger.isAfter  && Trigger.isUndelete) handler.afterUndelete(Trigger.new);
}
```

## Handler skeleton
```apex
public with sharing class AccountTriggerHandler {
    @TestVisible private static Boolean hasRun = false;

    public void beforeUpdate(List<Account> newList, Map<Id, Account> oldMap) {
        if (hasRun) { return; }
        // FM: respect the NoTriggers__c per-user bypass switch used by import batches
        if (NoTriggers__c.getInstance(UserInfo.getUserId())?.Flag__c == true) { return; }
        hasRun = true;
        // 1. filter records that actually changed the fields you care about
        // 2. gather ids, query related data via a selector (one query)
        // 3. mutate newList in memory (no DML in before-context)
    }
    // one method per context...
}
```

## Checklist
- [ ] Only one trigger for the object
- [ ] Every context delegated to the handler
- [ ] No SOQL/DML in loops; queries filtered by `Set<Id>`
- [ ] Recursion guard present
- [ ] `NoTriggers__c` bypass honored (match existing handlers in this repo)
- [ ] Handler test covers each context + a 200-record bulk case
