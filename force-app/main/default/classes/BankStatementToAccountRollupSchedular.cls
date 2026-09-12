public without sharing class BankStatementToAccountRollupSchedular implements Schedulable {

	public void execute(SchedulableContext sc) {
		Database.executeBatch(new BankStatementToAccountRollupBatch());
	}
}