# FM-002 sample data

This fixture set models one sample customer and collection location with:

- A legal entity used as the owning entity for customer and location Accounts
- A collection product and pricebook entry
- A haulage supplier and supplier product
- A depot and active collection round
- A collection schedule linked to the location, round, supplier, and supplier product
- One open missed collection linked to the schedule
- One draft order with two order items for the live collection location

Load the records in the order defined by `plan.json`. The Account `RecordTypeId` values
follow the existing CRMFM-1 fixture convention and may need to be replaced with the
matching Account and Location record type IDs in the target sandbox.

For an org that already contains the base FM-002 sample, use `bulk_plan.json` to add
records 2 through 10 without re-importing the base records. The active schedule trigger
may expand each imported Schedule__c record into weekday schedule records in the org;
this is expected sandbox automation behavior. Case automation may also normalize Case
subjects and other operational fields after import.
